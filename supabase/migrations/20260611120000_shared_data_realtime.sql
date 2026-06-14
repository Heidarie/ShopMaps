do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shared_grocery_lists'
  ) then
    alter publication supabase_realtime add table public.shared_grocery_lists;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shared_grocery_items'
  ) then
    alter publication supabase_realtime add table public.shared_grocery_items;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shared_deposit_vouchers'
  ) then
    alter publication supabase_realtime add table public.shared_deposit_vouchers;
  end if;
end
$$;

drop policy if exists "Creators and admins can delete shared deposit vouchers"
on public.shared_deposit_vouchers;

create policy "Members can delete shared deposit vouchers"
on public.shared_deposit_vouchers for delete
to authenticated
using (app_private.is_space_member(space_id, (select auth.uid())));
