create or replace function app_private.online_category_ids()
returns text[]
language sql
immutable
set search_path = ''
as $$
  select array[
    'drinks',
    'coffee_tea',
    'alcohol',
    'sweets',
    'snacks',
    'fruit',
    'vegetables',
    'dairy_eggs',
    'bakery',
    'meat',
    'fish_seafood',
    'frozen',
    'dry_goods',
    'canned_jars',
    'spices_condiments',
    'oils_sauces',
    'ready_meals',
    'household_cleaning',
    'paper_hygiene',
    'personal_care',
    'other'
  ]::text[];
$$;

create or replace function app_private.is_online_category_id(value text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select lower(trim(coalesce(value, ''))) = any (
    app_private.online_category_ids()
  );
$$;

create or replace function app_private.online_category_key(value text)
returns text
language sql
immutable
set search_path = ''
as $$
  select coalesce(
    nullif(app_private.content_filter_compact(value), ''),
    lower(regexp_replace(trim(coalesce(value, '')), '\s+', ' ', 'g'))
  );
$$;

create or replace function app_private.online_category_id_for_value(value text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  cleaned text := lower(trim(coalesce(value, '')));
  key text := app_private.online_category_key(value);
begin
  if app_private.is_online_category_id(cleaned) then
    return cleaned;
  end if;

  return case
    when key in (
      'drinks', 'drink', 'napoje', 'getrnke', 'dranken', 'bebidas',
      'boissons', 'bevande', 'water', 'wasser', 'sok', 'juice'
    ) then 'drinks'
    when key in (
      'coffeetea', 'coffee', 'tea', 'kawaiherbata', 'kawa', 'herbata',
      'kaffeeundtee', 'kaffee', 'tee', 'cafe', 'cafete'
    ) then 'coffee_tea'
    when key in (
      'alcohol', 'alkohol', 'alcool', 'alcol', 'alcolici', 'lcool',
      'beer', 'piwo', 'wine', 'wino'
    ) then 'alcohol'
    when key in (
      'sweets', 'sweet', 'slodycze', 'sussigkeiten', 'sigkeiten', 'snoep',
      'dulces', 'confiseries', 'dolci', 'doces', 'candy', 'chocolate'
    ) then 'sweets'
    when key in (
      'snacks', 'snack', 'przekaski', 'aperitivos', 'chips', 'crisps'
    ) then 'snacks'
    when key in (
      'fruit', 'fruits', 'owoce', 'obst', 'fruta', 'frutas', 'frutta'
    ) then 'fruit'
    when key in (
      'vegetables', 'vegetable', 'warzywa', 'gemuse', 'gemse', 'groenten',
      'verduras', 'legumes', 'lgumes', 'verdure', 'vegetais'
    ) then 'vegetables'
    when key in (
      'dairyeggs', 'dairy', 'eggs', 'nabial', 'nabialijajka',
      'molkereiprodukte', 'milchprodukteundeier', 'zuivel',
      'zuiv eleneieren', 'lcteos', 'lacteos', 'lcteosyhuevos',
      'lacteosyhuevos', 'produitslaitiers', 'latticini', 'laticinios',
      'milk', 'mleko', 'jajka'
    ) then 'dairy_eggs'
    when key in (
      'bakery', 'piekarnia', 'pieczywo', 'backerei', 'bckerei',
      'bakkerij', 'panaderia', 'panadera', 'boulangerie', 'panetteria',
      'padaria', 'bread', 'chleb'
    ) then 'bakery'
    when key in (
      'meat', 'mieso', 'fleisch', 'vlees', 'carne', 'viande'
    ) then 'meat'
    when key in (
      'fishseafood', 'fish', 'seafood', 'ryby', 'rybyiowocemorza',
      'pescadoymarisco', 'poissonetfruitsdemer', 'pesceefruttidimare',
      'peixeemarisco'
    ) then 'fish_seafood'
    when key in (
      'frozen', 'mrozonki', 'tiefkuhlkost', 'tiefkhlkost', 'diepvries',
      'congelados', 'surgeles', 'surgels', 'surgelati'
    ) then 'frozen'
    when key in (
      'drygoods', 'pastariceflour', 'makaronryzimaka',
      'makaronryzimka', 'nudelnreisundmehl', 'pastarijstenbloem',
      'pastaarrozyharina', 'ptesrizetfarine', 'patesrizetfarine',
      'pastarisoefarina', 'massaarrozefarinha', 'pasta', 'rice',
      'flour', 'makaron', 'ryz', 'maka', 'mka'
    ) then 'dry_goods'
    when key in (
      'cannedjars', 'cansjars', 'konserwyisloiki', 'konserwyisloiki',
      'konservenundglaser', 'blikkenenpotten', 'conservasytarros',
      'conservesetbocaux', 'scatoletteebarattoli', 'conservasefrascos',
      'cans', 'jars', 'konserwy', 'sloiki'
    ) then 'canned_jars'
    when key in (
      'spicescondiments', 'spices', 'condiments', 'przyprawy',
      'gewurze', 'gewrze', 'kruidenenspecerijen',
      'especiasycondimentos', 'epicesetcondiments',
      'picesetcondiments', 'spezieecondimenti',
      'especiariasecondimentos'
    ) then 'spices_condiments'
    when key in (
      'oilssauces', 'oilsauces', 'olejeisosy', 'oleundsoen',
      'leundsoen', 'olienensauzen', 'olinenensauzen',
      'aceitesysalsas', 'huilesetsauces', 'oliesalse',
      'oleosemolhos', 'oil', 'sauce', 'olej', 'sos'
    ) then 'oils_sauces'
    when key in (
      'readymeals', 'daniagotowe', 'fertiggerichte',
      'kantenklaarmaaltijden', 'platospreparados', 'platsprepares',
      'platsprpars', 'piattipronti', 'refeicoesprontas',
      'refeiesprontas'
    ) then 'ready_meals'
    when key in (
      'householdcleaning', 'household', 'cleaning', 'chemia',
      'chemiadomowa', 'haushalt', 'haushaltsreinigung', 'huishouden',
      'huishoudelijkeschoonmaak', 'hogar', 'limpiezadelhogar',
      'maison', 'entretiendelamaison', 'casa', 'limpezadomestica',
      'limpezadomstica'
    ) then 'household_cleaning'
    when key in (
      'paperhygiene', 'paper', 'hygiene', 'papierihigiena',
      'papierundhygiene', 'papierenhygiene', 'papelehigiene',
      'papierethygiene', 'cartaeigiene'
    ) then 'paper_hygiene'
    when key in (
      'personalcare', 'higienaosobista', 'korperpflege', 'krperpflege',
      'persoonlijkeverzorging', 'cuidadopersonal', 'soinspersonnels',
      'curapersonale', 'cuidadospessoais', 'cosmetics', 'kosmetyki'
    ) then 'personal_care'
    when key in ('other', 'inne', 'andere', 'overig', 'otros', 'autre', 'altro')
      then 'other'
    else 'other'
  end;
end;
$$;

create or replace function app_private.is_online_category_order(value jsonb)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
begin
  if jsonb_typeof(value) <> 'array' then
    return false;
  end if;

  return not exists (
    select 1
    from jsonb_array_elements_text(value) categories(category_id)
    where not app_private.is_online_category_id(categories.category_id)
  );
end;
$$;

create or replace function app_private.normalize_legacy_online_category_order(
  value jsonb
)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
  normalized jsonb;
begin
  if jsonb_typeof(value) <> 'array' then
    return '[]'::jsonb;
  end if;

  select coalesce(jsonb_agg(category_id order by first_index), '[]'::jsonb)
  into normalized
  from (
    select
      app_private.online_category_id_for_value(categories.category) as category_id,
      min(categories.ordinality) as first_index
    from jsonb_array_elements_text(value)
      with ordinality as categories(category, ordinality)
    where nullif(trim(categories.category), '') is not null
    group by app_private.online_category_id_for_value(categories.category)
  ) deduplicated;

  return normalized;
end;
$$;

create or replace function app_private.validate_online_category_order(
  value jsonb
)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
  normalized jsonb;
begin
  if jsonb_typeof(value) <> 'array' then
    raise exception 'Category order must be a JSON array';
  end if;

  if exists (
    select 1
    from jsonb_array_elements_text(value) categories(category_id)
    where not app_private.is_online_category_id(categories.category_id)
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'INVALID_ONLINE_CATEGORY',
      detail = 'INVALID_ONLINE_CATEGORY';
  end if;

  select coalesce(jsonb_agg(category_id order by first_index), '[]'::jsonb)
  into normalized
  from (
    select
      lower(trim(categories.category_id)) as category_id,
      min(categories.ordinality) as first_index
    from jsonb_array_elements_text(value)
      with ordinality as categories(category_id, ordinality)
    where nullif(trim(categories.category_id), '') is not null
    group by lower(trim(categories.category_id))
  ) deduplicated;

  return normalized;
end;
$$;

drop index if exists public.shared_market_layouts_store_layout_hash_key;

create temporary table normalized_shared_market_layouts on commit drop as
with normalized as (
  select
    id,
    store_location_id,
    app_private.normalize_legacy_online_category_order(category_order)
      as normalized_order,
    download_count,
    published_at,
    updated_at
  from public.shared_market_layouts
),
ranked as (
  select
    *,
    first_value(id) over (
      partition by store_location_id, normalized_order
      order by download_count desc, published_at, id
    ) as keeper_id,
    row_number() over (
      partition by store_location_id, normalized_order
      order by download_count desc, published_at, id
    ) as duplicate_rank
  from normalized
)
select *
from ranked;

with group_totals as (
  select
    duplicates.keeper_id,
    keepers.download_count + sum(duplicate_layouts.download_count)
      as total_download_count
  from normalized_shared_market_layouts duplicates
  join public.shared_market_layouts keepers
    on keepers.id = duplicates.keeper_id
  join public.shared_market_layouts duplicate_layouts
    on duplicate_layouts.id = duplicates.id
  where duplicates.duplicate_rank > 1
  group by duplicates.keeper_id, keepers.download_count
)
update public.shared_market_layouts layouts
set download_count = group_totals.total_download_count
from group_totals
where layouts.id = group_totals.keeper_id;

insert into public.shared_market_layout_reports (
  shared_market_layout_id,
  reported_by,
  reason,
  status,
  created_at
)
select
  duplicates.keeper_id,
  reports.reported_by,
  reports.reason,
  reports.status,
  reports.created_at
from public.shared_market_layout_reports reports
join normalized_shared_market_layouts duplicates
  on duplicates.id = reports.shared_market_layout_id
where duplicates.duplicate_rank > 1
on conflict (shared_market_layout_id, reported_by)
do update set
  reason = excluded.reason,
  status = case
    when public.shared_market_layout_reports.status = 'open' then 'open'
    else excluded.status
  end,
  created_at = least(
    public.shared_market_layout_reports.created_at,
    excluded.created_at
  );

delete from public.shared_market_layouts layouts
using normalized_shared_market_layouts duplicates
where layouts.id = duplicates.id
  and duplicates.duplicate_rank > 1;

update public.shared_market_layouts layouts
set category_order = normalized.normalized_order
from normalized_shared_market_layouts normalized
where layouts.id = normalized.id;

alter table public.shared_market_layouts
drop constraint if exists shared_market_layouts_category_order_online_ids_check;

alter table public.shared_market_layouts
add constraint shared_market_layouts_category_order_online_ids_check
check (app_private.is_online_category_order(category_order));

create unique index shared_market_layouts_store_layout_hash_key
on public.shared_market_layouts (
  store_location_id,
  md5(category_order::text)
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
  normalized_category_order jsonb;
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

  normalized_category_order :=
    app_private.validate_online_category_order(target_category_order);

  select id into current_layout_id
  from public.shared_market_layouts
  where created_by = current_user_id
    and source_local_id = left(cleaned_source_id, 512);

  if exists (
    select 1
    from public.shared_market_layouts layouts
    where layouts.store_location_id = target_store_location_id
      and layouts.category_order = normalized_category_order
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
    normalized_category_order
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

create or replace function public.publish_market_layout(
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

revoke all on function app_private.online_category_ids()
  from public, anon, authenticated;
revoke all on function app_private.is_online_category_id(text)
  from public, anon, authenticated;
revoke all on function app_private.online_category_key(text)
  from public, anon, authenticated;
revoke all on function app_private.online_category_id_for_value(text)
  from public, anon, authenticated;
revoke all on function app_private.is_online_category_order(jsonb)
  from public, anon, authenticated;
revoke all on function app_private.normalize_legacy_online_category_order(jsonb)
  from public, anon, authenticated;
revoke all on function app_private.validate_online_category_order(jsonb)
  from public, anon, authenticated;

revoke all on function app_private.publish_market_layout(uuid, text, jsonb)
  from public, anon;
grant execute on function app_private.publish_market_layout(uuid, text, jsonb)
  to authenticated;

revoke all on function public.publish_market_layout(uuid, text, jsonb)
  from public, anon;
grant execute on function public.publish_market_layout(uuid, text, jsonb)
  to authenticated;

notify pgrst, 'reload schema';
