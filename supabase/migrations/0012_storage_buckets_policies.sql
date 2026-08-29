-- ============================================================================
-- 0012_storage_buckets_policies.sql
--
-- Path conventions (enforced by the policies below — Flutter MUST upload to
-- exactly these paths or the insert will be rejected by RLS):
--   products/{product_id}/{filename}
--   maintenance/{customer_id}/{maintenance_request_id}/{filename}
--   avatars/{user_id}/{filename}
--   attachments/{expense_id}/{filename}
-- ============================================================================

insert into storage.buckets (id, name, public) values
  ('products', 'products', true),
  ('maintenance', 'maintenance', false),
  ('avatars', 'avatars', true),
  ('attachments', 'attachments', false)
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- products: public read (bucket is public), admin-only write
-- ----------------------------------------------------------------------------
create policy "products_public_read" on storage.objects for select
  using (bucket_id = 'products');

create policy "products_admin_write" on storage.objects for insert to authenticated
  with check (bucket_id = 'products' and public.is_admin());

create policy "products_admin_update" on storage.objects for update to authenticated
  using (bucket_id = 'products' and public.is_admin());

create policy "products_admin_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'products' and public.is_admin());

-- ----------------------------------------------------------------------------
-- maintenance: private. Readable/writable by the owning customer, the
-- assigned technician, and admin. Path: maintenance/{customer_id}/{request_id}/file
-- ----------------------------------------------------------------------------
create policy "maintenance_read" on storage.objects for select to authenticated
  using (
    bucket_id = 'maintenance' and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
      or exists (
        select 1 from public.maintenance_requests mr
        where mr.id::text = (storage.foldername(name))[2]
          and mr.assigned_technician_id = auth.uid()
      )
    )
  );

create policy "maintenance_write" on storage.objects for insert to authenticated
  with check (
    bucket_id = 'maintenance' and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
      or exists (
        select 1 from public.maintenance_requests mr
        where mr.id::text = (storage.foldername(name))[2]
          and mr.assigned_technician_id = auth.uid()
      )
    )
  );

create policy "maintenance_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'maintenance' and public.is_admin());

-- ----------------------------------------------------------------------------
-- avatars: public read, each user writes only to their own folder
-- ----------------------------------------------------------------------------
create policy "avatars_public_read" on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatars_own_write" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars_own_update" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars_own_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- ----------------------------------------------------------------------------
-- attachments (expense receipts etc.): admin only, both read and write
-- ----------------------------------------------------------------------------
create policy "attachments_admin_all" on storage.objects for all to authenticated
  using (bucket_id = 'attachments' and public.is_admin())
  with check (bucket_id = 'attachments' and public.is_admin());
