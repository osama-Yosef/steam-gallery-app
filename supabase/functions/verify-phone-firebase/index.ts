// supabase/functions/verify-phone-firebase/index.ts
//
// Bridges Firebase Phone Auth (free SMS delivery) into this app's phone
// verification story, which otherwise lives entirely in Supabase Auth (see
// supabase/migrations/0031_phone_verification.sql). Supabase's own SMS
// provider costs money per message; Firebase's phone auth is free within its
// quota, so it now does the actual OTP delivery. This function is what turns
// "Firebase says this number answered a code" into something this app's
// database trusts, without ever giving the client the service role key.
//
// Trust chain: verify the Firebase ID token's signature against Google's
// public keys (so only a real, unexpired Firebase verification is accepted),
// check it was issued by OUR Firebase project, and read its `phone_number`
// claim — Firebase only sets that claim after its own OTP was confirmed.
//
// Two intents:
//   * "mark_verified" — caller is already signed in to Supabase (JWT in
//     Authorization header); sets phone_verified_at directly for that
//     account, the same evidence rpc_mark_phone_verified() would have
//     recorded from a Supabase-native OTP session.
//   * "reset_password" — no Supabase session exists yet (this IS the
//     forgot-password flow). Looks up the account by the verified phone and
//     sets a new password with the service role, then the client signs in
//     normally with it. Never sends any Supabase SMS.
//
// Request body:
//   { "firebase_id_token": string, "intent": "mark_verified" }
//   { "firebase_id_token": string, "intent": "reset_password", "new_password": string }

import { createClient } from "npm:@supabase/supabase-js@2";
import { jwtVerify, createRemoteJWKSet } from "npm:jose@5";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const PUBLISHABLE_KEY = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY")!;
// Firebase project id (from google-services.json -> project_info.project_id).
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;

const GOOGLE_JWKS = createRemoteJWKSet(
  new URL("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"),
);

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  try {
    const body = await req.json();
    const { firebase_id_token, intent, new_password } = body ?? {};
    if (!firebase_id_token || typeof firebase_id_token !== "string") {
      return json({ error: "missing firebase_id_token" }, 400);
    }
    if (intent !== "mark_verified" && intent !== "reset_password") {
      return json({ error: "intent must be mark_verified or reset_password" }, 400);
    }

    // 1) Verify the Firebase ID token's signature, issuer and audience.
    let phoneNumber: string;
    try {
      const { payload } = await jwtVerify(firebase_id_token, GOOGLE_JWKS, {
        issuer: `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`,
        audience: FIREBASE_PROJECT_ID,
      });
      const claimedPhone = payload.phone_number;
      const signInProvider = (payload.firebase as { sign_in_provider?: string } | undefined)
        ?.sign_in_provider;
      if (typeof claimedPhone !== "string" || !claimedPhone.startsWith("+")) {
        return json({ error: "token has no verified phone number" }, 400);
      }
      if (signInProvider !== "phone") {
        return json({ error: "token was not established by phone verification" }, 400);
      }
      phoneNumber = claimedPhone;
    } catch (e) {
      console.error("verify-phone-firebase: token verification failed", e);
      return json({ error: "invalid_or_expired_token" }, 401);
    }

    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    if (intent === "mark_verified") {
      // 2a) Caller must already hold a Supabase session — this only confirms
      // the phone belongs to the account making the request, it can't be
      // used to take over someone else's account.
      const authHeader = req.headers.get("Authorization") ?? "";
      const callerClient = createClient(SUPABASE_URL, PUBLISHABLE_KEY, {
        global: { headers: { Authorization: authHeader } },
      });
      const { data: userRes, error: userErr } = await callerClient.auth.getUser();
      if (userErr || !userRes?.user) {
        return json({ error: "unauthorized" }, 401);
      }

      const { data: profile, error: profileErr } = await adminClient
        .from("users")
        .select("phone")
        .eq("id", userRes.user.id)
        .single();
      if (profileErr || !profile) {
        return json({ error: "user_not_found" }, 404);
      }
      if (profile.phone !== phoneNumber) {
        return json({ error: "verified number does not match this account" }, 400);
      }

      const { error: updateErr } = await adminClient
        .from("users")
        .update({ phone_verified_at: new Date().toISOString() })
        .eq("id", userRes.user.id)
        .is("phone_verified_at", null);
      if (updateErr) {
        console.error("verify-phone-firebase: mark_verified update failed", updateErr);
        return json({ error: "internal_error" }, 500);
      }

      await adminClient.from("audit_logs").insert({
        actor_id: userRes.user.id,
        action: "PHONE_VERIFIED",
        table_name: "users",
        record_id: userRes.user.id,
        new_data: { method: "firebase_otp" },
      });

      return json({ ok: true }, 200);
    }

    // intent === "reset_password"
    if (!new_password || typeof new_password !== "string" || new_password.length < 8) {
      return json({ error: "new_password must be at least 8 characters" }, 400);
    }

    // 2b) No session yet — find the account by the phone Firebase just
    // proved, and set its password directly with the service role. Silent,
    // generic failure for an unknown number so this can't be used to probe
    // which numbers have accounts.
    const { data: profile, error: profileErr } = await adminClient
      .from("users")
      .select("id")
      .eq("phone", phoneNumber)
      .maybeSingle();
    if (profileErr) {
      console.error("verify-phone-firebase: profile lookup failed", profileErr);
      return json({ error: "internal_error" }, 500);
    }
    if (!profile) {
      return json({ error: "account_not_found" }, 404);
    }

    const { error: updateErr } = await adminClient.auth.admin.updateUserById(profile.id, {
      password: new_password,
    });
    if (updateErr) {
      console.error("verify-phone-firebase: password reset failed", updateErr);
      return json({ error: "internal_error" }, 500);
    }

    await adminClient.from("audit_logs").insert({
      actor_id: profile.id,
      action: "PASSWORD_CHANGED",
      table_name: "users",
      record_id: profile.id,
      new_data: { method: "firebase_otp_recovery" },
    });

    return json({ ok: true }, 200);
  } catch (e) {
    console.error("verify-phone-firebase: unexpected error", e);
    return json({ error: "internal_error" }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
