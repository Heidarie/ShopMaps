create table public.push_devices (
  token text primary key check (char_length(token) between 20 and 4096),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('android', 'ios')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index push_devices_user_id_idx on public.push_devices(user_id);

alter table public.push_devices enable row level security;

revoke all on public.push_devices from anon, authenticated;
grant select, delete on public.push_devices to service_role;

create table app_private.shared_list_notification_state (
  list_id uuid not null references public.shared_grocery_lists(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  last_notified_item_created_at timestamptz not null,
  updated_at timestamptz not null default now(),
  primary key (list_id, user_id)
);

create or replace function app_private.register_push_device(
  device_token text,
  device_platform text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  cleaned_token text := trim(device_token);
  cleaned_platform text := lower(trim(device_platform));
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if char_length(cleaned_token) < 20 or char_length(cleaned_token) > 4096 then
    raise exception 'Invalid push token';
  end if;

  if cleaned_platform not in ('android', 'ios') then
    raise exception 'Invalid push platform';
  end if;

  insert into public.push_devices (token, user_id, platform)
  values (cleaned_token, current_user_id, cleaned_platform)
  on conflict (token) do update
  set
    user_id = excluded.user_id,
    platform = excluded.platform,
    updated_at = now();
end;
$$;

create or replace function app_private.unregister_push_device(device_token text)
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

  delete from public.push_devices
  where token = trim(device_token)
    and user_id = current_user_id;
end;
$$;

create or replace function app_private.claim_shared_list_addition_notification(
  target_list_id uuid
)
returns table(target_space_id uuid, target_list_name text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  latest_addition_at timestamptz;
  last_notified_at timestamptz;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  select lists.space_id, lists.name
  into target_space_id, target_list_name
  from public.shared_grocery_lists lists
  where lists.id = target_list_id
    and app_private.is_space_member(lists.space_id, current_user_id);

  if target_space_id is null then
    raise exception 'Shared list membership required';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      target_list_id::text || ':' || current_user_id::text,
      0
    )
  );

  select max(items.created_at)
  into latest_addition_at
  from public.shared_grocery_items items
  where items.list_id = target_list_id
    and items.created_by = current_user_id;

  if latest_addition_at is null then
    return;
  end if;

  select state.last_notified_item_created_at
  into last_notified_at
  from app_private.shared_list_notification_state state
  where state.list_id = target_list_id
    and state.user_id = current_user_id;

  if last_notified_at is not null and latest_addition_at <= last_notified_at then
    return;
  end if;

  insert into app_private.shared_list_notification_state (
    list_id,
    user_id,
    last_notified_item_created_at
  )
  values (target_list_id, current_user_id, latest_addition_at)
  on conflict (list_id, user_id) do update
  set
    last_notified_item_created_at = excluded.last_notified_item_created_at,
    updated_at = now();

  return next;
end;
$$;

create or replace function public.register_push_device(
  device_token text,
  device_platform text
)
returns void
language sql
set search_path = ''
as $$
  select app_private.register_push_device(device_token, device_platform);
$$;

create or replace function public.unregister_push_device(device_token text)
returns void
language sql
set search_path = ''
as $$
  select app_private.unregister_push_device(device_token);
$$;

create or replace function public.claim_shared_list_addition_notification(
  target_list_id uuid
)
returns table(target_space_id uuid, target_list_name text)
language sql
set search_path = ''
as $$
  select *
  from app_private.claim_shared_list_addition_notification(target_list_id);
$$;

revoke all on function app_private.register_push_device(text, text) from public;
revoke all on function app_private.unregister_push_device(text) from public;
revoke all on function app_private.claim_shared_list_addition_notification(uuid)
  from public;
grant execute on function app_private.register_push_device(text, text)
  to authenticated;
grant execute on function app_private.unregister_push_device(text)
  to authenticated;
grant execute on function app_private.claim_shared_list_addition_notification(uuid)
  to authenticated;

revoke all on function public.register_push_device(text, text) from public;
revoke all on function public.unregister_push_device(text) from public;
revoke all on function public.claim_shared_list_addition_notification(uuid)
  from public;
grant execute on function public.register_push_device(text, text)
  to authenticated;
grant execute on function public.unregister_push_device(text)
  to authenticated;
grant execute on function public.claim_shared_list_addition_notification(uuid)
  to authenticated;
