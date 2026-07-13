alter table public.profiles
add column if not exists country_code text;

alter table public.profiles
drop constraint if exists profiles_country_code_check;

alter table public.profiles
add constraint profiles_country_code_check
check (
  country_code is null
  or country_code in ('gb', 'pl', 'de', 'nl', 'es', 'fr', 'ua', 'it', 'pt')
);

create index if not exists profiles_country_code_idx
on public.profiles(country_code)
where country_code is not null;

create or replace function app_private.is_supported_store_country(value text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select lower(trim(coalesce(value, ''))) = any (
    array['gb', 'pl', 'de', 'nl', 'es', 'fr', 'ua', 'it', 'pt']::text[]
  );
$$;

create or replace function app_private.current_profile_country(target_user_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select profiles.country_code
  from public.profiles profiles
  where profiles.id = target_user_id
    and app_private.is_supported_store_country(profiles.country_code);
$$;

create or replace function app_private.assert_complete_profile(
  target_user_id uuid
)
returns public.profiles
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_profile public.profiles;
begin
  select * into current_profile
  from public.profiles
  where id = target_user_id;

  if not found or current_profile.country_code is null then
    raise exception 'Complete your profile first';
  end if;

  return current_profile;
end;
$$;

create or replace function app_private.assert_store_country_allowed(
  target_store_location_id uuid,
  target_user_id uuid
)
returns public.store_locations
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_profile public.profiles;
  target_location public.store_locations;
begin
  current_profile := app_private.assert_complete_profile(target_user_id);

  select * into target_location
  from public.store_locations
  where id = target_store_location_id;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'CANONICAL_STORE_REQUIRED',
      detail = 'CANONICAL_STORE_REQUIRED';
  end if;

  if target_location.country_code is distinct from current_profile.country_code then
    raise exception using
      errcode = 'P0001',
      message = 'STORE_COUNTRY_MISMATCH',
      detail = 'STORE_COUNTRY_MISMATCH';
  end if;

  return target_location;
end;
$$;

create or replace function app_private.complete_profile(
  requested_display_name text,
  target_country_code text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  cleaned_name text := regexp_replace(trim(requested_display_name), '\s+', ' ', 'g');
  cleaned_country text := lower(trim(coalesce(target_country_code, '')));
  normalized_name text;
  candidate_tag integer;
  existing_profile public.profiles;
  completed_profile public.profiles;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not app_private.is_supported_store_country(cleaned_country) then
    raise exception 'Invalid store country';
  end if;

  select * into existing_profile
  from public.profiles
  where id = current_user_id
  for update;

  if found then
    if existing_profile.country_code is null then
      update public.profiles
      set country_code = cleaned_country
      where id = current_user_id
      returning * into completed_profile;

      return completed_profile;
    end if;

    return existing_profile;
  end if;

  if char_length(cleaned_name) < 2 or char_length(cleaned_name) > 24 then
    raise exception 'Display name must contain between 2 and 24 characters';
  end if;

  if cleaned_name ~ '#' then
    raise exception 'Display name cannot contain #';
  end if;

  normalized_name := app_private.normalized_handle_name(cleaned_name);

  for attempt in 1..100 loop
    candidate_tag := floor(random() * 10000)::integer;
    begin
      insert into public.profiles (
        id,
        display_name,
        display_name_normalized,
        discriminator,
        country_code
      ) values (
        current_user_id,
        cleaned_name,
        normalized_name,
        candidate_tag,
        cleaned_country
      )
      returning * into completed_profile;

      return completed_profile;
    exception when unique_violation then
      -- Try another discriminator for the same normalized name.
    end;
  end loop;

  raise exception 'Could not allocate a unique tag. Try another display name.';
end;
$$;

create or replace function public.complete_profile(
  display_name text,
  country_code text
)
returns public.profiles
language sql
set search_path = ''
as $$
  select app_private.complete_profile(display_name, country_code);
$$;

create or replace function app_private.update_profile_country(
  target_country_code text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  cleaned_country text := lower(trim(coalesce(target_country_code, '')));
  updated_profile public.profiles;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not app_private.is_supported_store_country(cleaned_country) then
    raise exception 'Invalid store country';
  end if;

  update public.profiles
  set country_code = cleaned_country
  where id = current_user_id
  returning * into updated_profile;

  if not found then
    raise exception 'Complete your profile first';
  end if;

  return updated_profile;
end;
$$;

create or replace function public.update_profile_country(country_code text)
returns public.profiles
language sql
set search_path = ''
as $$
  select app_private.update_profile_country(country_code);
$$;

create or replace function app_private.create_group(group_name text)
returns public.spaces
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  cleaned_name text := regexp_replace(trim(group_name), '\s+', ' ', 'g');
  created_space public.spaces;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  perform app_private.assert_complete_profile(current_user_id);

  if char_length(cleaned_name) < 1 or char_length(cleaned_name) > 100 then
    raise exception 'Group name must contain between 1 and 100 characters';
  end if;

  insert into public.spaces (name, created_by)
  values (cleaned_name, current_user_id)
  returning * into created_space;

  insert into public.space_members (space_id, user_id, role)
  values (created_space.id, current_user_id, 'owner');

  return created_space;
end;
$$;

revoke all on function public.claim_handle(text)
  from public, anon, authenticated;
revoke all on function app_private.claim_handle(text)
  from public, anon, authenticated;

revoke all on function app_private.complete_profile(text, text)
  from public, anon;
grant execute on function app_private.complete_profile(text, text)
  to authenticated;

revoke all on function public.complete_profile(text, text)
  from public, anon;
grant execute on function public.complete_profile(text, text)
  to authenticated;

revoke all on function app_private.update_profile_country(text)
  from public, anon;
grant execute on function app_private.update_profile_country(text)
  to authenticated;

revoke all on function public.update_profile_country(text)
  from public, anon;
grant execute on function public.update_profile_country(text)
  to authenticated;

drop policy if exists "Authenticated users can read store locations"
on public.store_locations;

create policy "Users can read store locations in their profile country"
on public.store_locations for select
to authenticated
using (
  country_code = app_private.current_profile_country((select auth.uid()))
);

drop policy if exists "Authenticated users can read public market layouts"
on public.shared_market_layouts;

create policy "Users can read public market layouts in their profile country"
on public.shared_market_layouts for select
to authenticated
using (
  exists (
    select 1
    from public.store_locations locations
    where locations.id = store_location_id
      and locations.country_code = app_private.current_profile_country(
        (select auth.uid())
      )
  )
);

drop policy if exists "Creators can delete public market layouts"
on public.shared_market_layouts;

create policy "Creators can delete public market layouts in their profile country"
on public.shared_market_layouts for delete
to authenticated
using (
  created_by = (select auth.uid())
  and exists (
    select 1
    from public.store_locations locations
    where locations.id = store_location_id
      and locations.country_code = app_private.current_profile_country(
        (select auth.uid())
      )
  )
);

create or replace function app_private.publish_market_layout(
  target_store_location_id uuid,
  target_source_local_id text,
  target_category_order jsonb
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  current_profile public.profiles;
  cleaned_source_id text := nullif(trim(target_source_local_id), '');
  current_layout_id uuid;
  violated_constraint text;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  current_profile := app_private.assert_complete_profile(current_user_id);
  perform app_private.assert_store_country_allowed(
    target_store_location_id,
    current_user_id
  );

  if cleaned_source_id is null then
    raise exception 'Local map id is required';
  end if;

  if jsonb_typeof(target_category_order) <> 'array' then
    raise exception 'Category order must be a JSON array';
  end if;

  select id into current_layout_id
  from public.shared_market_layouts
  where created_by = current_user_id
    and source_local_id = left(cleaned_source_id, 512);

  if exists (
    select 1
    from public.shared_market_layouts layouts
    where layouts.store_location_id = target_store_location_id
      and layouts.category_order = target_category_order
      and layouts.id is distinct from current_layout_id
  ) then
    return 'duplicate';
  end if;

  insert into public.shared_market_layouts (
    store_location_id,
    created_by,
    creator_handle_snapshot,
    source_local_id,
    category_order
  ) values (
    target_store_location_id,
    current_user_id,
    app_private.profile_handle(current_profile),
    left(cleaned_source_id, 512),
    target_category_order
  )
  on conflict (created_by, source_local_id)
  do update set
    store_location_id = excluded.store_location_id,
    creator_handle_snapshot = excluded.creator_handle_snapshot,
    category_order = excluded.category_order,
    updated_at = now();

  return 'published';
exception
  when unique_violation then
    get stacked diagnostics violated_constraint = constraint_name;
    if violated_constraint = 'shared_market_layouts_store_layout_hash_key' then
      return 'duplicate';
    end if;
    raise;
end;
$$;

create or replace function app_private.move_deposit_voucher_to_group(
  target_space_id uuid,
  voucher jsonb,
  target_store_location_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  created_voucher_id uuid;
  local_source_id text := nullif(trim(voucher->>'id'), '');
  canonical_store public.store_locations;
begin
  if current_user_id is null
     or not app_private.is_space_member(target_space_id, current_user_id) then
    raise exception 'Group membership required';
  end if;

  if local_source_id is null then
    raise exception 'Local voucher id is required';
  end if;

  canonical_store := app_private.assert_store_country_allowed(
    target_store_location_id,
    current_user_id
  );

  insert into public.shared_deposit_vouchers (
    space_id,
    source_local_id,
    code,
    format,
    amount,
    store_name,
    store_location_id,
    scanned_at,
    valid_until,
    created_by
  ) values (
    target_space_id,
    local_source_id,
    left(trim(voucher->>'code'), 2048),
    coalesce(nullif(trim(voucher->>'format'), ''), 'unknown'),
    greatest(coalesce((voucher->>'amount')::numeric, 0), 0),
    canonical_store.store_name,
    target_store_location_id,
    (voucher->>'scannedAt')::timestamptz,
    nullif(voucher->>'validUntil', '')::timestamptz,
    current_user_id
  )
  on conflict (space_id, source_local_id) where source_local_id is not null
  do update set
    store_location_id = excluded.store_location_id,
    store_name = excluded.store_name,
    updated_at = now()
  returning id into created_voucher_id;

  return created_voucher_id;
end;
$$;

create or replace function app_private.record_market_layout_download(
  target_shared_layout_id uuid
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  updated_download_count bigint;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  perform app_private.assert_complete_profile(current_user_id);

  if exists (
    select 1
    from public.shared_market_layouts layouts
    where layouts.id = target_shared_layout_id
  ) and not exists (
    select 1
    from public.shared_market_layouts layouts
    join public.store_locations locations
      on locations.id = layouts.store_location_id
    where layouts.id = target_shared_layout_id
      and locations.country_code = app_private.current_profile_country(
        current_user_id
      )
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'STORE_COUNTRY_MISMATCH',
      detail = 'STORE_COUNTRY_MISMATCH';
  end if;

  update public.shared_market_layouts layouts
  set download_count = download_count + 1
  from public.store_locations locations
  where layouts.id = target_shared_layout_id
    and locations.id = layouts.store_location_id
    and locations.country_code = app_private.current_profile_country(
      current_user_id
    )
  returning layouts.download_count into updated_download_count;

  if not found then
    raise exception 'Shared store map not found';
  end if;

  return updated_download_count;
end;
$$;

create or replace function app_private.report_public_market_layout(
  target_shared_layout_id uuid,
  report_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  map_owner_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  perform app_private.assert_complete_profile(current_user_id);

  if report_reason not in ('incorrect', 'inappropriate', 'other') then
    raise exception 'Invalid report reason';
  end if;

  select layouts.created_by
  into map_owner_id
  from public.shared_market_layouts layouts
  join public.store_locations locations
    on locations.id = layouts.store_location_id
  where layouts.id = target_shared_layout_id
    and locations.country_code = app_private.current_profile_country(
      current_user_id
    );

  if map_owner_id is null then
    if exists (
      select 1
      from public.shared_market_layouts layouts
      where layouts.id = target_shared_layout_id
    ) then
      raise exception using
        errcode = 'P0001',
        message = 'STORE_COUNTRY_MISMATCH',
        detail = 'STORE_COUNTRY_MISMATCH';
    end if;

    raise exception 'Public map not found';
  end if;

  if map_owner_id = current_user_id then
    raise exception 'Users cannot report their own public map';
  end if;

  insert into public.shared_market_layout_reports (
    shared_market_layout_id,
    reported_by,
    reason
  )
  values (target_shared_layout_id, current_user_id, report_reason)
  on conflict (shared_market_layout_id, reported_by)
  do update set
    reason = excluded.reason,
    status = 'open',
    created_at = now();
end;
$$;

revoke all on function app_private.is_supported_store_country(text)
  from public, anon, authenticated;
revoke all on function app_private.current_profile_country(uuid)
  from public, anon;
grant execute on function app_private.current_profile_country(uuid)
  to authenticated;
revoke all on function app_private.assert_complete_profile(uuid)
  from public, anon, authenticated;
revoke all on function app_private.assert_store_country_allowed(uuid, uuid)
  from public, anon, authenticated;

notify pgrst, 'reload schema';
