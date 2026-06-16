begin;

create extension if not exists pgtap with schema extensions;

select plan(25);

select has_table(
  'app_private',
  'content_filter_terms',
  'blocked terms are stored in a private table'
);
select has_table(
  'app_private',
  'content_filter_allowlist',
  'allowlisted exact values are stored in a private table'
);

select throws_ok(
  $$select app_private.assert_content_allowed('KURWA')$$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'matching is case insensitive'
);
select throws_ok(
  $$select app_private.assert_content_allowed('k.u.r.w.4')$$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'matching catches separators and common leetspeak'
);
select throws_ok(
  $$select app_private.assert_content_allowed('son-of-a-bitch')$$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'matching catches blocked phrases'
);
select lives_ok(
  $$select app_private.assert_content_allowed('Classhole-free groceries')$$,
  'blocked terms are not matched inside longer words'
);

insert into app_private.content_filter_allowlist (value, reason)
values ('Bitch Please', 'pgTAP exact allowlist example');

select lives_ok(
  $$select app_private.assert_content_allowed('Bitch-Please')$$,
  'allowlist permits the exact normalized value'
);
select throws_ok(
  $$select app_private.assert_content_allowed('Bitch Please now')$$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'allowlist does not permit a longer value'
);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-000000000101', 'filter-one@example.com'),
  ('00000000-0000-0000-0000-000000000102', 'filter-two@example.com');

insert into public.profiles (
  id,
  display_name,
  display_name_normalized,
  discriminator
)
values (
  '00000000-0000-0000-0000-000000000101',
  'Filter One',
  'filter one',
  101
);

insert into public.spaces (id, name, created_by)
values (
  '00000000-0000-0000-0000-000000000201',
  'Filter Group',
  '00000000-0000-0000-0000-000000000101'
);

insert into public.space_members (space_id, user_id, role)
values (
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000101',
  'owner'
);

insert into public.shared_grocery_lists (id, space_id, name, created_by)
values (
  '00000000-0000-0000-0000-000000000301',
  '00000000-0000-0000-0000-000000000201',
  'Clean list',
  '00000000-0000-0000-0000-000000000101'
);

select lives_ok(
  $$
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
      '00000000-0000-0000-0000-000000000501',
      'geoapify',
      'filter-place',
      'Clean Store',
      'clean store',
      'K.u.r.w.4 Street 1',
      'pl',
      52.1,
      21.1
    )
  $$,
  'canonical address fields are not filtered'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000102',
  true
);

select throws_ok(
  $$select public.claim_handle('K.u.r.w.4')$$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'profile RPC rejects blocked display names'
);

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000101',
  true
);

select throws_ok(
  $$select public.create_group('Fucking group')$$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'group RPC rejects blocked names'
);
select throws_ok(
  $$
    insert into public.shared_grocery_items (
      list_id,
      name,
      category,
      quantity,
      created_by
    )
    values (
      '00000000-0000-0000-0000-000000000301',
      'K.u.r.w.4',
      'Other',
      1,
      '00000000-0000-0000-0000-000000000101'
    )
  $$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'direct shared item writes cannot bypass name filtering'
);
select throws_ok(
  $$
    insert into public.shared_grocery_items (
      list_id,
      name,
      category,
      quantity,
      created_by
    )
    values (
      '00000000-0000-0000-0000-000000000301',
      'Milk',
      'K.u.r.w.4',
      1,
      '00000000-0000-0000-0000-000000000101'
    )
  $$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'direct shared item writes cannot bypass category filtering'
);
select throws_ok(
  $$
    update public.shared_grocery_lists
    set name = 'K.u.r.w.4'
    where id = '00000000-0000-0000-0000-000000000301'
  $$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'direct shared list updates cannot bypass filtering'
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
      '00000000-0000-0000-0000-000000000201',
      'blocked-store',
      'safe-code',
      'qr',
      10,
      'K.u.r.w.4 Market',
      now(),
      '00000000-0000-0000-0000-000000000101'
    )
  $$,
  'P0001',
  'CANONICAL_STORE_REQUIRED',
  'shared vouchers require a canonical store'
);
select lives_ok(
  $$
    insert into public.shared_deposit_vouchers (
      id,
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
      '00000000-0000-0000-0000-000000000401',
      '00000000-0000-0000-0000-000000000201',
      'offensive-code',
      'K.u.r.w.4-in-a-scanned-code',
      'qr',
      10,
      'Clean Store',
      '00000000-0000-0000-0000-000000000501',
      now(),
      '00000000-0000-0000-0000-000000000101'
    )
  $$,
  'deposit voucher codes are not filtered'
);

