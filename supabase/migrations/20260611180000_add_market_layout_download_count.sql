alter table public.shared_market_layouts
add column download_count bigint not null default 0
check (download_count >= 0);

create index shared_market_layouts_download_count_idx
  on public.shared_market_layouts(download_count desc);

create function app_private.record_market_layout_download(
  target_shared_layout_id uuid
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  updated_download_count bigint;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  update public.shared_market_layouts
  set download_count = download_count + 1
  where id = target_shared_layout_id
  returning download_count into updated_download_count;

  if not found then
    raise exception 'Shared store map not found';
  end if;

  return updated_download_count;
end;
$$;

create function public.record_market_layout_download(
  target_shared_layout_id uuid
)
returns bigint
language sql
set search_path = ''
as $$
  select app_private.record_market_layout_download(target_shared_layout_id);
$$;

revoke all on function app_private.record_market_layout_download(uuid) from public;
grant execute on function app_private.record_market_layout_download(uuid)
  to authenticated;

revoke all on function public.record_market_layout_download(uuid) from public;
grant execute on function public.record_market_layout_download(uuid)
  to authenticated;
