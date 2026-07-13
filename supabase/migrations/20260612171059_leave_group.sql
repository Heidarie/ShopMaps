create or replace function app_private.leave_group(target_space_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  current_role text;
  successor_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  perform 1
  from public.spaces
  where id = target_space_id
  for update;

  select members.role
  into current_role
  from public.space_members members
  where members.space_id = target_space_id
    and members.user_id = current_user_id;

  if current_role is null then
    raise exception 'Group membership required';
  end if;

  if current_role = 'owner' then
    select members.user_id
    into successor_id
    from public.space_members members
    where members.space_id = target_space_id
      and members.user_id <> current_user_id
    order by
      case members.role
        when 'admin' then 0
        when 'member' then 1
        else 2
      end,
      members.joined_at,
      members.user_id
    limit 1;

    if successor_id is null then
      delete from public.spaces
      where id = target_space_id;
      return;
    end if;

    update public.spaces
    set created_by = successor_id
    where id = target_space_id;

    update public.space_members
    set role = case
      when user_id = successor_id then 'owner'
      when role = 'owner' then 'admin'
      else role
    end
    where space_id = target_space_id;
  end if;

  delete from public.space_members
  where space_id = target_space_id
    and user_id = current_user_id;
end;
$$;

create or replace function public.leave_group(target_space_id uuid)
returns void
language sql
set search_path = ''
as $$
  select app_private.leave_group(target_space_id);
$$;

revoke all on function app_private.leave_group(uuid) from public;
grant execute on function app_private.leave_group(uuid) to authenticated;

revoke all on function public.leave_group(uuid) from public;
grant execute on function public.leave_group(uuid) to authenticated;
