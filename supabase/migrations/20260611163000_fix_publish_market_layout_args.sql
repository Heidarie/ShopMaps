drop function public.publish_market_layout(jsonb, text, jsonb);
drop function app_private.publish_market_layout(jsonb, text, jsonb);

create function app_private.publish_market_layout(
  target_location jsonb,
  target_source_local_id text,
  target_category_order jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  current_profile public.profiles;
  cleaned_source_id text := nullif(trim(target_source_local_id), '');
  cleaned_store_name text := left(trim(target_location->>'store_name'), 100);
  normalized_store_name text;
  location_id uuid;
  shared_layout_id uuid;
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

  if cleaned_store_name is null or cleaned_store_name = '' then
    raise exception 'Store name is required';
  end if;

  if jsonb_typeof(target_category_order) <> 'array' then
    raise exception 'Category order must be a JSON array';
  end if;

  if coalesce(target_location->>'provider', '') <> 'geoapify'
     or nullif(trim(target_location->>'provider_place_id'), '') is null
     or nullif(trim(target_location->>'formatted_address'), '') is null
     or nullif(trim(target_location->>'country_code'), '') is null
     or nullif(trim(target_location->>'latitude'), '') is null
     or nullif(trim(target_location->>'longitude'), '') is null then
    raise exception 'A verified Geoapify address is required';
  end if;

  normalized_store_name := lower(regexp_replace(cleaned_store_name, '\s+', ' ', 'g'));

  insert into public.store_locations (
    provider,
    provider_place_id,
    store_name,
    store_name_normalized,
    formatted_address,
    street,
    house_number,
    postcode,
    city,
    country_code,
    latitude,
    longitude
  ) values (
    'geoapify',
    left(trim(target_location->>'provider_place_id'), 512),
    cleaned_store_name,
    normalized_store_name,
    left(trim(target_location->>'formatted_address'), 500),
    nullif(left(trim(target_location->>'street'), 200), ''),
    nullif(left(trim(target_location->>'house_number'), 50), ''),
    nullif(left(trim(target_location->>'postcode'), 50), ''),
    nullif(left(trim(target_location->>'city'), 200), ''),
    lower(left(trim(target_location->>'country_code'), 2)),
    (target_location->>'latitude')::double precision,
    (target_location->>'longitude')::double precision
  )
  on conflict (provider, provider_place_id, store_name_normalized)
  do update set
    store_name = excluded.store_name,
    formatted_address = excluded.formatted_address,
    street = excluded.street,
    house_number = excluded.house_number,
    postcode = excluded.postcode,
    city = excluded.city,
    country_code = excluded.country_code,
    latitude = excluded.latitude,
    longitude = excluded.longitude
  returning id into location_id;

  insert into public.shared_market_layouts (
    store_location_id,
    created_by,
    creator_handle_snapshot,
    source_local_id,
    category_order
  ) values (
    location_id,
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
    updated_at = now()
  returning id into shared_layout_id;

  return shared_layout_id;
end;
$$;

create function public.publish_market_layout(
  location jsonb,
  source_local_id text,
  category_order jsonb
)
returns uuid
language sql
set search_path = ''
as $$
  select app_private.publish_market_layout(location, source_local_id, category_order);
$$;

revoke all on function app_private.publish_market_layout(jsonb, text, jsonb) from public;
grant execute on function app_private.publish_market_layout(jsonb, text, jsonb)
  to authenticated;

revoke all on function public.publish_market_layout(jsonb, text, jsonb) from public;
grant execute on function public.publish_market_layout(jsonb, text, jsonb)
  to authenticated;
