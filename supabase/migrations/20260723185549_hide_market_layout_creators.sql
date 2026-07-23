create table public.hidden_market_layout_creators (
  user_id uuid not null references auth.users(id) on delete cascade,
  hidden_creator_id uuid not null references auth.users(id) on delete cascade,
  hidden_at timestamptz not null default now(),
  primary key (user_id, hidden_creator_id),
  constraint hidden_market_layout_creators_cannot_hide_self
    check (user_id <> hidden_creator_id)
);

create index hidden_market_layout_creators_hidden_creator_id_idx
  on public.hidden_market_layout_creators(hidden_creator_id);

alter table public.hidden_market_layout_creators enable row level security;

create policy "Users can read their hidden market layout creators"
on public.hidden_market_layout_creators for select
to authenticated
using (user_id = (select auth.uid()));

revoke all on public.hidden_market_layout_creators from anon, authenticated;
grant select on public.hidden_market_layout_creators to authenticated;

create or replace function app_private.hide_market_layout_creator(
  target_creator_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  perform app_private.assert_complete_profile(current_user_id);

  if target_creator_id is null then
    raise exception 'Public map creator required';
  end if;

  if target_creator_id = current_user_id then
    raise exception 'Users cannot hide their own public maps';
  end if;

  if not exists (
    select 1
    from public.shared_market_layouts layouts
    join public.store_locations locations
      on locations.id = layouts.store_location_id
    where layouts.created_by = target_creator_id
      and locations.country_code = app_private.current_profile_country(
        current_user_id
      )
  ) then
    if exists (
      select 1
      from public.shared_market_layouts layouts
      where layouts.created_by = target_creator_id
    ) then
      raise exception using
        errcode = 'P0001',
        message = 'STORE_COUNTRY_MISMATCH',
        detail = 'STORE_COUNTRY_MISMATCH';
    end if;

    raise exception 'Public map creator not found';
  end if;

  insert into public.hidden_market_layout_creators (
    user_id,
    hidden_creator_id
  )
  values (current_user_id, target_creator_id)
  on conflict (user_id, hidden_creator_id) do nothing;
end;
$$;

create or replace function public.hide_market_layout_creator(
  target_creator_id uuid
)
returns void
language sql
set search_path = ''
as $$
  select app_private.hide_market_layout_creator(target_creator_id);
$$;

revoke all on function app_private.hide_market_layout_creator(uuid)
  from public, anon, authenticated;
grant execute on function app_private.hide_market_layout_creator(uuid)
  to authenticated;

revoke all on function public.hide_market_layout_creator(uuid)
  from public, anon, authenticated;
grant execute on function public.hide_market_layout_creator(uuid)
  to authenticated;

drop policy if exists
  "Users can read public market layouts in their profile country"
on public.shared_market_layouts;

create policy "Users can read non-hidden public market layouts"
on public.shared_market_layouts for select
to authenticated
using (
  exists (
    select 1
    from public.store_locations locations
    where locations.id = store_location_id
      and locations.country_code = app_private.current_profile_country(
        (select auth.uid())
      )
  )
  and not exists (
    select 1
    from public.hidden_market_layout_creators hidden_creators
    where hidden_creators.user_id = (select auth.uid())
      and hidden_creators.hidden_creator_id =
        shared_market_layouts.created_by
  )
);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'hidden_market_layout_creators'
  ) then
    alter publication supabase_realtime
      add table public.hidden_market_layout_creators;
  end if;
end
$$;
