begin;

create extension if not exists pgtap with schema extensions;

select plan(16);

select has_table(
  'public',
  'online_categories',
  'online category metadata table exists'
);

select has_table(
  'public',
  'online_category_labels',
  'online category label table exists'
);

select is(
  (
    select relrowsecurity
    from pg_class
    where oid = 'public.online_categories'::regclass
  ),
  true,
  'online category metadata has RLS enabled'
);

select is(
  (
    select relrowsecurity
    from pg_class
    where oid = 'public.online_category_labels'::regclass
  ),
  true,
  'online category labels have RLS enabled'
);

select ok(
  has_table_privilege(
    'authenticated',
    'public.online_categories',
    'select'
  ),
  'authenticated users can read online category metadata'
);

select ok(
  not has_table_privilege('anon', 'public.online_categories', 'select'),
  'signed-out clients cannot read online category metadata'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.get_online_category_catalog()',
    'execute'
  ),
  'authenticated users can execute the category catalog RPC'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.get_online_category_catalog()',
    'execute'
  ),
  'signed-out clients cannot execute the category catalog RPC'
);

select is(
  (select count(*) from public.online_categories),
  32::bigint,
  'catalog contains all category metadata rows'
);

select is(
  (select count(*) from public.online_category_labels),
  288::bigint,
  'catalog contains nine translations for every category'
);

select is(
  (select count(*) from public.get_online_category_catalog()),
  32::bigint,
  'catalog RPC returns every known category'
);

select is(
  (
    select count(*)
    from jsonb_object_keys(
      (
        select labels
        from public.get_online_category_catalog()
        where category_id = 'nuts_seeds'
      )
    )
  ),
  9::bigint,
  'catalog RPC returns every supported translation'
);

insert into public.online_categories (
  category_id,
  sort_order,
  active,
  aliases
)
values (
  'dynamic_test',
  1000,
  false,
  array['dynamic alias']
);

insert into public.online_category_labels (
  category_id,
  language_code,
  sort_order,
  name
)
values
  ('dynamic_test', 'en', 1000, 'Dynamic test'),
  ('dynamic_test', 'pl', 1000, 'Test dynamiczny');

select ok(
  app_private.is_online_category_id('dynamic_test'),
  'new database categories become valid without a backend code change'
);

select is(
  app_private.online_category_id_for_value('dynamic alias'),
  'dynamic_test',
  'database aliases participate in legacy category normalization'
);

select is(
  app_private.validate_online_category_order(
    '["dynamic_test", "coffee"]'::jsonb
  ),
  '["dynamic_test", "coffee"]'::jsonb,
  'database categories are accepted by market layout validation'
);

select is(
  (
    select labels ->> 'pl'
    from public.get_online_category_catalog()
    where category_id = 'dynamic_test'
  ),
  'Test dynamiczny',
  'catalog RPC includes labels for inactive compatibility categories'
);

select * from finish();
rollback;
