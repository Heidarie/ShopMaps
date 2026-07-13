alter table public.shared_deposit_vouchers
add column store_location_id uuid
  references public.store_locations(id) on delete restrict;

create index shared_deposit_vouchers_store_location_id_idx
on public.shared_deposit_vouchers(store_location_id);

grant select, insert, update on public.store_locations to service_role;

create or replace function app_private.enforce_canonical_voucher_store()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  canonical_store_name text;
begin
  if new.store_location_id is null then
    if tg_op = 'UPDATE'
       and old.store_location_id is null
       and new.store_name is not distinct from old.store_name then
      return new;
    end if;

    raise exception using
      errcode = 'P0001',
      message = 'CANONICAL_STORE_REQUIRED',
      detail = 'CANONICAL_STORE_REQUIRED';
  end if;

  select locations.store_name
  into canonical_store_name
  from public.store_locations locations
  where locations.id = new.store_location_id;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'CANONICAL_STORE_REQUIRED',
      detail = 'CANONICAL_STORE_REQUIRED';
  end if;

  new.store_name := canonical_store_name;
  return new;
end;
$$;

create trigger shared_deposit_vouchers_enforce_canonical_store
before insert or update of store_location_id, store_name
on public.shared_deposit_vouchers
for each row execute function app_private.enforce_canonical_voucher_store();

drop function public.move_deposit_voucher_to_group(uuid, jsonb);
drop function app_private.move_deposit_voucher_to_group(uuid, jsonb);

create function app_private.move_deposit_voucher_to_group(
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
  canonical_store_name text;
begin
  if current_user_id is null
     or not app_private.is_space_member(target_space_id, current_user_id) then
    raise exception 'Group membership required';
  end if;

  if local_source_id is null then
    raise exception 'Local voucher id is required';
  end if;

  select locations.store_name
  into canonical_store_name
  from public.store_locations locations
  where locations.id = target_store_location_id;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'CANONICAL_STORE_REQUIRED',
      detail = 'CANONICAL_STORE_REQUIRED';
  end if;

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
    canonical_store_name,
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

create function public.move_deposit_voucher_to_group(
  space_id uuid,
  voucher jsonb,
  store_location_id uuid
)
returns uuid
language sql
set search_path = ''
as $$
  select app_private.move_deposit_voucher_to_group(
    space_id,
    voucher,
    store_location_id
  );
$$;

revoke all on function app_private.move_deposit_voucher_to_group(
  uuid,
  jsonb,
  uuid
) from public;
grant execute on function app_private.move_deposit_voucher_to_group(
  uuid,
  jsonb,
  uuid
) to authenticated;

revoke all on function public.move_deposit_voucher_to_group(
  uuid,
  jsonb,
  uuid
) from public;
grant execute on function public.move_deposit_voucher_to_group(
  uuid,
  jsonb,
  uuid
) to authenticated;

drop function public.publish_market_layout(jsonb, text, jsonb);
drop function app_private.publish_market_layout(jsonb, text, jsonb);

create function app_private.publish_market_layout(
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

  select * into current_profile
  from public.profiles
  where id = current_user_id;

  if not found then
    raise exception 'Complete your profile first';
  end if;

  if cleaned_source_id is null then
    raise exception 'Local map id is required';
  end if;

  if jsonb_typeof(target_category_order) <> 'array' then
    raise exception 'Category order must be a JSON array';
  end if;

  if not exists (
    select 1
    from public.store_locations locations
    where locations.id = target_store_location_id
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'CANONICAL_STORE_REQUIRED',
      detail = 'CANONICAL_STORE_REQUIRED';
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

create function public.publish_market_layout(
  store_location_id uuid,
  source_local_id text,
  category_order jsonb
)
returns text
language sql
set search_path = ''
as $$
  select app_private.publish_market_layout(
    store_location_id,
    source_local_id,
    category_order
  );
$$;

revoke all on function app_private.publish_market_layout(uuid, text, jsonb)
  from public;
grant execute on function app_private.publish_market_layout(uuid, text, jsonb)
  to authenticated;

revoke all on function public.publish_market_layout(uuid, text, jsonb)
  from public;
grant execute on function public.publish_market_layout(uuid, text, jsonb)
  to authenticated;

revoke all on function app_private.enforce_canonical_voucher_store()
  from public, anon, authenticated;
