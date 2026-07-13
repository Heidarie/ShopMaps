create or replace function app_private.delete_current_user_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  owned_space record;
  successor_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  delete from public.shared_grocery_lists
  where created_by = current_user_id;

  delete from public.shared_grocery_items
  where created_by = current_user_id;

  delete from public.shared_deposit_vouchers
  where created_by = current_user_id;

  update public.shared_deposit_vouchers
  set redeemed_by = null
  where redeemed_by = current_user_id;

  delete from public.group_invites
  where invited_by = current_user_id
     or invited_user_id = current_user_id;

  for owned_space in
    select id
    from public.spaces
    where created_by = current_user_id
    for update
  loop
    select members.user_id
    into successor_id
    from public.space_members members
    where members.space_id = owned_space.id
      and members.user_id <> current_user_id
    order by
      case members.role
        when 'admin' then 0
        when 'member' then 1
        else 2
      end,
      members.joined_at
    limit 1;

    if successor_id is null then
      delete from public.spaces
      where id = owned_space.id;
    else
      update public.spaces
      set created_by = successor_id
      where id = owned_space.id;

      update public.space_members
      set role = case
        when user_id = successor_id then 'owner'
        when role = 'owner' then 'admin'
        else role
      end
      where space_id = owned_space.id;
    end if;
  end loop;

  delete from auth.users
  where id = current_user_id;
end;
$$;

create or replace function public.delete_account()
returns void
language sql
set search_path = ''
as $$
  select app_private.delete_current_user_account();
$$;

revoke all on function app_private.delete_current_user_account() from public;
grant execute on function app_private.delete_current_user_account() to authenticated;

revoke all on function public.delete_account() from public;
grant execute on function public.delete_account() to authenticated;
