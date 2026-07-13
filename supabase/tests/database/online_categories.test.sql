begin;

create extension if not exists pgtap with schema extensions;

select plan(9);

select is(
  app_private.online_category_id_for_value('Napoje'),
  'drinks',
  'Polish legacy labels map to canonical category ids'
);

select is(
  app_private.online_category_id_for_value('Dairy'),
  'dairy_eggs',
  'English legacy defaults map to broader canonical category ids'
);

select is(
  app_private.online_category_id_for_value('Moja prywatna alejka'),
  'other',
  'unknown legacy categories migrate to other'
);

select is(
  app_private.normalize_legacy_online_category_order(
    '["Napoje", "Dairy", "Napoje", "Moja prywatna alejka"]'::jsonb
  ),
  '["drinks", "dairy_eggs", "other"]'::jsonb,
  'legacy category orders are normalized and deduplicated'
);

insert into auth.users (id, email)
values ('00000000-0000-0000-0000-000000003001', 'online-categories@example.com');

insert into public.profiles (
  id,
  display_name,
  display_name_normalized,
  discriminator,
  country_code
)
values (
  '00000000-0000-0000-0000-000000003001',
  'Online Categories',
  'online categories',
  3001,
  'pl'
);

insert into public.store_locations (
  id,
  provider,
  provider_place_id,
  store_name,
  store_name_normalized,
  formatted_address,
  country_code,
  latitude,
  longitude
)
values (
  '00000000-0000-0000-0000-000000003101',
  'geoapify',
  'online-category-store',
  'Category Market',
  'category market',
  'Pułaskiego 10, Warszawa',
  'pl',
  52.2,
  21.0
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000003001',
  true
);

select throws_ok(
  $$
    select public.publish_market_layout(
      '00000000-0000-0000-0000-000000003101',
      'invalid-category-layout',
      '["not_a_category"]'::jsonb
    )
  $$,
  'P0001',
  'INVALID_ONLINE_CATEGORY',
  'publish RPC rejects unknown online category ids'
);

select is(
  public.publish_market_layout(
    '00000000-0000-0000-0000-000000003101',
    'canonical-category-layout',
    '["drinks", "drinks", "bakery"]'::jsonb
  ),
  'published',
  'publish RPC accepts canonical category ids'
);

select is(
  (
    select category_order
    from public.shared_market_layouts
    where source_local_id = 'canonical-category-layout'
  ),
  '["drinks", "bakery"]'::jsonb,
  'publish RPC deduplicates canonical category order'
);

select is(
  public.publish_market_layout(
    '00000000-0000-0000-0000-000000003101',
    'duplicate-category-layout',
    '["drinks", "bakery"]'::jsonb
  ),
  'duplicate',
  'duplicate detection uses canonical category order'
);

reset role;

select throws_ok(
  $$
    insert into public.shared_market_layouts (
      store_location_id,
      created_by,
      creator_handle_snapshot,
      source_local_id,
      category_order
    )
    values (
      '00000000-0000-0000-0000-000000003101',
      '00000000-0000-0000-0000-000000003001',
      'Online Categories#3001',
      'direct-invalid-category-layout',
      '["not_a_category"]'::jsonb
    )
  $$,
  '23514',
  'new row for relation "shared_market_layouts" violates check constraint "shared_market_layouts_category_order_online_ids_check"',
  'direct writes cannot store unknown online category ids'
);

select * from finish();
rollback;
