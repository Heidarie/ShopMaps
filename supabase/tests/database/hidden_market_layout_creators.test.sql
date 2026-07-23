begin;

create extension if not exists pgtap with schema extensions;

select plan(13);

select has_table(
  'public',
  'hidden_market_layout_creators',
  'hidden market layout creators are stored'
);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000004001', 'map-viewer@example.com'),
  ('00000000-0000-0000-0000-000000004002', 'hidden-author@example.com'),
  ('00000000-0000-0000-0000-000000004003', 'visible-author@example.com');

insert into public.profiles (
  id,
  display_name,
  display_name_normalized,
  discriminator,
  country_code
)
values
  (
    '00000000-0000-0000-0000-000000004001',
    'Map Viewer',
    'map viewer',
    4001,
    'pl'
  ),
  (
    '00000000-0000-0000-0000-000000004002',
    'Hidden Author',
    'hidden author',
    4002,
    'pl'
  ),
  (
    '00000000-0000-0000-0000-000000004003',
    'Visible Author',
    'visible author',
    4003,
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
  '00000000-0000-0000-0000-000000004101',
  'geoapify',
  'hidden-creators-store',
  'Hidden Creators Market',
  'hidden creators market',
  'Testowa 1, Warszawa',
  'pl',
  52.2,
  21.0
);

insert into public.shared_market_layouts (
  id,
  store_location_id,
  created_by,
  creator_handle_snapshot,
  source_local_id,
  category_order
)
values
  (
    '00000000-0000-0000-0000-000000004201',
    '00000000-0000-0000-0000-000000004101',
    '00000000-0000-0000-0000-000000004001',
    'Map Viewer#4001',
    'viewer-map',
    '["other"]'::jsonb
  ),
  (
    '00000000-0000-0000-0000-000000004202',
    '00000000-0000-0000-0000-000000004101',
    '00000000-0000-0000-0000-000000004002',
    'Hidden Author#4002',
    'hidden-map-one',
    '["bakery"]'::jsonb
  ),
  (
    '00000000-0000-0000-0000-000000004203',
    '00000000-0000-0000-0000-000000004101',
    '00000000-0000-0000-0000-000000004002',
    'Hidden Author#4002',
    'hidden-map-two',
    '["drinks"]'::jsonb
  ),
  (
    '00000000-0000-0000-0000-000000004204',
    '00000000-0000-0000-0000-000000004101',
    '00000000-0000-0000-0000-000000004003',
    'Visible Author#4003',
    'visible-map',
    '["dairy_eggs"]'::jsonb
  );

set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000004001',
  true
);

select is(
  (select count(*) from public.shared_market_layouts),
  4::bigint,
  'all maps are visible before hiding a creator'
);

select lives_ok(
  $$
    select public.hide_market_layout_creator(
      '00000000-0000-0000-0000-000000004002'
    )
  $$,
  'a user can hide another public map creator'
);

select is(
  (
    select count(*)
    from public.hidden_market_layout_creators
    where hidden_creator_id = '00000000-0000-0000-0000-000000004002'
  ),
  1::bigint,
  'the hidden creator preference is stored for the current user'
);

select is(
  (
    select count(*)
    from public.shared_market_layouts
    where created_by = '00000000-0000-0000-0000-000000004002'
  ),
  0::bigint,
  'all maps from the hidden creator are filtered by RLS'
);

select is(
  (select count(*) from public.shared_market_layouts),
  2::bigint,
  'maps from the current user and other creators remain visible'
);

select lives_ok(
  $$
    select public.hide_market_layout_creator(
      '00000000-0000-0000-0000-000000004002'
    )
  $$,
  'hiding the same creator again is idempotent'
);

select is(
  (select count(*) from public.hidden_market_layout_creators),
  1::bigint,
  'an idempotent hide does not create duplicate preferences'
);

select throws_ok(
  $$
    select public.hide_market_layout_creator(
      '00000000-0000-0000-0000-000000004001'
    )
  $$,
  'P0001',
  'Users cannot hide their own public maps',
  'users cannot hide their own maps'
);

select throws_ok(
  $$select public.hide_market_layout_creator(null)$$,
  'P0001',
  'Public map creator required',
  'a creator id is required'
);

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000004002',
  true
);

select is(
  (select count(*) from public.shared_market_layouts),
  4::bigint,
  'another user does not inherit the viewer hidden creator preference'
);

select is(
  (select count(*) from public.hidden_market_layout_creators),
  0::bigint,
  'hidden creator preferences are private to their owner'
);

select set_config('request.jwt.claim.sub', '', true);

select throws_ok(
  $$
    select public.hide_market_layout_creator(
      '00000000-0000-0000-0000-000000004002'
    )
  $$,
  'P0001',
  'Authentication required',
  'an authenticated role without a user cannot hide creators'
);

select * from finish();
rollback;
