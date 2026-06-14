create index group_invites_invited_by_idx on public.group_invites(invited_by);
create index shared_deposit_vouchers_created_by_idx
  on public.shared_deposit_vouchers(created_by);
create index shared_deposit_vouchers_redeemed_by_idx
  on public.shared_deposit_vouchers(redeemed_by);
create index shared_grocery_items_created_by_idx
  on public.shared_grocery_items(created_by);
create index shared_grocery_lists_created_by_idx
  on public.shared_grocery_lists(created_by);
create index spaces_created_by_idx on public.spaces(created_by);

alter policy "Users can read their own profile"
on public.profiles
using (id = (select auth.uid()));

alter policy "Members can read their spaces"
on public.spaces
using (app_private.is_space_member(id, (select auth.uid())));

alter policy "Members can read memberships in their spaces"
on public.space_members
using (app_private.is_space_member(space_id, (select auth.uid())));

alter policy "Invitees and admins can read invitations"
on public.group_invites
using (
  invited_user_id = (select auth.uid())
  or app_private.is_space_admin(space_id, (select auth.uid()))
);

alter policy "Members can read shared grocery lists"
on public.shared_grocery_lists
using (app_private.is_space_member(space_id, (select auth.uid())));

alter policy "Members can create shared grocery lists"
on public.shared_grocery_lists
with check (
  created_by = (select auth.uid())
  and app_private.is_space_member(space_id, (select auth.uid()))
);

alter policy "Members can update shared grocery lists"
on public.shared_grocery_lists
using (app_private.is_space_member(space_id, (select auth.uid())))
with check (app_private.is_space_member(space_id, (select auth.uid())));

alter policy "Members can delete shared grocery lists"
on public.shared_grocery_lists
using (app_private.is_space_member(space_id, (select auth.uid())));

alter policy "Members can read shared grocery items"
on public.shared_grocery_items
using (
  exists (
    select 1
    from public.shared_grocery_lists lists
    where lists.id = list_id
      and app_private.is_space_member(lists.space_id, (select auth.uid()))
  )
);

alter policy "Members can create shared grocery items"
on public.shared_grocery_items
with check (
  created_by = (select auth.uid())
  and exists (
    select 1
    from public.shared_grocery_lists lists
    where lists.id = list_id
      and app_private.is_space_member(lists.space_id, (select auth.uid()))
  )
);

alter policy "Members can update shared grocery items"
on public.shared_grocery_items
using (
  exists (
    select 1
    from public.shared_grocery_lists lists
    where lists.id = list_id
      and app_private.is_space_member(lists.space_id, (select auth.uid()))
  )
)
with check (
  exists (
    select 1
    from public.shared_grocery_lists lists
    where lists.id = list_id
      and app_private.is_space_member(lists.space_id, (select auth.uid()))
  )
);

alter policy "Members can delete shared grocery items"
on public.shared_grocery_items
using (
  exists (
    select 1
    from public.shared_grocery_lists lists
    where lists.id = list_id
      and app_private.is_space_member(lists.space_id, (select auth.uid()))
  )
);

alter policy "Members can read shared deposit vouchers"
on public.shared_deposit_vouchers
using (app_private.is_space_member(space_id, (select auth.uid())));

alter policy "Members can create shared deposit vouchers"
on public.shared_deposit_vouchers
with check (
  created_by = (select auth.uid())
  and app_private.is_space_member(space_id, (select auth.uid()))
);

alter policy "Members can update shared deposit vouchers"
on public.shared_deposit_vouchers
using (app_private.is_space_member(space_id, (select auth.uid())))
with check (
  app_private.is_space_member(space_id, (select auth.uid()))
  and (redeemed_by is null or redeemed_by = (select auth.uid()))
);

alter policy "Creators and admins can delete shared deposit vouchers"
on public.shared_deposit_vouchers
using (
  created_by = (select auth.uid())
  or app_private.is_space_admin(space_id, (select auth.uid()))
);
