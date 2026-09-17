-- ============================================================================
-- 0032_locations_and_addresses.sql
--
-- Phase 3: where Mokoji operates, and where each customer is.
--
--   countries → cities → service_areas      (admin-managed coverage)
--   customers.city_id                       (profile city)
--   customer_addresses                      (several per customer, one default)
--
-- The schema is multi-country; the launch data is Egypt only.
--
-- Coverage model (V1): a service area is a circle — a centre point and a
-- radius in km — inside a city. An address is serviceable when its pin falls
-- inside an ACTIVE area of its ACTIVE city in an ACTIVE country. Circles are
-- deliberately simple: an admin sets one with a pin and a slider, no polygon
-- drawing, and resolution is plain arithmetic that needs no PostGIS. A polygon
-- column can be added later without changing how addresses consume coverage.
--
-- The decision is made here, server-side:
--   * each address stores the area it resolves to (service_area_id), set by
--     a trigger on every write — never by the client;
--   * when an admin changes coverage (area, city or country switched on/off,
--     moved, resized), every affected address is re-resolved at once, so
--     "available" is never stale;
--   * rpc_check_service_availability answers "is this pin covered?" before an
--     address is even saved, so the customer learns it while picking the pin,
--     not at checkout.
-- Enforcement at order time arrives with checkout (Phase 8), through
-- private.address_is_serviceable().
--
-- Addresses are written only through rpc_* functions (validation, the
-- one-default rule, the per-customer cap); clients get SELECT on their own
-- rows. Non-destructive: nothing existing is dropped. The legacy free-text
-- customers.default_address/latitude/longitude columns stay untouched.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Geography
-- ----------------------------------------------------------------------------
create table public.countries (
  id uuid primary key default gen_random_uuid(),
  iso_code text not null unique check (iso_code ~ '^[A-Z]{2}$'),
  name_ar text not null,
  name_en text not null,
  phone_code text not null check (phone_code ~ '^\+[0-9]{1,4}$'),
  currency_code text not null check (currency_code ~ '^[A-Z]{3}$'),
  is_active boolean not null default false,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table public.cities (
  id uuid primary key default gen_random_uuid(),
  country_id uuid not null references public.countries(id),
  name_ar text not null check (length(btrim(name_ar)) between 1 and 80),
  name_en text check (length(name_en) <= 80),
  -- Where the map opens when a customer picks this city, and the reference
  -- point for rejecting pins dropped nowhere near it.
  center_latitude numeric(10,7) not null check (center_latitude between -90 and 90),
  center_longitude numeric(10,7) not null check (center_longitude between -180 and 180),
  is_active boolean not null default false,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  unique (country_id, name_ar)
);

create table public.service_areas (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references public.cities(id),
  name_ar text not null check (length(btrim(name_ar)) between 1 and 80),
  center_latitude numeric(10,7) not null check (center_latitude between -90 and 90),
  center_longitude numeric(10,7) not null check (center_longitude between -180 and 180),
  radius_km numeric(5,2) not null check (radius_km > 0 and radius_km <= 50),
  is_active boolean not null default true,
  notes text check (length(notes) <= 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (city_id, name_ar)
);

create trigger trg_service_areas_updated_at
  before update on public.service_areas
  for each row execute function public.touch_updated_at();

create index idx_cities_country on public.cities(country_id, sort_order);
create index idx_service_areas_city on public.service_areas(city_id) where is_active;

-- Coverage changes are business decisions worth a trail.
create trigger trg_audit_countries after insert or update or delete on public.countries
  for each row execute function public.audit_trigger();
create trigger trg_audit_cities after insert or update or delete on public.cities
  for each row execute function public.audit_trigger();
create trigger trg_audit_service_areas after insert or update or delete on public.service_areas
  for each row execute function public.audit_trigger();

-- ----------------------------------------------------------------------------
-- 2. Profile city
-- ----------------------------------------------------------------------------
alter table public.customers
  add column if not exists city_id uuid references public.cities(id);

-- ----------------------------------------------------------------------------
-- 3. Addresses
-- ----------------------------------------------------------------------------
create table public.customer_addresses (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  -- Derived from city_id by trigger; stored so later phases (currency, phone
  -- format) don't need the join.
  country_id uuid not null references public.countries(id),
  city_id uuid not null references public.cities(id),
  -- Resolved by trigger from the pin. NULL = outside current coverage.
  service_area_id uuid references public.service_areas(id) on delete set null,
  label text not null check (length(btrim(label)) between 1 and 40),
  recipient_name text check (length(recipient_name) <= 100),
  phone text check (phone ~ '^\+?[0-9]{8,15}$'),
  address_line text not null check (length(btrim(address_line)) between 3 and 300),
  building text check (length(building) <= 50),
  floor text check (length(floor) <= 20),
  apartment text check (length(apartment) <= 20),
  landmark text check (length(landmark) <= 150),
  latitude numeric(10,7) not null check (latitude between -90 and 90),
  longitude numeric(10,7) not null check (longitude between -180 and 180),
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (not is_default or is_active)
);

-- One default per customer among live addresses.
create unique index customer_addresses_one_default
  on public.customer_addresses (customer_id) where is_default and is_active;
create index idx_customer_addresses_customer
  on public.customer_addresses (customer_id, created_at desc) where is_active;
create index idx_customer_addresses_city on public.customer_addresses (city_id) where is_active;

-- ----------------------------------------------------------------------------
-- 4. Coverage resolution
-- ----------------------------------------------------------------------------
-- Great-circle distance (haversine), km. least() guards asin against a
-- floating-point value a hair above 1 for antipodal points.
create or replace function private.distance_km(
  p_lat1 numeric, p_lng1 numeric, p_lat2 numeric, p_lng2 numeric
) returns double precision
language sql immutable parallel safe as $$
  select 6371.0088 * 2 * asin(least(1, sqrt(
    power(sin(radians((p_lat2 - p_lat1)::double precision) / 2), 2)
    + cos(radians(p_lat1::double precision)) * cos(radians(p_lat2::double precision))
      * power(sin(radians((p_lng2 - p_lng1)::double precision) / 2), 2)
  )));
$$;

-- The active area in [p_city_id] containing the point. With overlapping
-- circles, the one whose centre is relatively closest wins (distance as a
-- share of radius), so a pin goes to the area it's most "inside".
create or replace function private.resolve_service_area(
  p_city_id uuid, p_lat numeric, p_lng numeric
) returns uuid
language sql stable security definer set search_path = public as $$
  select sa.id
  from public.service_areas sa
  join public.cities c on c.id = sa.city_id
  join public.countries co on co.id = c.country_id
  where sa.city_id = p_city_id
    and sa.is_active and c.is_active and co.is_active
    and p_lat is not null and p_lng is not null
    and private.distance_km(p_lat, p_lng, sa.center_latitude, sa.center_longitude) <= sa.radius_km
  order by private.distance_km(p_lat, p_lng, sa.center_latitude, sa.center_longitude) / sa.radius_km,
           sa.id
  limit 1;
$$;

-- For checkout (Phase 8) and anything else that must refuse uncovered
-- addresses server-side.
create or replace function private.address_is_serviceable(p_address_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((
    select a.is_active and a.service_area_id is not null
    from public.customer_addresses a where a.id = p_address_id
  ), false);
$$;

revoke all on function private.distance_km(numeric, numeric, numeric, numeric) from public, anon, authenticated;
revoke all on function private.resolve_service_area(uuid, numeric, numeric) from public, anon, authenticated;
revoke all on function private.address_is_serviceable(uuid) from public, anon, authenticated;

-- Every address write: country follows city, area follows pin, timestamps.
create or replace function public.customer_addresses_before_write() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  select country_id into new.country_id from public.cities where id = new.city_id;
  if new.country_id is null then raise exception 'CITY_NOT_FOUND'; end if;

  new.service_area_id := private.resolve_service_area(new.city_id, new.latitude, new.longitude);

  if tg_op = 'UPDATE' then
    new.created_at := old.created_at;
    new.customer_id := old.customer_id;
    -- Coverage re-resolution alone isn't an edit by the customer.
    if (new.label, new.recipient_name, new.phone, new.address_line, new.building, new.floor,
        new.apartment, new.landmark, new.latitude, new.longitude, new.city_id,
        new.is_default, new.is_active)
       is distinct from
       (old.label, old.recipient_name, old.phone, old.address_line, old.building, old.floor,
        old.apartment, old.landmark, old.latitude, old.longitude, old.city_id,
        old.is_default, old.is_active) then
      new.updated_at := now();
    else
      new.updated_at := old.updated_at;
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_customer_addresses_before_write
  before insert or update on public.customer_addresses
  for each row execute function public.customer_addresses_before_write();

-- Re-resolve every live address in the cities a coverage change touches.
create or replace function private.reresolve_city_addresses(p_city_ids uuid[]) returns void
language sql security definer set search_path = public as $$
  update public.customer_addresses a
    set service_area_id = private.resolve_service_area(a.city_id, a.latitude, a.longitude)
    where a.is_active
      and a.city_id = any (p_city_ids)
      and a.service_area_id is distinct from private.resolve_service_area(a.city_id, a.latitude, a.longitude);
$$;
revoke all on function private.reresolve_city_addresses(uuid[]) from public, anon, authenticated;

create or replace function public.on_coverage_change() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_cities uuid[];
begin
  if tg_table_name = 'service_areas' then
    v_cities := array_remove(array[
      case when tg_op <> 'INSERT' then old.city_id end,
      case when tg_op <> 'DELETE' then new.city_id end
    ], null);
  elsif tg_table_name = 'cities' then
    v_cities := array[new.id];
  else -- countries
    select coalesce(array_agg(id), '{}') into v_cities from public.cities where country_id = new.id;
  end if;

  perform private.reresolve_city_addresses(v_cities);
  return null;
end;
$$;

create trigger trg_service_areas_coverage
  after insert or update or delete on public.service_areas
  for each row execute function public.on_coverage_change();
create trigger trg_cities_coverage
  after update of is_active on public.cities
  for each row execute function public.on_coverage_change();
create trigger trg_countries_coverage
  after update of is_active on public.countries
  for each row execute function public.on_coverage_change();

-- ----------------------------------------------------------------------------
-- 5. RLS + grants
-- ----------------------------------------------------------------------------
alter table public.countries enable row level security;
alter table public.cities enable row level security;
alter table public.service_areas enable row level security;
alter table public.customer_addresses enable row level security;

-- Supabase's default privileges hand anon/authenticated ALL on new tables;
-- start from nothing and grant exactly what's needed.
revoke all on public.countries, public.cities, public.service_areas, public.customer_addresses
  from public, anon, authenticated;

-- Geography: everyone signed in reads what's live; admins read everything and
-- maintain it (no DELETE — switch off instead, history stays intact).
grant select, insert, update on public.countries, public.cities, public.service_areas to authenticated;

create policy countries_select on public.countries for select to authenticated
  using (is_active or public.is_admin());
create policy countries_admin_insert on public.countries for insert to authenticated
  with check (public.is_admin());
create policy countries_admin_update on public.countries for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy cities_select on public.cities for select to authenticated
  using (is_active or public.is_admin());
create policy cities_admin_insert on public.cities for insert to authenticated
  with check (public.is_admin());
create policy cities_admin_update on public.cities for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy service_areas_select on public.service_areas for select to authenticated
  using (is_active or public.is_admin());
create policy service_areas_admin_insert on public.service_areas for insert to authenticated
  with check (public.is_admin());
create policy service_areas_admin_update on public.service_areas for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- Addresses: read own (admin reads all); writes only through the RPCs below.
grant select on public.customer_addresses to authenticated;
create policy customer_addresses_select on public.customer_addresses for select to authenticated
  using (public.is_admin() or (customer_id = auth.uid() and is_active));

-- ----------------------------------------------------------------------------
-- 6. RPCs
-- ----------------------------------------------------------------------------
-- "Is this pin covered?" — before saving, so the customer knows while picking.
create or replace function public.rpc_check_service_availability(
  p_city_id uuid, p_latitude numeric, p_longitude numeric
) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_area record;
begin
  if auth.uid() is null then raise exception 'FORBIDDEN'; end if;
  if p_latitude is null or p_longitude is null
     or p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then
    raise exception 'INVALID_LOCATION';
  end if;

  select sa.id, sa.name_ar into v_area
    from public.service_areas sa
    where sa.id = private.resolve_service_area(p_city_id, p_latitude, p_longitude);

  return jsonb_build_object(
    'available', v_area.id is not null,
    'service_area_id', v_area.id,
    'service_area_name', v_area.name_ar
  );
end;
$$;

-- Create (p_address_id null) or edit one of the caller's addresses.
create or replace function public.rpc_save_my_address(
  p_address_id uuid,
  p_city_id uuid,
  p_label text,
  p_address_line text,
  p_latitude numeric,
  p_longitude numeric,
  p_building text default null,
  p_floor text default null,
  p_apartment text default null,
  p_landmark text default null,
  p_recipient_name text default null,
  p_phone text default null,
  p_make_default boolean default false
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_city record;
  v_phone text := nullif(regexp_replace(coalesce(p_phone, ''), '[\s-]', '', 'g'), '');
  v_id uuid;
  v_make_default boolean;
  v_area_id uuid;
  v_area_name text;
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;

  if p_label is null or btrim(p_label) = '' or p_address_line is null or btrim(p_address_line) = '' then
    raise exception 'INVALID_INPUT';
  end if;
  if length(btrim(p_label)) > 40 or length(btrim(p_address_line)) > 300
     or length(p_building) > 50 or length(p_floor) > 20 or length(p_apartment) > 20
     or length(p_landmark) > 150 or length(p_recipient_name) > 100 then
    raise exception 'INPUT_TOO_LONG';
  end if;
  if length(btrim(p_address_line)) < 3 then raise exception 'INVALID_INPUT'; end if;
  if v_phone is not null and v_phone !~ '^\+?[0-9]{8,15}$' then raise exception 'INVALID_PHONE'; end if;
  if p_latitude is null or p_longitude is null
     or p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then
    raise exception 'INVALID_LOCATION';
  end if;

  select c.id, c.center_latitude, c.center_longitude into v_city
    from public.cities c join public.countries co on co.id = c.country_id
    where c.id = p_city_id and c.is_active and co.is_active;
  if not found then raise exception 'CITY_NOT_AVAILABLE'; end if;

  -- A pin hundreds of km from the chosen city is a mistake (wrong city picked,
  -- map dragged away), not an address in that city.
  if private.distance_km(p_latitude, p_longitude, v_city.center_latitude, v_city.center_longitude) > 100 then
    raise exception 'LOCATION_OUTSIDE_CITY';
  end if;

  -- Serialise this customer's address writes: the default switch and the cap
  -- must see a consistent set.
  perform 1 from public.customers where id = v_uid for update;
  if not found then raise exception 'CUSTOMER_NOT_FOUND'; end if;

  if p_address_id is null then
    if (select count(*) from public.customer_addresses where customer_id = v_uid and is_active) >= 10 then
      raise exception 'TOO_MANY_ADDRESSES';
    end if;
    -- The first address is the default whether asked or not.
    v_make_default := coalesce(p_make_default, false) or not exists (
      select 1 from public.customer_addresses where customer_id = v_uid and is_active and is_default
    );
  else
    perform 1 from public.customer_addresses
      where id = p_address_id and customer_id = v_uid and is_active;
    if not found then raise exception 'ADDRESS_NOT_FOUND'; end if;
    v_make_default := coalesce(p_make_default, false);
  end if;

  if v_make_default then
    update public.customer_addresses set is_default = false
      where customer_id = v_uid and is_default and (p_address_id is null or id <> p_address_id);
  end if;

  if p_address_id is null then
    insert into public.customer_addresses (
      customer_id, country_id, city_id, label, recipient_name, phone, address_line,
      building, floor, apartment, landmark, latitude, longitude, is_default)
    values (
      v_uid, (select country_id from public.cities where id = p_city_id), p_city_id,
      btrim(p_label), nullif(btrim(p_recipient_name), ''), v_phone, btrim(p_address_line),
      nullif(btrim(p_building), ''), nullif(btrim(p_floor), ''), nullif(btrim(p_apartment), ''),
      nullif(btrim(p_landmark), ''), p_latitude, p_longitude, v_make_default)
    returning id, service_area_id into v_id, v_area_id;
  else
    update public.customer_addresses set
      city_id = p_city_id,
      label = btrim(p_label),
      recipient_name = nullif(btrim(p_recipient_name), ''),
      phone = v_phone,
      address_line = btrim(p_address_line),
      building = nullif(btrim(p_building), ''),
      floor = nullif(btrim(p_floor), ''),
      apartment = nullif(btrim(p_apartment), ''),
      landmark = nullif(btrim(p_landmark), ''),
      latitude = p_latitude,
      longitude = p_longitude,
      -- Un-defaulting the only default by editing would leave none; only
      -- rpc_set_default_address moves the default elsewhere.
      is_default = is_default or v_make_default
    where id = p_address_id
    returning id, service_area_id into v_id, v_area_id;
  end if;

  select name_ar into v_area_name from public.service_areas where id = v_area_id;

  return jsonb_build_object(
    'id', v_id,
    'available', v_area_id is not null,
    'service_area_id', v_area_id,
    'service_area_name', v_area_name
  );
end;
$$;

create or replace function public.rpc_set_default_address(p_address_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  perform 1 from public.customers where id = v_uid for update;

  perform 1 from public.customer_addresses where id = p_address_id and customer_id = v_uid and is_active;
  if not found then raise exception 'ADDRESS_NOT_FOUND'; end if;

  update public.customer_addresses set is_default = false
    where customer_id = v_uid and is_default and id <> p_address_id;
  update public.customer_addresses set is_default = true where id = p_address_id;
end;
$$;

-- Soft delete: past orders will snapshot addresses (Phase 8), but the row
-- itself stays for support/audit. Deleting the default promotes the newest
-- remaining address, so a customer with addresses always has a default.
create or replace function public.rpc_delete_my_address(p_address_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_was_default boolean;
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  perform 1 from public.customers where id = v_uid for update;

  update public.customer_addresses set is_active = false, is_default = false
    where id = p_address_id and customer_id = v_uid and is_active
    returning true into v_was_default;
  if not found then raise exception 'ADDRESS_NOT_FOUND'; end if;

  if not exists (select 1 from public.customer_addresses where customer_id = v_uid and is_active and is_default) then
    update public.customer_addresses set is_default = true
      where id = (
        select id from public.customer_addresses
        where customer_id = v_uid and is_active
        order by created_at desc limit 1
      );
  end if;
end;
$$;

create or replace function public.rpc_set_my_city(p_city_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  if p_city_id is not null and not exists (
    select 1 from public.cities c join public.countries co on co.id = c.country_id
    where c.id = p_city_id and c.is_active and co.is_active
  ) then
    raise exception 'CITY_NOT_AVAILABLE';
  end if;
  update public.customers set city_id = p_city_id where id = auth.uid();
  if not found then raise exception 'CUSTOMER_NOT_FOUND'; end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7. Launch data: Egypt
-- ----------------------------------------------------------------------------
-- Area centres/radii are approximate starting points for the admin to review
-- on the map (Admin → مناطق الخدمة), not surveyed boundaries.
insert into public.countries (iso_code, name_ar, name_en, phone_code, currency_code, is_active, sort_order)
values ('EG', 'مصر', 'Egypt', '+20', 'EGP', true, 1)
on conflict (iso_code) do nothing;

insert into public.cities (country_id, name_ar, name_en, center_latitude, center_longitude, is_active, sort_order)
select co.id, v.name_ar, v.name_en, v.lat, v.lng, true, v.sort_order
from public.countries co
cross join (values
  ('القاهرة', 'Cairo', 30.0444196, 31.2357116, 1),
  ('الجيزة', 'Giza', 30.0130557, 31.2088526, 2),
  ('الإسكندرية', 'Alexandria', 31.2000924, 29.9187387, 3)
) as v(name_ar, name_en, lat, lng, sort_order)
where co.iso_code = 'EG'
on conflict (country_id, name_ar) do nothing;

insert into public.service_areas (city_id, name_ar, center_latitude, center_longitude, radius_km, notes)
select c.id, v.name_ar, v.lat, v.lng, v.radius_km, 'نقطة بداية تقريبية — راجِعها على الخريطة'
from public.cities c
join public.countries co on co.id = c.country_id and co.iso_code = 'EG'
cross join (values
  ('مدينة نصر', 30.0561000, 31.3300800, 5.00),
  ('مصر الجديدة', 30.0910900, 31.3225300, 4.00),
  ('التجمع الخامس', 30.0074100, 31.4913000, 7.00)
) as v(name_ar, lat, lng, radius_km)
where c.name_ar = 'القاهرة'
on conflict (city_id, name_ar) do nothing;

-- ----------------------------------------------------------------------------
-- 8. Grants (rule from 0029)
-- ----------------------------------------------------------------------------
insert into private.rpc_allowlist (function_name, note) values
  ('rpc_check_service_availability', 'any signed-in user'),
  ('rpc_save_my_address', 'customer'),
  ('rpc_set_default_address', 'customer'),
  ('rpc_delete_my_address', 'customer'),
  ('rpc_set_my_city', 'customer')
on conflict (function_name) do nothing;

select private.apply_function_grants();
