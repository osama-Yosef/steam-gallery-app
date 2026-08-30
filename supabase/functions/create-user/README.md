# Edge Function: `create-user`

The only place `SUPABASE_SERVICE_ROLE_KEY` is used anywhere in this system. Creates a **technician** or **admin** account (phone + password). Customers self-register from the app and never touch this function.

## Deploy

```bash
supabase functions deploy create-user
```

The service role key is available to the function automatically as `SUPABASE_SERVICE_ROLE_KEY` (Supabase injects it into every Edge Function's environment) — you don't set it manually.

## Call it (from an authenticated admin session)

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/create-user" \
  -H "Authorization: Bearer <the admin's own access token>" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "01099998888",
    "password": "a-strong-password",
    "full_name": "محمد الصنايعي",
    "role": "technician",
    "employee_code": "T-001"
  }'
```

In Flutter, this is just `supabase.functions.invoke('create-user', body: {...})` — the SDK attaches the current session's access token automatically, satisfying step 1 of the function (verifying the caller is an admin).

## Bootstrapping the very first admin

Before any admin exists, nobody can call this function (it requires an existing admin's JWT). Run this **once**, from a trusted machine, using the service role key directly — see the comment block at the bottom of `supabase/migrations/0013_seed.sql` for the exact `auth.admin.createUser(...)` call.
