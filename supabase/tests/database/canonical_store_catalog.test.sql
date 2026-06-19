begin;

create extension if not exists pgtap with schema extensions;

select plan(10);

select has_column(
  'public',
  'shared_deposit_vouchers',
  'store_location_id',
  'shared vouchers reference the canonical store catalog'
);

select ok(
  has_table_privilege('service_role', 'public.store_locations', 'INSERT')
    and has_table_privilege('service_role', 'public.store_locations', 'UPDATE'),
  'the authenticated Edge Function backend can maintain the store catalog'
);

insert into auth.users (id, email)
values ('00000000-0000-0000-0000-000000001001', 'catalog@example.com');

insert into public.profiles (
  id,
  display_name,
  display_name_normalized,
  discriminator
)
values (
  '00000000-0000-0000-0000-000000001001',
  'Catalog User',
  'catalog user',
  1001
);

insert into public.spaces (id, name, created_by)
values (
  '00000000-0000-0000-0000-000000001002',
  'Catalog Group',
  '00000000-0000-0000-0000-000000001001'
);

insert into public.space_members (space_id, user_id, role)
values (
  '00000000-0000-0000-0000-000000001002',
  '00000000-0000-0000-0000-000000001001',
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
values (
  '00000000-0000-0000-0000-000000001003',
  'geoapify',
  'canonical-store-place',
  'Canonical Market',
  'canonical market',
  'Pułaskiego 10, Warszawa',
  'pl',
  52.2,
  21.0
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000001001',
  true
);

select throws_ok(
  $$
    insert into public.shared_deposit_vouchers (
      space_id,
      source_local_id,
      code,
      format,
      amount,
      store_name,
      scanned_at,
      created_by
    )
    values (
      '00000000-0000-0000-0000-000000001002',
      'missing-store',
      'code-one',
      'qr',
      10,
      'Typed Store',
      now(),
      '00000000-0000-0000-0000-000000001001'
    )
  $$,
  'P0001',
  'CANONICAL_STORE_REQUIRED',
  'direct shared voucher inserts require a catalog store'
);

select lives_ok(
  $$
    insert into public.shared_deposit_vouchers (
      space_id,
      source_local_id,
      code,
      format,
      amount,
      store_name,
      store_location_id,
      scanned_at,
      created_by
    )
    values (
      '00000000-0000-0000-0000-000000001002',
      'canonical-direct',
      'code-two',
      'qr',
      10,
      'Client supplied name is ignored',
      '00000000-0000-0000-0000-000000001003',
      now(),
      '00000000-0000-0000-0000-000000001001'
    )
  $$,
  'direct shared voucher inserts accept a catalog store'
);

select is(
  (
    select store_name
    from public.shared_deposit_vouchers
    where source_local_id = 'canonical-direct'
  ),
  'Canonical Market',
  'shared voucher store name is derived from the catalog'
);

select lives_ok(
  $$
    select public.move_deposit_voucher_to_group(
      '00000000-0000-0000-0000-000000001002',
      '{
        "id":"canonical-rpc",
        "code":"code-three",
        "format":"qr",
        "amount":12,
        "storeName":"Ignored local name",
        "scannedAt":"2026-06-14T12:00:00Z"
      }'::jsonb,
      '00000000-0000-0000-0000-000000001003'
    )
  $$,
  'voucher RPC accepts only a catalog store id'
);

select is(
  (
    select store_name
    from public.shared_deposit_vouchers
    where source_local_id = 'canonical-rpc'
  ),
  'Canonical Market',
  'voucher RPC stores the canonical name'
);

select throws_ok(
  $$
    select public.publish_market_layout(
      '00000000-0000-0000-0000-000000001099',
      'missing-catalog-store',
      '["dry_goods"]'::jsonb
    )
  $$,
  'P0001',
  'CANONICAL_STORE_REQUIRED',
  'public maps reject unknown store ids'
);

select is(
  public.publish_market_layout(
    '00000000-0000-0000-0000-000000001003',
    'canonical-layout',
    '["dry_goods"]'::jsonb
  ),
  'published',
  'public maps accept a canonical store id'
);

select is(
  (
    select store_location_id
    from public.shared_market_layouts
    where source_local_id = 'canonical-layout'
  ),
  '00000000-0000-0000-0000-000000001003'::uuid,
  'published map references the selected catalog store'
);

select * from finish();
rollback;
