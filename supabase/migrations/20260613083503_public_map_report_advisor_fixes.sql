create index shared_market_layout_reports_reported_by_idx
on public.shared_market_layout_reports (reported_by);

create policy "Client API cannot read shared market layout reports"
on public.shared_market_layout_reports for select
to anon, authenticated
using (false);
