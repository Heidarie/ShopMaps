create table public.hidden_shared_deposit_vouchers (
  user_id uuid not null references auth.users(id) on delete cascade,
  voucher_id uuid not null references public.shared_deposit_vouchers(id)
    on delete cascade,
  hidden_at timestamptz not null default now(),
  primary key (user_id, voucher_id)
);

alter table public.hidden_shared_deposit_vouchers enable row level security;

create policy "Users can read their hidden shared deposit vouchers"
on public.hidden_shared_deposit_vouchers for select
to authenticated
using (user_id = (select auth.uid()));

revoke all on public.hidden_shared_deposit_vouchers from anon, authenticated;
grant select on public.hidden_shared_deposit_vouchers to authenticated;

create or replace function app_private.list_group_members(target_space_id uuid)
returns table(member_user_id uuid, display_name text, member_role text)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null
    or not app_private.is_space_member(target_space_id, current_user_id)
  then
    raise exception 'Group membership required';
  end if;

  return query
  select
    members.user_id,
    profiles.display_name,
    members.role
  from public.space_members members
  join public.profiles profiles on profiles.id = members.user_id
  where members.space_id = target_space_id
  order by profiles.display_name_normalized, profiles.discriminator;
end;
$$;

create or replace function app_private.hide_shared_deposit_voucher(
  target_voucher_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  target_space_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  select vouchers.space_id
  into target_space_id
  from public.shared_deposit_vouchers vouchers
  where vouchers.id = target_voucher_id;

  if target_space_id is null
    or not app_private.is_space_member(target_space_id, current_user_id)
  then
    raise exception 'Shared deposit voucher membership required';
  end if;

  insert into public.hidden_shared_deposit_vouchers (user_id, voucher_id)
  values (current_user_id, target_voucher_id)
  on conflict (user_id, voucher_id) do nothing;
end;
$$;

create or replace function app_private.use_shared_deposit_voucher(
  target_voucher_id uuid
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

  delete from public.shared_deposit_vouchers vouchers
  where vouchers.id = target_voucher_id
    and app_private.is_space_member(vouchers.space_id, current_user_id);

  if not found then
    raise exception 'Shared deposit voucher membership required';
  end if;
end;
$$;

create or replace function public.list_group_members(target_space_id uuid)
returns table(member_user_id uuid, display_name text, member_role text)
language sql
set search_path = ''
as $$
  select *
  from app_private.list_group_members(target_space_id);
$$;

create or replace function public.hide_shared_deposit_voucher(
  target_voucher_id uuid
)
returns void
language sql
set search_path = ''
as $$
  select app_private.hide_shared_deposit_voucher(target_voucher_id);
$$;

create or replace function public.use_shared_deposit_voucher(
  target_voucher_id uuid
)
returns void
language sql
set search_path = ''
as $$
  select app_private.use_shared_deposit_voucher(target_voucher_id);
$$;

drop policy if exists "Creators and admins can delete shared deposit vouchers"
on public.shared_deposit_vouchers;
drop policy if exists "Members can delete shared deposit vouchers"
on public.shared_deposit_vouchers;
revoke delete on public.shared_deposit_vouchers from authenticated;

revoke all on function app_private.list_group_members(uuid) from public;
revoke all on function app_private.hide_shared_deposit_voucher(uuid) from public;
revoke all on function app_private.use_shared_deposit_voucher(uuid) from public;
grant execute on function app_private.list_group_members(uuid) to authenticated;
grant execute on function app_private.hide_shared_deposit_voucher(uuid)
  to authenticated;
grant execute on function app_private.use_shared_deposit_voucher(uuid)
  to authenticated;

revoke all on function public.list_group_members(uuid) from public;
revoke all on function public.hide_shared_deposit_voucher(uuid) from public;
revoke all on function public.use_shared_deposit_voucher(uuid) from public;
grant execute on function public.list_group_members(uuid) to authenticated;
grant execute on function public.hide_shared_deposit_voucher(uuid)
  to authenticated;
grant execute on function public.use_shared_deposit_voucher(uuid)
  to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'hidden_shared_deposit_vouchers'
  ) then
    alter publication supabase_realtime
      add table public.hidden_shared_deposit_vouchers;
  end if;
end
$$;
