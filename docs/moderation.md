# Moderacja publicznych map sklepów

Użytkownicy mogą zgłaszać cudze publiczne mapy jako nieprawidłowe,
nieodpowiednie albo z innego powodu. Zgłoszenia są niewidoczne dla klientów
aplikacji i trafiają do `public.shared_market_layout_reports`.

## Przegląd otwartych zgłoszeń

Uruchom w Supabase SQL Editor:

```sql
select
  reports.id,
  reports.reason,
  reports.created_at,
  reports.shared_market_layout_id,
  locations.store_name,
  locations.formatted_address,
  layouts.creator_handle_snapshot
from public.shared_market_layout_reports reports
join public.shared_market_layouts layouts
  on layouts.id = reports.shared_market_layout_id
join public.store_locations locations
  on locations.id = layouts.store_location_id
where reports.status = 'open'
order by reports.created_at;
```

## Zamknięcie zgłoszenia bez usuwania mapy

```sql
update public.shared_market_layout_reports
set status = 'dismissed'
where id = '<REPORT_ID>';
```

## Usunięcie zgłoszonej mapy

Najpierw zweryfikuj mapę i identyfikator. Usunięcie jest nieodwracalne:

```sql
begin;

delete from public.shared_market_layouts
where id = '<SHARED_MARKET_LAYOUT_ID>';

commit;
```

Powiązane zgłoszenia zostaną usunięte przez `on delete cascade`. Kopie mapy
wcześniej pobrane lokalnie przez użytkowników pozostaną na ich urządzeniach.

## Zalecany proces

1. Sprawdzaj otwarte zgłoszenia regularnie.
2. Zachowuj ostrożność przed usunięciem mapy.
3. Dokumentuj powód decyzji poza bazą, jeżeli wymaga tego obsługa prawna.
4. W przypadku nadużyć ogranicz konto użytkownika przez panel Supabase Auth.
