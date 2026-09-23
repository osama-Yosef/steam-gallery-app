// supabase/functions/send-push/index.ts
//
// Turns an in-app notification row into a real push (arrives even with the
// app closed/killed), via Firebase Cloud Messaging's HTTP v1 API. Called
// fire-and-forget by a trigger on public.notifications (see
// 0066_push_notifications.sql) — never awaited by whatever created the
// notification, so a push failure can never block that action.
//
// FCM v1 needs a Google OAuth2 access token, not a fixed API key: this signs
// a short-lived JWT with the Firebase service account's private key and
// exchanges it for one. The service account (FCM_CLIENT_EMAIL,
// FCM_PRIVATE_KEY) is a project secret set via `supabase secrets set` — it
// is never shipped to Flutter and never appears in this repo.
//
// Request body: { "user_id": string, "title": string, "body"?: string, "data"?: object }

import { createClient } from "npm:@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "npm:jose@5";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_CLIENT_EMAIL = Deno.env.get("FCM_CLIENT_EMAIL")!;
const FCM_PRIVATE_KEY = Deno.env.get("FCM_PRIVATE_KEY")!.replace(/\\n/g, "\n");
const FCM_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;

const TOKEN_URL = "https://oauth2.googleapis.com/token";
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  try {
    const body = await req.json();
    const { user_id, title, body: messageBody, data } = body ?? {};
    if (!user_id || !title) {
      return json({ error: "missing user_id or title" }, 400);
    }

    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { data: profile, error: profileErr } = await adminClient
      .from("users")
      .select("fcm_token")
      .eq("id", user_id)
      .maybeSingle();
    if (profileErr) {
      console.error("send-push: profile lookup failed", profileErr);
      return json({ error: "internal_error" }, 500);
    }
    const token = profile?.fcm_token;
    if (!token) {
      // No device registered for push — the in-app notification row still
      // stands on its own, this is not a failure.
      return json({ ok: true, skipped: "no_fcm_token" }, 200);
    }

    const accessToken = await getGoogleAccessToken();

    // FCM's `data` payload must be flat string->string.
    const stringData: Record<string, string> = {};
    if (data && typeof data === "object") {
      for (const [k, v] of Object.entries(data as Record<string, unknown>)) {
        stringData[k] = typeof v === "string" ? v : JSON.stringify(v);
      }
    }

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body: messageBody ?? "" },
            data: stringData,
          },
        }),
      },
    );

    if (!fcmRes.ok) {
      const errBody = await fcmRes.text();
      console.error("send-push: FCM send failed", fcmRes.status, errBody);
      // An invalid/expired token is routine (uninstalled app, cleared data)
      // — clear it so future notifications stop trying it, but this is
      // still not an error worth surfacing.
      if (fcmRes.status === 404 || fcmRes.status === 400) {
        await adminClient.from("users").update({ fcm_token: null }).eq("id", user_id);
      }
      return json({ ok: false, fcm_status: fcmRes.status }, 200);
    }

    return json({ ok: true }, 200);
  } catch (e) {
    console.error("send-push: unexpected error", e);
    return json({ error: "internal_error" }, 500);
  }
});

async function getGoogleAccessToken(): Promise<string> {
  const privateKey = await importPKCS8(FCM_PRIVATE_KEY, "RS256");
  const now = Math.floor(Date.now() / 1000);
  const assertion = await new SignJWT({ scope: FCM_SCOPE })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(FCM_CLIENT_EMAIL)
    .setAudience(TOKEN_URL)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) {
    throw new Error(`Google token exchange failed: ${res.status} ${await res.text()}`);
  }
  const { access_token } = await res.json();
  return access_token as string;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
