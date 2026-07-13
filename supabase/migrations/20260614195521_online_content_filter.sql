create or replace function app_private.content_filter_normalize(value text)
returns text
language sql
immutable
set search_path = ''
as $$
  select translate(
    translate(
      lower(coalesce(value, '')),
      'ąćęłńóśźż',
      'acelnoszz'
    ),
    '01234578@$!|',
    'oizeastbasii'
  );
$$;

create or replace function app_private.content_filter_compact(value text)
returns text
language sql
immutable
set search_path = ''
as $$
  select regexp_replace(
    app_private.content_filter_normalize(value),
    '[^a-z0-9]+',
    '',
    'g'
  );
$$;

create or replace function app_private.content_filter_pattern(value text)
returns text
language sql
immutable
set search_path = ''
as $$
  with normalized as (
    select app_private.content_filter_compact(value) as term
  )
  select
    '(^|[^a-z0-9])'
    || coalesce(
      (
        select string_agg(
          substr(normalized.term, character_index, 1),
          '[^a-z0-9]*'
          order by character_index
        )
        from generate_series(
          1,
          char_length(normalized.term)
        ) character_index
      ),
      ''
    )
    || '([^a-z0-9]|$)'
  from normalized;
$$;

create table app_private.content_filter_terms (
  id bigint generated always as identity primary key,
  term text not null,
  category text not null default 'profanity'
    check (category in ('profanity', 'insult', 'slur')),
  active boolean not null default true,
  normalized_term text generated always as (
    app_private.content_filter_compact(term)
  ) stored,
  match_pattern text generated always as (
    app_private.content_filter_pattern(term)
  ) stored,
  created_at timestamptz not null default now(),
  check (normalized_term <> ''),
  unique (normalized_term)
);

create table app_private.content_filter_allowlist (
  id bigint generated always as identity primary key,
  value text not null,
  normalized_value text generated always as (
    app_private.content_filter_compact(value)
  ) stored,
  reason text,
  created_at timestamptz not null default now(),
  check (normalized_value <> ''),
  unique (normalized_value)
);

revoke all on table app_private.content_filter_terms
  from public, anon, authenticated;
revoke all on table app_private.content_filter_allowlist
  from public, anon, authenticated;

insert into app_private.content_filter_terms (term, category)
values
  ('kurwa', 'profanity'),
  ('kurwo', 'profanity'),
  ('chuj', 'profanity'),
  ('chuju', 'profanity'),
  ('pizda', 'profanity'),
  ('pizdo', 'profanity'),
  ('pierdol', 'profanity'),
  ('pierdolony', 'profanity'),
  ('pierdolona', 'profanity'),
  ('jebać', 'profanity'),
  ('jebany', 'profanity'),
  ('jebana', 'profanity'),
  ('skurwysyn', 'insult'),
  ('skurwiel', 'insult'),
  ('kutas', 'profanity'),
  ('cipa', 'profanity'),
  ('dupek', 'insult'),
  ('debil', 'insult'),
  ('idiota', 'insult'),
  ('kretyn', 'insult'),
  ('frajer', 'insult'),
  ('szmata', 'insult'),
  ('fuck', 'profanity'),
  ('fucker', 'profanity'),
  ('fucking', 'profanity'),
  ('motherfucker', 'profanity'),
  ('shit', 'profanity'),
  ('bullshit', 'profanity'),
  ('bitch', 'insult'),
  ('son of a bitch', 'insult'),
  ('asshole', 'insult'),
  ('bastard', 'insult'),
  ('cunt', 'profanity'),
  ('dickhead', 'insult'),
  ('retard', 'slur'),
  ('moron', 'insult'),
  ('idiot', 'insult');

create or replace function app_private.find_content_filter_match(candidate text)
returns table(term_id bigint, matched_term text)
language sql
stable
security definer
set search_path = ''
as $$
  select terms.id, terms.term
  from app_private.content_filter_terms terms
  where terms.active
    and not exists (
      select 1
      from app_private.content_filter_allowlist allowed
      where allowed.normalized_value = app_private.content_filter_compact(candidate)
    )
    and app_private.content_filter_normalize(candidate) ~ terms.match_pattern
  order by char_length(terms.normalized_term) desc, terms.id
  limit 1;
$$;

create or replace function app_private.assert_content_allowed(value text)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1
    from app_private.find_content_filter_match(value)
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'CONTENT_NOT_ALLOWED',
      detail = 'CONTENT_NOT_ALLOWED';
  end if;
end;
$$;

