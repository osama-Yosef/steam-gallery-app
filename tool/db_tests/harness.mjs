// tool/db_tests/harness.mjs
//
// Shared setup for the database test suites: a fresh PGlite (real Postgres
// compiled to WASM — no Docker, no Supabase project, nothing touched outside
// this process), minimal stand-ins for Supabase's auth/storage schemas and
// default grants, every migration in supabase/migrations applied in order,
// and a small set of users (admin, two technicians, two customers).
//
// Limits: the stand-ins are not Supabase itself — PostgREST, GoTrue (bans,
// sessions, OTP delivery) and Realtime are not exercised.
// tool/hardening_check.dart covers those against a real project.

import { PGlite } from '@electric-sql/pglite';
import { pg_trgm } from '@electric-sql/pglite/contrib/pg_trgm';
import { pgcrypto } from '@electric-sql/pglite/contrib/pgcrypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const uid = n => `${String(n).padStart(8, '0')}-0000-4000-8000-${String(n).padStart(12, '0')}`;
export const ADMIN = uid(1), TECH = uid(2), TECH2 = uid(3), CUST_A = uid(4), CUST_B = uid(5);

/**
 * Builds the database. [repo] defaults to the repository containing this
 * file; pass another root to test a different migrations folder.
 */
export async function setup(repo) {
  const root = repo ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
  const migDir = path.join(root, 'supabase', 'migrations');
  const db = new PGlite({ extensions: { pg_trgm, pgcrypto } });

  let pass = 0, fail = 0;
  const ok = (label, cond, extra = '') => {
    if (cond) { pass++; console.log(`  [PASS] ${label}`); }
    else { fail++; console.log(`  [FAIL] ${label} ${extra}`); }
  };
  const finish = () => {
    console.log(`\n== ${pass} passed, ${fail} failed ==`);
    process.exit(fail === 0 ? 0 : 1);
  };

  await db.exec(`
    create role anon nologin; create role authenticated nologin; create role service_role nologin;
    create schema auth;
    create table auth.users (id uuid primary key, phone text, email text,
      encrypted_password text, phone_confirmed_at timestamptz,
      raw_app_meta_data jsonb default '{}'::jsonb, raw_user_meta_data jsonb default '{}'::jsonb,
      banned_until timestamptz);
    create table auth.sessions (id uuid primary key default gen_random_uuid(), user_id uuid);
    create function auth.jwt() returns jsonb language sql stable as
      $$ select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb $$;
    create function auth.uid() returns uuid language sql stable as
      $$ select nullif(auth.jwt() ->> 'sub', '')::uuid $$;
    grant usage on schema auth to anon, authenticated, service_role;
    grant execute on all functions in schema auth to anon, authenticated, service_role;
    grant usage on schema public to anon, authenticated, service_role;
    -- Supabase's default privileges on public.
    alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
    alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
    alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
    create schema storage;
    create table storage.buckets (id text primary key, name text, public boolean);
    create table storage.objects (id uuid default gen_random_uuid(), bucket_id text, name text);
    alter table storage.objects enable row level security;
    create function storage.foldername(name text) returns text[] language sql as $$ select string_to_array(name, '/') $$;
    create publication supabase_realtime;
  `);

  console.log('== Applying migrations ==');
  const files = fs.readdirSync(migDir).filter(f => f.endsWith('.sql')).sort();
  for (const f of files) {
    try {
      await db.exec(fs.readFileSync(path.join(migDir, f), 'utf8'));
    } catch (e) {
      ok(`applied ${f}`, false, e.message);
      console.log('Aborting: later migrations depend on this one.');
      process.exit(1);
    }
  }
  ok(`applied ${files.length} migrations (${files[0]} .. ${files[files.length - 1]})`, true);

  async function mkUser(id, role, phone, name) {
    await db.query(
      `insert into auth.users (id, phone, phone_confirmed_at, raw_app_meta_data, raw_user_meta_data)
       values ($1, $2, now(), $3, $4)`,
      [id, phone, role ? { role } : {}, { full_name: name, phone: '+201999999999' }]);
  }
  await mkUser(ADMIN, 'admin', '+201000000001', 'Admin');
  await mkUser(TECH, 'technician', '+201000000002', 'Tech');
  await mkUser(TECH2, 'technician', '+201000000003', 'Tech2');
  await mkUser(CUST_A, null, '+201000000004', 'Cust A');
  await mkUser(CUST_B, null, '', 'Cust B');

  const roleOf = { [ADMIN]: 'admin', [TECH]: 'technician', [TECH2]: 'technician', [CUST_A]: 'customer', [CUST_B]: 'customer' };

  /** Acts as [userId] (null = anon). [claims] are merged into the JWT. */
  async function as(userId, claims = {}) {
    await db.exec('reset role');
    const jwt = userId ? { sub: userId, app_metadata: { role: roleOf[userId] ?? 'customer' }, ...claims } : {};
    await db.query(`select set_config('request.jwt.claims', $1, false)`, [JSON.stringify(jwt)]);
    await db.exec(`set role ${userId ? 'authenticated' : 'anon'}`);
  }
  const asSuper = async () => { await db.exec('reset role'); };
  const q = async (sql, params = []) => (await db.query(sql, params)).rows;
  const one = async (sql, params = []) => (await q(sql, params))[0];
  const err = async (sql, params = []) => {
    try { await db.query(sql, params); return null; } catch (e) { return e.message; }
  };

  return { db, ok, finish, as, asSuper, q, one, err, mkUser, roleOf };
}
