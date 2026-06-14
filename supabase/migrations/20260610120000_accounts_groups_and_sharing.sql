create schema if not exists app_private;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 24),
  display_name_normalized text not null,
  discriminator smallint not null check (discriminator between 0 and 9999),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (display_name_normalized, discriminator)
);

create table public.spaces (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 100),
  kind text not null default 'group' check (kind = 'group'),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.space_members (
  space_id uuid not null references public.spaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null default now(),
  primary key (space_id, user_id)
);

create table public.group_invites (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.spaces(id) on delete cascade,
  invited_user_id uuid not null references auth.users(id) on delete cascade,
  invited_by uuid not null references auth.users(id) on delete cascade,
  space_name_snapshot text not null,
  inviter_handle_snapshot text not null,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  unique (space_id, invited_user_id)
);

create table public.shared_grocery_lists (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.spaces(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100),
  created_by uuid not null references auth.users(id) on delete restrict,
  source_local_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.shared_grocery_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references public.shared_grocery_lists(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100),
  category text not null check (char_length(category) between 1 and 100),
  quantity integer not null default 1 check (quantity > 0),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.shared_deposit_vouchers (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.spaces(id) on delete cascade,
  source_local_id text,
  code text not null check (char_length(code) between 1 and 2048),
  format text not null default 'unknown',
  amount numeric(12, 2) not null default 0 check (amount >= 0),
  store_name text not null check (char_length(store_name) between 1 and 100),
  scanned_at timestamptz not null,
  valid_until timestamptz,
  created_by uuid not null references auth.users(id) on delete restrict,
  redeemed_at timestamptz,
  redeemed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index space_members_user_id_idx on public.space_members(user_id);
create index group_invites_invited_user_id_status_idx
  on public.group_invites(invited_user_id, status);
create index shared_grocery_lists_space_id_idx on public.shared_grocery_lists(space_id);
create index shared_grocery_items_list_id_idx on public.shared_grocery_items(list_id);
create index shared_deposit_vouchers_space_id_idx
  on public.shared_deposit_vouchers(space_id);
create unique index shared_deposit_vouchers_source_local_id_idx
  on public.shared_deposit_vouchers(space_id, source_local_id)
  where source_local_id is not null;

create or replace function app_private.normalized_handle_name(value text)
returns text
language sql
immutable
set search_path = ''
as $$
  select lower(regexp_replace(trim(value), '\s+', ' ', 'g'));
$$;

create or replace function app_private.profile_handle(profile public.profiles)
returns text
language sql
stable
set search_path = ''
as $$
  select profile.display_name || '#' || lpad(profile.discriminator::text, 4, '0');
$$;

create or replace function app_private.is_space_member(target_space_id uuid, target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.space_members
    where space_id = target_space_id
      and user_id = target_user_id
  );
$$;

create or replace function app_private.is_space_admin(target_space_id uuid, target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.space_members
    where space_id = target_space_id
      and user_id = target_user_id
      and role in ('owner', 'admin')
  );
$$;

create or replace function app_private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function app_private.touch_updated_at();

create trigger spaces_touch_updated_at
before update on public.spaces
for each row execute function app_private.touch_updated_at();

create trigger shared_grocery_lists_touch_updated_at
before update on public.shared_grocery_lists
for each row execute function app_private.touch_updated_at();

create trigger shared_grocery_items_touch_updated_at
before update on public.shared_grocery_items
for each row execute function app_private.touch_updated_at();

create trigger shared_deposit_vouchers_touch_updated_at
before update on public.shared_deposit_vouchers
for each row execute function app_private.touch_updated_at();

create or replace function app_private.claim_handle(requested_display_name text)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  cleaned_name text := regexp_replace(trim(requested_display_name), '\s+', ' ', 'g');
  normalized_name text;
  candidate_tag integer;
  claimed_profile public.profiles;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if char_length(cleaned_name) < 2 or char_length(cleaned_name) > 24 then
    raise exception 'Display name must contain between 2 and 24 characters';
  end if;

  if cleaned_name ~ '#' then
    raise exception 'Display name cannot contain #';
  end if;

  select * into claimed_profile from public.profiles where id = current_user_id;
  if found then
    return claimed_profile;
  end if;

  normalized_name := app_private.normalized_handle_name(cleaned_name);

  for attempt in 1..100 loop
    candidate_tag := floor(random() * 10000)::integer;
    begin
      insert into public.profiles (
        id,
        display_name,
        display_name_normalized,
        discriminator
      ) values (
        current_user_id,
        cleaned_name,
        normalized_name,
        candidate_tag
      )
      returning * into claimed_profile;

      return claimed_profile;
    exception when unique_violation then
      -- Try another discriminator for the same normalized name.
    end;
  end loop;

  raise exception 'Could not allocate a unique tag. Try another display name.';
end;
$$;

create or replace function app_private.create_group(group_name text)
returns public.spaces
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  cleaned_name text := regexp_replace(trim(group_name), '\s+', ' ', 'g');
  created_space public.spaces;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not exists (select 1 from public.profiles where id = current_user_id) then
    raise exception 'Complete your profile first';
  end if;

  if char_length(cleaned_name) < 1 or char_length(cleaned_name) > 100 then
    raise exception 'Group name must contain between 1 and 100 characters';
  end if;

  insert into public.spaces (name, created_by)
  values (cleaned_name, current_user_id)
  returning * into created_space;

  insert into public.space_members (space_id, user_id, role)
  values (created_space.id, current_user_id, 'owner');

  return created_space;
end;
$$;

create or replace function app_private.invite_user_by_handle(
  target_space_id uuid,
  target_handle text
)
returns public.group_invites
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  handle_name text;
  handle_tag_text text;
  target_profile public.profiles;
  inviter_profile public.profiles;
  target_space public.spaces;
  created_invite public.group_invites;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not app_private.is_space_admin(target_space_id, current_user_id) then
    raise exception 'Only owners and admins can invite members';
  end if;

  handle_name := regexp_replace(trim(target_handle), '#[0-9]{4}$', '');
  handle_tag_text := substring(trim(target_handle) from '#([0-9]{4})$');
  if handle_name = trim(target_handle) or handle_tag_text is null then
    raise exception 'Use the Name#1234 format';
  end if;

  select * into target_profile
  from public.profiles
  where display_name_normalized = app_private.normalized_handle_name(handle_name)
    and discriminator = handle_tag_text::smallint;

  if not found then
    raise exception 'User not found';
  end if;

  if target_profile.id = current_user_id then
    raise exception 'You are already in this group';
  end if;

  if app_private.is_space_member(target_space_id, target_profile.id) then
    raise exception 'User is already in this group';
  end if;

  select * into inviter_profile from public.profiles where id = current_user_id;
  select * into target_space from public.spaces where id = target_space_id;

  insert into public.group_invites (
    space_id,
    invited_user_id,
    invited_by,
    space_name_snapshot,
    inviter_handle_snapshot,
    status,
    responded_at
  ) values (
    target_space_id,
    target_profile.id,
    current_user_id,
    target_space.name,
    app_private.profile_handle(inviter_profile),
    'pending',
    null
  )
  on conflict (space_id, invited_user_id)
  do update set
    invited_by = excluded.invited_by,
    space_name_snapshot = excluded.space_name_snapshot,
    inviter_handle_snapshot = excluded.inviter_handle_snapshot,
    status = 'pending',
    created_at = now(),
    responded_at = null
  returning * into created_invite;

  return created_invite;
end;
$$;

create or replace function app_private.respond_to_group_invite(
  target_invite_id uuid,
  accept_invite boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  invite public.group_invites;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  select * into invite
  from public.group_invites
  where id = target_invite_id
    and invited_user_id = current_user_id
    and status = 'pending'
  for update;

  if not found then
    raise exception 'Pending invitation not found';
  end if;

  if accept_invite then
    insert into public.space_members (space_id, user_id, role)
    values (invite.space_id, current_user_id, 'member')
    on conflict (space_id, user_id) do nothing;
  end if;

  update public.group_invites
  set
    status = case when accept_invite then 'accepted' else 'declined' end,
    responded_at = now()
  where id = target_invite_id;
end;
$$;

create or replace function app_private.copy_grocery_list_to_group(
  target_space_id uuid,
  source_local_id text,
  list_name text,
  items jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  created_list_id uuid;
  item jsonb;
begin
  if current_user_id is null
     or not app_private.is_space_member(target_space_id, current_user_id) then
    raise exception 'Group membership required';
  end if;

  if jsonb_typeof(items) <> 'array' then
    raise exception 'Items must be a JSON array';
  end if;

  insert into public.shared_grocery_lists (space_id, name, created_by, source_local_id)
  values (
    target_space_id,
    left(trim(list_name), 100),
    current_user_id,
    nullif(trim(source_local_id), '')
  )
  returning id into created_list_id;

  for item in select * from jsonb_array_elements(items)
  loop
    insert into public.shared_grocery_items (
      list_id,
      name,
      category,
      quantity,
      created_by
    ) values (
      created_list_id,
      left(trim(item->>'name'), 100),
      left(trim(item->>'category'), 100),
      greatest(coalesce((item->>'quantity')::integer, 1), 1),
      current_user_id
    );
  end loop;

  return created_list_id;
end;
$$;

create or replace function app_private.move_deposit_voucher_to_group(
  target_space_id uuid,
  voucher jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  created_voucher_id uuid;
  local_source_id text := nullif(trim(voucher->>'id'), '');
begin
  if current_user_id is null
     or not app_private.is_space_member(target_space_id, current_user_id) then
    raise exception 'Group membership required';
  end if;

  if local_source_id is null then
    raise exception 'Local voucher id is required';
  end if;

  insert into public.shared_deposit_vouchers (
    space_id,
    source_local_id,
    code,
    format,
    amount,
    store_name,
    scanned_at,
    valid_until,
    created_by
  ) values (
    target_space_id,
    local_source_id,
    left(trim(voucher->>'code'), 2048),
    coalesce(nullif(trim(voucher->>'format'), ''), 'unknown'),
    greatest(coalesce((voucher->>'amount')::numeric, 0), 0),
    left(trim(voucher->>'storeName'), 100),
    (voucher->>'scannedAt')::timestamptz,
    nullif(voucher->>'validUntil', '')::timestamptz,
    current_user_id
  )
  on conflict (space_id, source_local_id) where source_local_id is not null
  do update set updated_at = now()
  returning id into created_voucher_id;

  return created_voucher_id;
end;
$$;

create or replace function public.claim_handle(display_name text)
returns public.profiles
language sql
set search_path = ''
as $$
  select app_private.claim_handle(display_name);
$$;

create or replace function public.create_group(group_name text)
returns public.spaces
language sql
set search_path = ''
as $$
  select app_private.create_group(group_name);
$$;

create or replace function public.invite_user_by_handle(space_id uuid, handle text)
returns public.group_invites
language sql
set search_path = ''
as $$
  select app_private.invite_user_by_handle(space_id, handle);
$$;

create or replace function public.respond_to_group_invite(invite_id uuid, accept_invite boolean)
returns void
language sql
set search_path = ''
as $$
  select app_private.respond_to_group_invite(invite_id, accept_invite);
$$;

create or replace function public.copy_grocery_list_to_group(
  space_id uuid,
  source_local_id text,
  list_name text,
  items jsonb
)
returns uuid
language sql
set search_path = ''
as $$
  select app_private.copy_grocery_list_to_group(space_id, source_local_id, list_name, items);
$$;

create or replace function public.move_deposit_voucher_to_group(space_id uuid, voucher jsonb)
returns uuid
language sql
set search_path = ''
as $$
  select app_private.move_deposit_voucher_to_group(space_id, voucher);
$$;

alter table public.profiles enable row level security;
alter table public.spaces enable row level security;
alter table public.space_members enable row level security;
alter table public.group_invites enable row level security;
alter table public.shared_grocery_lists enable row level security;
alter table public.shared_grocery_items enable row level security;
alter table public.shared_deposit_vouchers enable row level security;

create policy "Users can read their own profile"
on public.profiles for select
to authenticated
using (id = auth.uid());

create policy "Members can read their spaces"
on public.spaces for select
to authenticated
using (app_private.is_space_member(id, auth.uid()));

create policy "Members can read memberships in their spaces"
on public.space_members for select
to authenticated
using (app_private.is_space_member(space_id, auth.uid()));

create policy "Invitees and admins can read invitations"
on public.group_invites for select
to authenticated
using (
  invited_user_id = auth.uid()
  or app_private.is_space_admin(space_id, auth.uid())
);

create policy "Members can read shared grocery lists"
on public.shared_grocery_lists for select
to authenticated
using (app_private.is_space_member(space_id, auth.uid()));

create policy "Members can create shared grocery lists"
on public.shared_grocery_lists for insert
to authenticated
with check (
  created_by = auth.uid()
  and app_private.is_space_member(space_id, auth.uid())
);

create policy "Members can update shared grocery lists"
on public.shared_grocery_lists for update
to authenticated
using (app_private.is_space_member(space_id, auth.uid()))
with check (app_private.is_space_member(space_id, auth.uid()));

create policy "Members can delete shared grocery lists"
on public.shared_grocery_lists for delete
to authenticated
using (app_private.is_space_member(space_id, auth.uid()));

create policy "Members can read shared grocery items"
on public.shared_grocery_items for select
to authenticated
using (
  exists (
    select 1
    from public.shared_grocery_lists lists
    where lists.id = list_id
      and app_private.is_space_member(lists.space_id, auth.uid())
  )
);

create policy "Members can create shared grocery items"
on public.shared_grocery_items for insert
to authenticated
with check (
  created_by = auth.uid()
  and exists (
    select 1
    from public.shared_grocery_lists lists
    where lists.id = list_id
      and app_private.is_space_member(lists.space_id, auth.uid())
  )
);

create policy "Members can update shared grocery items"
on public.shared_grocery_items for update
to authenticated
using (
  exists (
    select 1
    from public.shared_grocery_lists lists
    where lists.id = list_id
      and app_private.is_space_member(lists.space_id, auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.shared_grocery_lists lists
    where lists.id = list_id
      and app_private.is_space_member(lists.space_id, auth.uid())
  )
);

create policy "Members can delete shared grocery items"
on public.shared_grocery_items for delete
to authenticated
using (
  exists (
    select 1
    from public.shared_grocery_lists lists
    where lists.id = list_id
      and app_private.is_space_member(lists.space_id, auth.uid())
  )
);

create policy "Members can read shared deposit vouchers"
on public.shared_deposit_vouchers for select
to authenticated
using (app_private.is_space_member(space_id, auth.uid()));

create policy "Members can create shared deposit vouchers"
on public.shared_deposit_vouchers for insert
to authenticated
with check (
  created_by = auth.uid()
  and app_private.is_space_member(space_id, auth.uid())
);

create policy "Members can update shared deposit vouchers"
on public.shared_deposit_vouchers for update
to authenticated
using (app_private.is_space_member(space_id, auth.uid()))
with check (
  app_private.is_space_member(space_id, auth.uid())
  and (redeemed_by is null or redeemed_by = auth.uid())
);

create policy "Creators and admins can delete shared deposit vouchers"
on public.shared_deposit_vouchers for delete
to authenticated
using (
  created_by = auth.uid()
  or app_private.is_space_admin(space_id, auth.uid())
);

revoke all on schema app_private from public;
grant usage on schema app_private to authenticated;

revoke all on all functions in schema app_private from public;
grant execute on function app_private.claim_handle(text) to authenticated;
grant execute on function app_private.create_group(text) to authenticated;
grant execute on function app_private.invite_user_by_handle(uuid, text) to authenticated;
grant execute on function app_private.respond_to_group_invite(uuid, boolean) to authenticated;
grant execute on function app_private.copy_grocery_list_to_group(uuid, text, text, jsonb)
  to authenticated;
grant execute on function app_private.move_deposit_voucher_to_group(uuid, jsonb)
  to authenticated;
grant execute on function app_private.is_space_member(uuid, uuid) to authenticated;
grant execute on function app_private.is_space_admin(uuid, uuid) to authenticated;

revoke all on function public.claim_handle(text) from public;
revoke all on function public.create_group(text) from public;
revoke all on function public.invite_user_by_handle(uuid, text) from public;
revoke all on function public.respond_to_group_invite(uuid, boolean) from public;
revoke all on function public.copy_grocery_list_to_group(uuid, text, text, jsonb)
  from public;
revoke all on function public.move_deposit_voucher_to_group(uuid, jsonb) from public;
grant execute on function public.claim_handle(text) to authenticated;
grant execute on function public.create_group(text) to authenticated;
grant execute on function public.invite_user_by_handle(uuid, text) to authenticated;
grant execute on function public.respond_to_group_invite(uuid, boolean) to authenticated;
grant execute on function public.copy_grocery_list_to_group(uuid, text, text, jsonb)
  to authenticated;
grant execute on function public.move_deposit_voucher_to_group(uuid, jsonb)
  to authenticated;

grant select on public.profiles to authenticated;
grant select on public.spaces to authenticated;
grant select on public.space_members to authenticated;
grant select on public.group_invites to authenticated;
grant select, insert, update, delete on public.shared_grocery_lists to authenticated;
grant select, insert, update, delete on public.shared_grocery_items to authenticated;
grant select, insert, delete on public.shared_deposit_vouchers to authenticated;
grant update (redeemed_at, redeemed_by) on public.shared_deposit_vouchers to authenticated;
