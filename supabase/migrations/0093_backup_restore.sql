-- ============================================================================
-- 0093_backup_restore.sql
--
-- A full backup the owner takes from the app, and putting one back. Admin
-- only.
--
-- rpc_backup_export(): every row of every table in `public`, plus
-- private.processed_requests (what makes a queued offline write apply only
-- once), as one JSON document. Read-only.
--
-- rpc_backup_restore(p_backup): makes the database what the backup says,
-- in one transaction — on any error nothing has changed. Before touching
-- anything it stores the current data in private.backup_snapshots (the
-- last 5 are kept), so a restore of the wrong file can itself be undone.
-- Rows go back exactly as they were: triggers are switched off while they
-- load (no stock movement, ledger entry or audit row is re-derived), tables
-- load parents first, and every counter (sale numbers, invoice numbers...)
-- continues after the highest number restored.
--
-- Not covered: logins (auth.users — a restored profile needs its account
-- to still exist, or the restore stops with BACKUP_USER_MISSING), and files
-- in Storage (photos, receipts).
-- ============================================================================

create table if not exists private.backup_snapshots (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by uuid,
  reason text not null,
  data jsonb not null
);

-- The tables a backup covers, as 'schema.table'.
create or replace function private.fn_backup_tables()
returns setof text language sql stable set search_path = public as $$
  select format('%I.%I', n.nspname, c.relname)
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where c.relkind = 'r' and n.nspname = 'public'
  union all
  select 'private.processed_requests'
  order by 1;
$$;

create or replace function private.fn_backup_export()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_table text;
  v_rows jsonb;
  v_tables jsonb := '{}'::jsonb;
begin
  for v_table in select private.fn_backup_tables() loop
    execute format('select coalesce(jsonb_agg(to_jsonb(t)), ''[]''::jsonb) from %s t', v_table)
      into v_rows;
    v_tables := v_tables || jsonb_build_object(v_table, v_rows);
  end loop;
  return jsonb_build_object(
    'format', 'mokoji-backup',
    'version', 1,
    'schema', '0093',
    'created_at', now(),
    'tables', v_tables
  );
end;
$$;
revoke all on function private.fn_backup_export() from public, anon, authenticated;

create or replace function public.rpc_backup_export()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  return private.fn_backup_export();
end;
$$;

create or replace function public.rpc_backup_restore(p_backup jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_tables text[];
  v_table text;
  v_rows jsonb;
  v_cols text;
  v_done text[] := '{}';
  v_progress boolean;
  v_counts jsonb := '{}'::jsonb;
  v_snapshot uuid;
  v_seq record;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_backup is null or p_backup ->> 'format' is distinct from 'mokoji-backup'
     or jsonb_typeof(p_backup -> 'tables') <> 'object' then
    raise exception 'INVALID_BACKUP';
  end if;
  -- A backup from a newer app may hold columns this database lacks.
  if coalesce(p_backup ->> 'schema', '') > '0093' then raise exception 'BACKUP_TOO_NEW'; end if;

  select array_agg(t) into v_tables from private.fn_backup_tables() t;

  -- Every user in the backup must still have a login.
  if exists (
    select 1 from jsonb_array_elements(coalesce(p_backup -> 'tables' -> 'public.users', '[]'::jsonb)) u
    where not exists (select 1 from auth.users a where a.id = (u ->> 'id')::uuid)
  ) then
    raise exception 'BACKUP_USER_MISSING';
  end if;

  insert into private.backup_snapshots (created_by, reason, data)
  values (auth.uid(), 'قبل استرجاع نسخة ' || coalesce(p_backup ->> 'created_at', ''), private.fn_backup_export())
  returning id into v_snapshot;
  delete from private.backup_snapshots
  where id not in (select id from private.backup_snapshots order by created_at desc limit 5);

  foreach v_table in array v_tables loop
    execute format('alter table %s disable trigger user', v_table);
  end loop;

  execute 'truncate table ' || array_to_string(v_tables, ', ');

  -- Parents before children: a table loads once every table it points at
  -- (other than itself) has.
  loop
    v_progress := false;
    foreach v_table in array v_tables loop
      continue when v_table = any(v_done);
      continue when exists (
        select 1 from pg_constraint fk
        where fk.contype = 'f'
          and fk.conrelid = v_table::regclass
          and fk.confrelid <> fk.conrelid
          and fk.confrelid = any(select t::regclass::oid from unnest(v_tables) t)
          and fk.confrelid <> all(select t::regclass::oid from unnest(v_done) t)
      );

      v_rows := coalesce(p_backup -> 'tables' -> v_table, '[]'::jsonb);
      if jsonb_array_length(v_rows) > 0 then
        -- The table's own columns that the backup has, minus generated ones
        -- (Postgres computes those). A column added after the backup was
        -- taken gets its default.
        select string_agg(quote_ident(a.attname), ', ' order by a.attnum) into v_cols
        from pg_attribute a
        where a.attrelid = v_table::regclass and a.attnum > 0 and not a.attisdropped
          and a.attgenerated = ''
          and v_rows -> 0 ? a.attname;
        execute format(
          'insert into %s (%s) overriding system value select %s from jsonb_populate_recordset(null::%s, $1)',
          v_table, v_cols, v_cols, v_table) using v_rows;
      end if;
      v_counts := v_counts || jsonb_build_object(v_table, jsonb_array_length(v_rows));
      v_done := v_done || v_table;
      v_progress := true;
    end loop;
    exit when cardinality(v_done) = cardinality(v_tables);
    if not v_progress then raise exception 'BACKUP_TABLE_ORDER'; end if;
  end loop;

  foreach v_table in array v_tables loop
    execute format('alter table %s enable trigger user', v_table);
  end loop;

  -- Counters continue after the highest number restored.
  for v_seq in
    select format('%I.%I', n.nspname, c.relname) as tbl, a.attname as col,
           pg_get_serial_sequence(format('%I.%I', n.nspname, c.relname), a.attname) as seq
    from pg_attribute a
    join pg_class c on c.oid = a.attrelid
    join pg_namespace n on n.oid = c.relnamespace
    where format('%I.%I', n.nspname, c.relname) = any(v_tables)
      and a.attnum > 0 and not a.attisdropped
      and pg_get_serial_sequence(format('%I.%I', n.nspname, c.relname), a.attname) is not null
  loop
    execute format(
      'select setval(%L, coalesce((select max(%I) from %s), 0) + 1, false)',
      v_seq.seq, v_seq.col, v_seq.tbl);
  end loop;

  insert into public.audit_logs (actor_id, action, table_name, record_id, new_data)
  values (auth.uid(), 'BACKUP_RESTORED', 'backup', null,
          jsonb_build_object('backup_created_at', p_backup ->> 'created_at', 'snapshot_id', v_snapshot));

  return jsonb_build_object('snapshot_id', v_snapshot, 'tables', v_counts);
end;
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_backup_export', 'admin'),
  ('rpc_backup_restore', 'admin')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
