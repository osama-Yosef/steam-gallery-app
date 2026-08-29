// supabase/functions/create-user/index.ts
//
// The ONLY place in the whole system that touches SUPABASE_SERVICE_ROLE_KEY.
// Runs on Supabase's servers (Deno Edge Runtime) — never shipped to Flutter.
//
// Purpose: create a technician or admin account. There is no self sign-up
// for these roles (see docs/04-security-architecture.md §1); only an
// existing admin may call this, authenticated with their own normal user
// JWT (passed in the Authorization header exactly like any other request).
//
// Request body:
//   {
//     "email": string,
//     "password": string,
//     "full_name": string,
//     "phone"?: string,
//     "role": "technician" | "admin",
//     "employee_code"?: string   // technician only, auto-generated if omitted
//   }

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";

    // 1) Verify the CALLER is an authenticated admin, using their own JWT
    //    against the anon-key client (respects RLS — no shortcuts here).
    const callerClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userRes, error: userErr } = await callerClient.auth.getUser();
    if (userErr || !userRes?.user) {
      return json({ error: "unauthorized" }, 401);
    }

    const { data: callerProfile, error: profileErr } = await callerClient
      .from("users")
      .select("role")
      .eq("id", userRes.user.id)
      .single();
    if (profileErr || callerProfile?.role !== "admin") {
      return json({ error: "forbidden: admin only" }, 403);
    }

    // 2) Validate payload
    const body = await req.json();
    const { email, password, full_name, phone, role, employee_code } = body ?? {};
    if (!email || !password || !full_name || !role) {
      return json({ error: "missing required fields" }, 400);
    }
    if (role !== "technician" && role !== "admin") {
      return json({ error: "role must be technician or admin" }, 400);
    }
    if (typeof password !== "string" || password.length < 8) {
      return json({ error: "password must be at least 8 characters" }, 400);
    }

    // 3) Create the auth user with the SERVICE ROLE client — the only step
    //    that needs elevated privileges. app_metadata.role is what every RLS
    //    policy and every rpc_* function trusts.
    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { data: created, error: createErr } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      app_metadata: { role },
      user_metadata: {
        full_name,
        phone: phone ?? null,
        employee_code: employee_code ?? null,
        created_by: userRes.user.id,
      },
    });

    if (createErr) {
      return json({ error: createErr.message }, 400);
    }

    // handle_new_auth_user() trigger takes it from here: creates public.users
    // + technicians/technician_bags/technician_accounts (or customers/
    // customer_accounts) rows automatically.
    return json({ user_id: created.user?.id }, 201);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
