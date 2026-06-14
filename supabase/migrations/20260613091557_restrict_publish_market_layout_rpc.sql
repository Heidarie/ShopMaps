revoke all on function public.publish_market_layout(jsonb, text, jsonb)
  from public, anon;
grant execute on function public.publish_market_layout(jsonb, text, jsonb)
  to authenticated;

revoke all on function app_private.publish_market_layout(jsonb, text, jsonb)
  from public, anon;
grant execute on function app_private.publish_market_layout(jsonb, text, jsonb)
  to authenticated;
