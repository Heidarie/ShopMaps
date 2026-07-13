create table public.store_locations (
  id uuid primary key default gen_random_uuid(),
  provider text not null check (provider = 'geoapify'),
  provider_place_id text not null check (char_length(provider_place_id) between 1 and 512),
  store_name text not null check (char_length(store_name) between 1 and 100),
  store_name_normalized text not null check (char_length(store_name_normalized) between 1 and 100),
  formatted_address text not null check (char_length(formatted_address) between 1 and 500),
  street text,
  house_number text,
  postcode text,
  city text,
  country_code text not null check (char_length(country_code) = 2),
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, provider_place_id, store_name_normalized)
);

create table public.shared_market_layouts (
  id uuid primary key default gen_random_uuid(),
  store_location_id uuid not null references public.store_locations(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  creator_handle_snapshot text not null check (char_length(creator_handle_snapshot) between 1 and 100),
  source_local_id text not null check (char_length(source_local_id) between 1 and 512),
  category_order jsonb not null default '[]'::jsonb
    check (jsonb_typeof(category_order) = 'array'),
  published_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (created_by, source_local_id)
);

create index shared_market_layouts_store_location_id_idx
  on public.shared_market_layouts(store_location_id);
create index shared_market_layouts_created_by_idx
  on public.shared_market_layouts(created_by);
create index store_locations_city_idx
  on public.store_locations(country_code, city);

create trigger store_locations_touch_updated_at
before update on public.store_locations
for each row execute function app_private.touch_updated_at();

create trigger shared_market_layouts_touch_updated_at
before update on public.shared_market_layouts
for each row execute function app_private.touch_updated_at();

create or replace function app_private.publish_market_layout(
  location jsonb,
  source_local_id text,
  category_order jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  current_profile public.profiles;
  cleaned_source_id text := nullif(trim(source_local_id), '');
  cleaned_store_name text := left(trim(location->>'store_name'), 100);
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

  if jsonb_typeof(category_order) <> 'array' then
    raise exception 'Category order must be a JSON array';
  end if;

  if coalesce(location->>'provider', '') <> 'geoapify'
     or nullif(trim(location->>'provider_place_id'), '') is null
     or nullif(trim(location->>'formatted_address'), '') is null
     or nullif(trim(location->>'country_code'), '') is null
     or nullif(trim(location->>'latitude'), '') is null
     or nullif(trim(location->>'longitude'), '') is null then
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
    left(trim(location->>'provider_place_id'), 512),
    cleaned_store_name,
    normalized_store_name,
    left(trim(location->>'formatted_address'), 500),
    nullif(left(trim(location->>'street'), 200), ''),
    nullif(left(trim(location->>'house_number'), 50), ''),
    nullif(left(trim(location->>'postcode'), 50), ''),
    nullif(left(trim(location->>'city'), 200), ''),
    lower(left(trim(location->>'country_code'), 2)),
    (location->>'latitude')::double precision,
    (location->>'longitude')::double precision
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
    category_order
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

create or replace function public.publish_market_layout(
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

alter table public.store_locations enable row level security;
alter table public.shared_market_layouts enable row level security;

create policy "Authenticated users can read store locations"
on public.store_locations for select
to authenticated
using (true);

create policy "Authenticated users can read public market layouts"
on public.shared_market_layouts for select
to authenticated
using (true);

create policy "Creators can delete public market layouts"
on public.shared_market_layouts for delete
to authenticated
using (created_by = (select auth.uid()));

revoke all on function app_private.publish_market_layout(jsonb, text, jsonb) from public;
grant execute on function app_private.publish_market_layout(jsonb, text, jsonb)
  to authenticated;

revoke all on function public.publish_market_layout(jsonb, text, jsonb) from public;
grant execute on function public.publish_market_layout(jsonb, text, jsonb)
  to authenticated;

grant select on public.store_locations to authenticated;
grant select, delete on public.shared_market_layouts to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shared_market_layouts'
  ) then
    alter publication supabase_realtime add table public.shared_market_layouts;
  end if;
end
$$;
