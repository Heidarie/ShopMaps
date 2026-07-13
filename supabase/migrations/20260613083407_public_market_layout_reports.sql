create table public.shared_market_layout_reports (
  id uuid primary key default gen_random_uuid(),
  shared_market_layout_id uuid not null
    references public.shared_market_layouts(id) on delete cascade,
  reported_by uuid not null references auth.users(id) on delete cascade,
  reason text not null check (
    reason in ('incorrect', 'inappropriate', 'other')
  ),
  status text not null default 'open' check (
    status in ('open', 'resolved', 'dismissed')
  ),
  created_at timestamptz not null default now(),
  unique (shared_market_layout_id, reported_by)
);

create index shared_market_layout_reports_status_created_at_idx
on public.shared_market_layout_reports (status, created_at);

alter table public.shared_market_layout_reports enable row level security;

revoke all on public.shared_market_layout_reports from anon, authenticated;
grant select, update, delete on public.shared_market_layout_reports
  to service_role;

create or replace function app_private.report_public_market_layout(
  target_shared_layout_id uuid,
  report_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  map_owner_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if report_reason not in ('incorrect', 'inappropriate', 'other') then
    raise exception 'Invalid report reason';
  end if;

  select layouts.created_by
  into map_owner_id
  from public.shared_market_layouts layouts
  where layouts.id = target_shared_layout_id;

  if map_owner_id is null then
    raise exception 'Public map not found';
  end if;
  if map_owner_id = current_user_id then
    raise exception 'Users cannot report their own public map';
  end if;

  insert into public.shared_market_layout_reports (
    shared_market_layout_id,
    reported_by,
    reason
  )
  values (target_shared_layout_id, current_user_id, report_reason)
  on conflict (shared_market_layout_id, reported_by)
  do update set
    reason = excluded.reason,
    status = 'open',
    created_at = now();
end;
$$;

create or replace function public.report_public_market_layout(
  target_shared_layout_id uuid,
  report_reason text
)
returns void
language sql
set search_path = ''
as $$
  select app_private.report_public_market_layout(
    target_shared_layout_id,
    report_reason
  );
$$;

revoke all on function app_private.report_public_market_layout(uuid, text)
  from public, anon;
grant execute on function app_private.report_public_market_layout(uuid, text)
  to authenticated;

revoke all on function public.report_public_market_layout(uuid, text)
  from public, anon;
grant execute on function public.report_public_market_layout(uuid, text)
  to authenticated;
