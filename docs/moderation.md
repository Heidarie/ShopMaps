# Moderacja treści online

ShopMaps blokuje zapis nowych lub zmienionych treści online zawierających
wyrażenia z prywatnego słownika. Filtr działa w bazie, więc obejmuje również
bezpośrednie żądania do Data API. Dane lokalne nie są filtrowane.

Chronione są nazwy użytkowników, grup, współdzielonych list, produktów,
kategorii, sklepów z udostępnionych kodów kaucji oraz publicznych map.
Filtrowane nie są kody kaucji, adresy Geoapify, identyfikatory ani inne pola
techniczne. Nazwy sklepów w nowych publicznych mapach i współdzielonych kodach
kaucji pochodzą wyłącznie z kanonicznego katalogu zasilanego przez Geoapify.

Odrzucona operacja kończy się błędem `CONTENT_NOT_ALLOWED`. Treść próby nie jest
zapisywana. W przypadku RPC udostępniającego całą listę wszystkie wykonane w
ramach wywołania zapisy są wycofywane.

## Słownik blokowanych wyrażeń

Słownik znajduje się w `app_private.content_filter_terms` i nie jest dostępny
dla klientów aplikacji. Aby dodać wyrażenie:

```sql
insert into app_private.content_filter_terms (term, category)
values ('<WYRAŻENIE>', 'profanity');
```

Dozwolone kategorie to `profanity`, `insult` oraz `slur`. Wyrażenie można
czasowo wyłączyć bez usuwania:

```sql
update app_private.content_filter_terms
set active = false
where term = '<WYRAŻENIE>';
```

Filtr ignoruje wielkość liter, polskie znaki, popularny leetspeak oraz
separatory między literami. Dopasowanie wymaga granic całego wyrażenia, dzięki
czemu zablokowane słowo nie powinno blokować poprawnego dłuższego słowa.

## Dokładne wyjątki

Allowlista dotyczy wyłącznie całej znormalizowanej wartości. Nie zezwala na
dłuższe teksty zawierające tę wartość:

```sql
insert into app_private.content_filter_allowlist (value, reason)
values ('<DOKŁADNA WARTOŚĆ>', '<POWÓD>');
```

Przed dodaniem wyjątku sprawdź, czy nie umożliwi on publikowania obraźliwej
treści w innym kontekście.

## Audyt istniejących danych

Migracja nie usuwa ani nie ukrywa istniejących danych. Uruchom prywatny raport
i ręcznie zweryfikuj trafienia:

```sql
select *
from app_private.content_filter_audit()
order by source_table, record_id, field_name;
```

Raport obejmuje również snapshoty nazw zapisane w zaproszeniach i publicznych
mapach. Nie obejmuje kodów kaucji ani adresów.

## Monitorowanie odrzuceń

W Supabase Dashboard otwórz Logs > Postgres Logs i filtruj komunikaty po
`CONTENT_NOT_ALLOWED`. Monitoruj liczbę błędów i nagłe wzrosty, ale nie zapisuj
odrzuconej treści ani dopasowanego słowa w osobnej tabeli.

## Testy filtra

Testy bazy znajdują się w `supabase/tests/database/online_content_filter.test.sql`.
Po uruchomieniu lokalnego Supabase wykonaj:

```bash
supabase test db
```

## Moderacja publicznych map sklepów

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

1. Regularnie przeglądaj audyt filtra i otwarte zgłoszenia.
2. Dodawaj wyjątki dopiero po potwierdzeniu fałszywego trafienia.
3. Zachowuj ostrożność przed usunięciem mapy.
4. Dokumentuj powód decyzji poza bazą, jeżeli wymaga tego obsługa prawna.
5. W przypadku nadużyć ogranicz konto użytkownika przez panel Supabase Auth.
