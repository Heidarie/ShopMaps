begin;

create extension if not exists pgtap with schema extensions;

select plan(15);

select has_column(
  'public',
  'profiles',
  'country_code',
  'profiles store the selected online store country'
);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000002001', 'pl-country@example.com'),
  ('00000000-0000-0000-0000-000000002002', 'de-country@example.com'),
  ('00000000-0000-0000-0000-000000002003', 'legacy-country@example.com'),
  ('00000000-0000-0000-0000-000000002004', 'new-country@example.com');

insert into public.profiles (
  id,
  display_name,
  display_name_normalized,
  discriminator,
  country_code
)
values
  (
    '00000000-0000-0000-0000-000000002001',
    'Polish User',
    'polish user',
    2001,
    'pl'
  ),
  (
    '00000000-0000-0000-0000-000000002002',
    'German User',
    'german user',
    2002,
    'de'
  ),
  (
    '00000000-0000-0000-0000-000000002003',
    'Legacy User',
    'legacy user',
    2003,
    null
  );

insert into public.spaces (id, name, created_by)
values (
  '00000000-0000-0000-0000-000000002010',
  'Country Group',
  '00000000-0000-0000-0000-000000002001'
);

insert into public.space_members (space_id, user_id, role)
values (
  '00000000-0000-0000-0000-000000002010',
  '00000000-0000-0000-0000-000000002001',
  'owner'
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
values
  (
    '00000000-0000-0000-0000-000000002101',
    'geoapify',
    'pl-store-place',
    'Polish Market',
    'polish market',
    'Pułaskiego 10, Warszawa',
    'pl',
    52.2,
    21.0
  ),
  (
    '00000000-0000-0000-0000-000000002102',
    'geoapify',
    'de-store-place',
    'German Market',
    'german market',
    'Alexanderplatz 1, Berlin',
    'de',
    52.52,
    13.405
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
    '00000000-0000-0000-0000-000000002201',
    '00000000-0000-0000-0000-000000002101',
    '00000000-0000-0000-0000-000000002001',
    'Polish User#2001',
    'pl-layout',
    '["other"]'::jsonb
  ),
  (
    '00000000-0000-0000-0000-000000002202',
    '00000000-0000-0000-0000-000000002102',
    '00000000-0000-0000-0000-000000002002',
    'German User#2002',
    'de-layout',
    '["other"]'::jsonb
  );

set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000002003',
  true
);

select is(
  (select count(*) from public.store_locations),
  0::bigint,
  'legacy profiles without a country cannot see store locations'
);

select is(
  (select count(*) from public.shared_market_layouts),
  0::bigint,
  'legacy profiles without a country cannot see public maps'
);

select throws_ok(
  $$select public.create_group('Legacy Group')$$,
  'P0001',
  'Complete your profile first',
  'legacy profiles without a country cannot create groups'
);

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000002001',
  true
);

select is(
  (select count(*) from public.store_locations),
  1::bigint,
  'Polish profiles see only Polish store locations'
);

select is(
  (
    select locations.country_code
    from public.shared_market_layouts layouts
    join public.store_locations locations
      on locations.id = layouts.store_location_id
  ),
  'pl',
  'Polish profiles see only Polish public maps'
);

select throws_ok(
  $$
    select public.publish_market_layout(
      '00000000-0000-0000-0000-000000002102',
      'pl-user-de-store',
      '["dry_goods"]'::jsonb
    )
  $$,
  'P0001',
  'STORE_COUNTRY_MISMATCH',
  'users cannot publish maps for stores outside their profile country'
);

select throws_ok(
  $$
    select public.record_market_layout_download(
      '00000000-0000-0000-0000-000000002202'
    )
  $$,
  'P0001',
  'STORE_COUNTRY_MISMATCH',
  'users cannot download maps outside their profile country'
);

select throws_ok(
  $$
    select public.report_public_market_layout(
      '00000000-0000-0000-0000-000000002202',
      'incorrect'
    )
  $$,
  'P0001',
  'STORE_COUNTRY_MISMATCH',
  'users cannot report maps outside their profile country'
);

select throws_ok(
  $$
    select public.move_deposit_voucher_to_group(
      '00000000-0000-0000-0000-000000002010',
      '{
        "id":"foreign-voucher-store",
        "code":"voucher",
        "format":"qr",
        "amount":10,
        "scannedAt":"2026-06-16T10:00:00Z"
      }'::jsonb,
      '00000000-0000-0000-0000-000000002102'
    )
  $$,
  'P0001',
  'STORE_COUNTRY_MISMATCH',
  'users cannot move vouchers to stores outside their profile country'
);

select lives_ok(
  $$
    select public.update_profile_country('de')
  $$,
  'users can change their profile country'
);

select is(
  (
    select locations.country_code
    from public.shared_market_layouts layouts
    join public.store_locations locations
      on locations.id = layouts.store_location_id
  ),
  'de',
  'changing profile country changes public map visibility'
);

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000002004',
  true
);

select throws_ok(
  $$
    select public.complete_profile('No Country', null)
  $$,
  'P0001',
  'Invalid store country',
  'new profiles cannot be completed without a country'
);

select lives_ok(
  $$
    select public.complete_profile('New User', 'gb')
  $$,
  'new profiles can be completed with a country'
);

select is(
  (
    select country_code
    from public.profiles
    where id = '00000000-0000-0000-0000-000000002004'
  ),
  'gb',
  'complete_profile stores the selected country'
);

select * from finish();
rollback;
