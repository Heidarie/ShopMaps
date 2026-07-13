create index shared_list_notification_state_user_id_idx
  on app_private.shared_list_notification_state(user_id);

create policy "Clients cannot access push devices directly"
on public.push_devices for all
to anon, authenticated
using (false)
with check (false);