set local role postgres;

select throws_ok(
  $$
    insert into public.store_locations (
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
      'geoapify',
      'blocked-store-name',
      'K.u.r.w.4 Market',
      'blocked store',
      'Clean Street 1',
      'pl',
      52.2,
      21.2
    )
  $$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'public store names are filtered'
);
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
      '00000000-0000-0000-0000-000000000501',
      '00000000-0000-0000-0000-000000000101',
      'Filter One#0101',
      'blocked-category-layout',
      '["Food", "K.u.r.w.4"]'::jsonb
    )
  $$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'public map category names are filtered'
);

alter table public.shared_deposit_vouchers
disable trigger shared_deposit_vouchers_enforce_content_filter;
alter table public.shared_deposit_vouchers
disable trigger shared_deposit_vouchers_enforce_canonical_store;
insert into public.shared_deposit_vouchers (
  id,
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
  '00000000-0000-0000-0000-000000000402',
  '00000000-0000-0000-0000-000000000201',
  'legacy-voucher',
  'legacy-code',
  'qr',
  10,
  'K.u.r.w.4 Market',
  now(),
  '00000000-0000-0000-0000-000000000101'
);
alter table public.shared_deposit_vouchers
enable trigger shared_deposit_vouchers_enforce_content_filter;
alter table public.shared_deposit_vouchers
enable trigger shared_deposit_vouchers_enforce_canonical_store;

select lives_ok(
  $$
    update public.shared_deposit_vouchers
    set redeemed_at = now(),
        redeemed_by = '00000000-0000-0000-0000-000000000101'
    where id = '00000000-0000-0000-0000-000000000402'
  $$,
  'updates that do not change protected text remain allowed'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000101',
  true
);

select throws_ok(
  $$
    select public.copy_grocery_list_to_group(
      '00000000-0000-0000-0000-000000000201',
      'atomic-filter-list',
      'Imported list',
      '[
        {"name":"Milk","category":"Food","quantity":1},
        {"name":"K.u.r.w.4","category":"Food","quantity":1}
      ]'::jsonb
    )
  $$,
  'P0001',
  'CONTENT_NOT_ALLOWED',
  'bulk list sharing rejects a blocked item'
);

set local role postgres;

select is(
  (
    select count(*)
    from public.shared_grocery_lists
    where source_local_id = 'atomic-filter-list'
  ),
  0::bigint,
  'rejected bulk list sharing leaves no partial list'
);
select is(
  (
    select count(*)
    from public.shared_grocery_items items
    join public.shared_grocery_lists lists on lists.id = items.list_id
    where lists.source_local_id = 'atomic-filter-list'
  ),
  0::bigint,
  'rejected bulk list sharing leaves no partial items'
);

insert into public.group_invites (
  id,
  space_id,
  invited_user_id,
  invited_by,
  space_name_snapshot,
  inviter_handle_snapshot
)
values (
  '00000000-0000-0000-0000-000000000601',
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000102',
  '00000000-0000-0000-0000-000000000101',
  'K.u.r.w.4 Group',
  'Filter One#0101'
);

insert into public.shared_market_layouts (
  id,
  store_location_id,
  created_by,
  creator_handle_snapshot,
  source_local_id,
  category_order
)
values (
  '00000000-0000-0000-0000-000000000701',
  '00000000-0000-0000-0000-000000000501',
  '00000000-0000-0000-0000-000000000101',
  'K.u.r.w.4#0101',
  'legacy-snapshot-layout',
  '["Food"]'::jsonb
);

select ok(
  exists (
    select 1
    from app_private.content_filter_audit()
    where source_table = 'group_invites'
      and record_id = '00000000-0000-0000-0000-000000000601'
      and field_name = 'space_name_snapshot'
  ),
  'audit reports existing group invitation snapshots'
);
select ok(
  exists (
    select 1
    from app_private.content_filter_audit()
    where source_table = 'shared_market_layouts'
      and record_id = '00000000-0000-0000-0000-000000000701'
      and field_name = 'creator_handle_snapshot'
  ),
  'audit reports existing public map snapshots'
);
select is(
  (
    select count(*)
    from app_private.content_filter_audit()
    where field_name in ('code', 'formatted_address')
  ),
  0::bigint,
  'audit excludes operational codes and canonical addresses'
);

select * from finish();
rollback;