create or replace function app_private.enforce_content_filter()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  field_name text;
  new_value jsonb;
  old_value jsonb;
  array_item text;
begin
  foreach field_name in array tg_argv
  loop
    new_value := to_jsonb(new) -> field_name;

    if tg_op = 'UPDATE' then
      old_value := to_jsonb(old) -> field_name;
      if new_value is not distinct from old_value then
        continue;
      end if;
    end if;

    if jsonb_typeof(new_value) = 'array' then
      for array_item in
        select jsonb_array_elements_text(new_value)
      loop
        perform app_private.assert_content_allowed(array_item);
      end loop;
    elsif new_value is not null and jsonb_typeof(new_value) = 'string' then
      perform app_private.assert_content_allowed(new_value #>> '{}');
    end if;
  end loop;

  return new;
end;
$$;

create trigger profiles_enforce_content_filter
before insert or update on public.profiles
for each row execute function app_private.enforce_content_filter('display_name');

create trigger spaces_enforce_content_filter
before insert or update on public.spaces
for each row execute function app_private.enforce_content_filter('name');

create trigger shared_grocery_lists_enforce_content_filter
before insert or update on public.shared_grocery_lists
for each row execute function app_private.enforce_content_filter('name');

create trigger shared_grocery_items_enforce_content_filter
before insert or update on public.shared_grocery_items
for each row execute function app_private.enforce_content_filter('name', 'category');

create trigger shared_deposit_vouchers_enforce_content_filter
before insert or update on public.shared_deposit_vouchers
for each row execute function app_private.enforce_content_filter('store_name');

create trigger store_locations_enforce_content_filter
before insert or update on public.store_locations
for each row execute function app_private.enforce_content_filter('store_name');

create trigger shared_market_layouts_enforce_content_filter
before insert or update on public.shared_market_layouts
for each row execute function app_private.enforce_content_filter('category_order');

create or replace function app_private.content_filter_audit()
returns table(
  source_table text,
  record_id text,
  field_name text,
  field_value text,
  matched_term_id bigint,
  matched_term text
)
language sql
stable
security definer
set search_path = ''
as $$
  with content(source_table, record_id, field_name, field_value) as (
    select 'profiles'::text, profiles.id::text, 'display_name'::text, profiles.display_name
    from public.profiles profiles
    union all
    select 'spaces', spaces.id::text, 'name', spaces.name
    from public.spaces spaces
    union all
    select 'group_invites', invites.id::text, 'space_name_snapshot', invites.space_name_snapshot
    from public.group_invites invites
    union all
    select 'group_invites', invites.id::text, 'inviter_handle_snapshot', invites.inviter_handle_snapshot
    from public.group_invites invites
    union all
    select 'shared_grocery_lists', lists.id::text, 'name', lists.name
    from public.shared_grocery_lists lists
    union all
    select 'shared_grocery_items', items.id::text, 'name', items.name
    from public.shared_grocery_items items
    union all
    select 'shared_grocery_items', items.id::text, 'category', items.category
    from public.shared_grocery_items items
    union all
    select 'shared_deposit_vouchers', vouchers.id::text, 'store_name', vouchers.store_name
    from public.shared_deposit_vouchers vouchers
    union all
    select 'store_locations', locations.id::text, 'store_name', locations.store_name
    from public.store_locations locations
    union all
    select 'shared_market_layouts', layouts.id::text, 'creator_handle_snapshot', layouts.creator_handle_snapshot
    from public.shared_market_layouts layouts
    union all
    select
      'shared_market_layouts',
      layouts.id::text,
      'category_order[' || categories.ordinality::text || ']',
      categories.value
    from public.shared_market_layouts layouts
    cross join lateral jsonb_array_elements_text(layouts.category_order)
      with ordinality as categories(value, ordinality)
  )
  select
    content.source_table,
    content.record_id,
    content.field_name,
    content.field_value,
    matches.term_id,
    matches.matched_term
  from content
  cross join lateral app_private.find_content_filter_match(content.field_value) matches;
$$;

revoke all on function app_private.content_filter_normalize(text)
  from public, anon, authenticated;
revoke all on function app_private.content_filter_compact(text)
  from public, anon, authenticated;
revoke all on function app_private.content_filter_pattern(text)
  from public, anon, authenticated;
revoke all on function app_private.find_content_filter_match(text)
  from public, anon, authenticated;
revoke all on function app_private.assert_content_allowed(text)
  from public, anon, authenticated;
revoke all on function app_private.enforce_content_filter()
  from public, anon, authenticated;
revoke all on function app_private.content_filter_audit()
  from public, anon, authenticated;
