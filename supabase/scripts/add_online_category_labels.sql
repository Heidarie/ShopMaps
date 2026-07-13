begin;

create table if not exists public.online_category_labels (
  category_id text not null
    check (
      category_id in (
        'drinks',
        'coffee_tea',
        'alcohol',
        'sweets',
        'snacks',
        'fruit',
        'vegetables',
        'dairy_eggs',
        'bakery',
        'meat',
        'fish_seafood',
        'frozen',
        'dry_goods',
        'canned_jars',
        'spices_condiments',
        'oils_sauces',
        'ready_meals',
        'household_cleaning',
        'paper_hygiene',
        'personal_care',
        'other'
      )
    ),
  language_code text not null
    check (language_code in ('en', 'pl', 'de', 'nl', 'es', 'fr', 'uk', 'it', 'pt')),
  sort_order integer not null check (sort_order > 0),
  name text not null check (nullif(trim(name), '') is not null),
  updated_at timestamptz not null default now(),
  primary key (category_id, language_code),
  unique (language_code, sort_order)
);

alter table public.online_category_labels enable row level security;

revoke all on table public.online_category_labels from public, anon, authenticated;
grant select on table public.online_category_labels to anon, authenticated;

drop policy if exists "Online category labels are readable"
  on public.online_category_labels;

create policy "Online category labels are readable"
on public.online_category_labels
for select
to anon, authenticated
using (true);

insert into public.online_category_labels (
  category_id,
  language_code,
  sort_order,
  name
)
values
  ('drinks', 'en', 1, 'Drinks'),
  ('drinks', 'pl', 1, 'Napoje'),
  ('drinks', 'de', 1, 'Getränke'),
  ('drinks', 'nl', 1, 'Dranken'),
  ('drinks', 'es', 1, 'Bebidas'),
  ('drinks', 'fr', 1, 'Boissons'),
  ('drinks', 'uk', 1, 'Напої'),
  ('drinks', 'it', 1, 'Bevande'),
  ('drinks', 'pt', 1, 'Bebidas'),

  ('coffee_tea', 'en', 2, 'Coffee & tea'),
  ('coffee_tea', 'pl', 2, 'Kawa i herbata'),
  ('coffee_tea', 'de', 2, 'Kaffee und Tee'),
  ('coffee_tea', 'nl', 2, 'Koffie en thee'),
  ('coffee_tea', 'es', 2, 'Café y té'),
  ('coffee_tea', 'fr', 2, 'Café et thé'),
  ('coffee_tea', 'uk', 2, 'Кава і чай'),
  ('coffee_tea', 'it', 2, 'Caffè e tè'),
  ('coffee_tea', 'pt', 2, 'Café e chá'),

  ('alcohol', 'en', 3, 'Alcohol'),
  ('alcohol', 'pl', 3, 'Alkohol'),
  ('alcohol', 'de', 3, 'Alkohol'),
  ('alcohol', 'nl', 3, 'Alcohol'),
  ('alcohol', 'es', 3, 'Alcohol'),
  ('alcohol', 'fr', 3, 'Alcool'),
  ('alcohol', 'uk', 3, 'Алкоголь'),
  ('alcohol', 'it', 3, 'Alcol'),
  ('alcohol', 'pt', 3, 'Álcool'),

  ('sweets', 'en', 4, 'Sweets'),
  ('sweets', 'pl', 4, 'Słodycze'),
  ('sweets', 'de', 4, 'Süßigkeiten'),
  ('sweets', 'nl', 4, 'Snoep'),
  ('sweets', 'es', 4, 'Dulces'),
  ('sweets', 'fr', 4, 'Confiseries'),
  ('sweets', 'uk', 4, 'Солодощі'),
  ('sweets', 'it', 4, 'Dolci'),
  ('sweets', 'pt', 4, 'Doces'),

  ('snacks', 'en', 5, 'Snacks'),
  ('snacks', 'pl', 5, 'Przekąski'),
  ('snacks', 'de', 5, 'Snacks'),
  ('snacks', 'nl', 5, 'Snacks'),
  ('snacks', 'es', 5, 'Aperitivos'),
  ('snacks', 'fr', 5, 'Snacks'),
  ('snacks', 'uk', 5, 'Снеки'),
  ('snacks', 'it', 5, 'Snack'),
  ('snacks', 'pt', 5, 'Snacks'),

  ('fruit', 'en', 6, 'Fruit'),
  ('fruit', 'pl', 6, 'Owoce'),
  ('fruit', 'de', 6, 'Obst'),
  ('fruit', 'nl', 6, 'Fruit'),
  ('fruit', 'es', 6, 'Fruta'),
  ('fruit', 'fr', 6, 'Fruits'),
  ('fruit', 'uk', 6, 'Фрукти'),
  ('fruit', 'it', 6, 'Frutta'),
  ('fruit', 'pt', 6, 'Fruta'),

  ('vegetables', 'en', 7, 'Vegetables'),
  ('vegetables', 'pl', 7, 'Warzywa'),
  ('vegetables', 'de', 7, 'Gemüse'),
  ('vegetables', 'nl', 7, 'Groenten'),
  ('vegetables', 'es', 7, 'Verduras'),
  ('vegetables', 'fr', 7, 'Légumes'),
  ('vegetables', 'uk', 7, 'Овочі'),
  ('vegetables', 'it', 7, 'Verdure'),
  ('vegetables', 'pt', 7, 'Legumes'),

  ('dairy_eggs', 'en', 8, 'Dairy & eggs'),
  ('dairy_eggs', 'pl', 8, 'Nabiał i jajka'),
  ('dairy_eggs', 'de', 8, 'Milchprodukte und Eier'),
  ('dairy_eggs', 'nl', 8, 'Zuivel en eieren'),
  ('dairy_eggs', 'es', 8, 'Lácteos y huevos'),
  ('dairy_eggs', 'fr', 8, 'Produits laitiers et œufs'),
  ('dairy_eggs', 'uk', 8, 'Молочні продукти та яйця'),
  ('dairy_eggs', 'it', 8, 'Latticini e uova'),
  ('dairy_eggs', 'pt', 8, 'Laticínios e ovos'),

  ('bakery', 'en', 9, 'Bakery'),
  ('bakery', 'pl', 9, 'Piekarnia'),
  ('bakery', 'de', 9, 'Bäckerei'),
  ('bakery', 'nl', 9, 'Bakkerij'),
  ('bakery', 'es', 9, 'Panadería'),
  ('bakery', 'fr', 9, 'Boulangerie'),
  ('bakery', 'uk', 9, 'Випічка'),
  ('bakery', 'it', 9, 'Panetteria'),
  ('bakery', 'pt', 9, 'Padaria'),

  ('meat', 'en', 10, 'Meat'),
  ('meat', 'pl', 10, 'Mięso'),
  ('meat', 'de', 10, 'Fleisch'),
  ('meat', 'nl', 10, 'Vlees'),
  ('meat', 'es', 10, 'Carne'),
  ('meat', 'fr', 10, 'Viande'),
  ('meat', 'uk', 10, 'Мʼясо'),
  ('meat', 'it', 10, 'Carne'),
  ('meat', 'pt', 10, 'Carne'),

  ('fish_seafood', 'en', 11, 'Fish & seafood'),
  ('fish_seafood', 'pl', 11, 'Ryby i owoce morza'),
  ('fish_seafood', 'de', 11, 'Fisch und Meeresfrüchte'),
  ('fish_seafood', 'nl', 11, 'Vis en zeevruchten'),
  ('fish_seafood', 'es', 11, 'Pescado y marisco'),
  ('fish_seafood', 'fr', 11, 'Poisson et fruits de mer'),
  ('fish_seafood', 'uk', 11, 'Риба та морепродукти'),
  ('fish_seafood', 'it', 11, 'Pesce e frutti di mare'),
  ('fish_seafood', 'pt', 11, 'Peixe e marisco'),

  ('frozen', 'en', 12, 'Frozen'),
  ('frozen', 'pl', 12, 'Mrożonki'),
  ('frozen', 'de', 12, 'Tiefkühlkost'),
  ('frozen', 'nl', 12, 'Diepvries'),
  ('frozen', 'es', 12, 'Congelados'),
  ('frozen', 'fr', 12, 'Surgelés'),
  ('frozen', 'uk', 12, 'Заморожені продукти'),
  ('frozen', 'it', 12, 'Surgelati'),
  ('frozen', 'pt', 12, 'Congelados'),

  ('dry_goods', 'en', 13, 'Pasta, rice & flour'),
  ('dry_goods', 'pl', 13, 'Makaron, ryż i mąka'),
  ('dry_goods', 'de', 13, 'Nudeln, Reis und Mehl'),
  ('dry_goods', 'nl', 13, 'Pasta, rijst en bloem'),
  ('dry_goods', 'es', 13, 'Pasta, arroz y harina'),
  ('dry_goods', 'fr', 13, 'Pâtes, riz et farine'),
  ('dry_goods', 'uk', 13, 'Макарони, рис і борошно'),
  ('dry_goods', 'it', 13, 'Pasta, riso e farina'),
  ('dry_goods', 'pt', 13, 'Massa, arroz e farinha'),

  ('canned_jars', 'en', 14, 'Cans & jars'),
  ('canned_jars', 'pl', 14, 'Konserwy i słoiki'),
  ('canned_jars', 'de', 14, 'Konserven und Gläser'),
  ('canned_jars', 'nl', 14, 'Blikken en potten'),
  ('canned_jars', 'es', 14, 'Conservas y tarros'),
  ('canned_jars', 'fr', 14, 'Conserves et bocaux'),
  ('canned_jars', 'uk', 14, 'Консерви та банки'),
  ('canned_jars', 'it', 14, 'Scatolette e barattoli'),
  ('canned_jars', 'pt', 14, 'Conservas e frascos'),

  ('spices_condiments', 'en', 15, 'Spices & condiments'),
  ('spices_condiments', 'pl', 15, 'Przyprawy'),
  ('spices_condiments', 'de', 15, 'Gewürze'),
  ('spices_condiments', 'nl', 15, 'Kruiden en specerijen'),
  ('spices_condiments', 'es', 15, 'Especias y condimentos'),
  ('spices_condiments', 'fr', 15, 'Épices et condiments'),
  ('spices_condiments', 'uk', 15, 'Спеції та приправи'),
  ('spices_condiments', 'it', 15, 'Spezie e condimenti'),
  ('spices_condiments', 'pt', 15, 'Especiarias e condimentos'),

  ('oils_sauces', 'en', 16, 'Oils & sauces'),
  ('oils_sauces', 'pl', 16, 'Oleje i sosy'),
  ('oils_sauces', 'de', 16, 'Öle und Soßen'),
  ('oils_sauces', 'nl', 16, 'Oliën en sauzen'),
  ('oils_sauces', 'es', 16, 'Aceites y salsas'),
  ('oils_sauces', 'fr', 16, 'Huiles et sauces'),
  ('oils_sauces', 'uk', 16, 'Олії та соуси'),
  ('oils_sauces', 'it', 16, 'Oli e salse'),
  ('oils_sauces', 'pt', 16, 'Óleos e molhos'),

  ('ready_meals', 'en', 17, 'Ready meals'),
  ('ready_meals', 'pl', 17, 'Dania gotowe'),
  ('ready_meals', 'de', 17, 'Fertiggerichte'),
  ('ready_meals', 'nl', 17, 'Kant-en-klaarmaaltijden'),
  ('ready_meals', 'es', 17, 'Platos preparados'),
  ('ready_meals', 'fr', 17, 'Plats préparés'),
  ('ready_meals', 'uk', 17, 'Готові страви'),
  ('ready_meals', 'it', 17, 'Piatti pronti'),
  ('ready_meals', 'pt', 17, 'Refeições prontas'),

  ('household_cleaning', 'en', 18, 'Household cleaning'),
  ('household_cleaning', 'pl', 18, 'Chemia domowa'),
  ('household_cleaning', 'de', 18, 'Haushaltsreinigung'),
  ('household_cleaning', 'nl', 18, 'Huishoudelijke schoonmaak'),
  ('household_cleaning', 'es', 18, 'Limpieza del hogar'),
  ('household_cleaning', 'fr', 18, 'Entretien de la maison'),
  ('household_cleaning', 'uk', 18, 'Побутова хімія'),
  ('household_cleaning', 'it', 18, 'Pulizia della casa'),
  ('household_cleaning', 'pt', 18, 'Limpeza doméstica'),

  ('paper_hygiene', 'en', 19, 'Paper & hygiene'),
  ('paper_hygiene', 'pl', 19, 'Papier i higiena'),
  ('paper_hygiene', 'de', 19, 'Papier und Hygiene'),
  ('paper_hygiene', 'nl', 19, 'Papier en hygiëne'),
  ('paper_hygiene', 'es', 19, 'Papel e higiene'),
  ('paper_hygiene', 'fr', 19, 'Papier et hygiène'),
  ('paper_hygiene', 'uk', 19, 'Папір та гігієна'),
  ('paper_hygiene', 'it', 19, 'Carta e igiene'),
  ('paper_hygiene', 'pt', 19, 'Papel e higiene'),

  ('personal_care', 'en', 20, 'Personal care'),
  ('personal_care', 'pl', 20, 'Higiena osobista'),
  ('personal_care', 'de', 20, 'Körperpflege'),
  ('personal_care', 'nl', 20, 'Persoonlijke verzorging'),
  ('personal_care', 'es', 20, 'Cuidado personal'),
  ('personal_care', 'fr', 20, 'Soins personnels'),
  ('personal_care', 'uk', 20, 'Особиста гігієна'),
  ('personal_care', 'it', 20, 'Cura personale'),
  ('personal_care', 'pt', 20, 'Cuidados pessoais'),

  ('other', 'en', 21, 'Other'),
  ('other', 'pl', 21, 'Inne'),
  ('other', 'de', 21, 'Andere'),
  ('other', 'nl', 21, 'Overig'),
  ('other', 'es', 21, 'Otros'),
  ('other', 'fr', 21, 'Autre'),
  ('other', 'uk', 21, 'Інше'),
  ('other', 'it', 21, 'Altro'),
  ('other', 'pt', 21, 'Outros')
on conflict (category_id, language_code)
do update set
  sort_order = excluded.sort_order,
  name = excluded.name,
  updated_at = now();

create or replace function public.get_online_category_labels(
  target_language_code text default 'en'
)
returns table (
  category_id text,
  language_code text,
  sort_order integer,
  name text
)
language sql
stable
security invoker
set search_path = ''
as $$
  with requested_language as (
    select case
      when lower(trim(coalesce(target_language_code, ''))) in
        ('en', 'pl', 'de', 'nl', 'es', 'fr', 'uk', 'it', 'pt')
      then lower(trim(target_language_code))
      else 'en'
    end as code
  ),
  categories as (
    select distinct category_id, sort_order
    from public.online_category_labels
  )
  select
    categories.category_id,
    coalesce(requested.language_code, fallback.language_code, 'en')
      as language_code,
    categories.sort_order,
    coalesce(requested.name, fallback.name, categories.category_id) as name
  from categories
  cross join requested_language
  left join public.online_category_labels requested
    on requested.category_id = categories.category_id
    and requested.language_code = requested_language.code
  left join public.online_category_labels fallback
    on fallback.category_id = categories.category_id
    and fallback.language_code = 'en'
  order by categories.sort_order, categories.category_id;
$$;

revoke all on function public.get_online_category_labels(text)
  from public, anon, authenticated;
grant execute on function public.get_online_category_labels(text)
  to anon, authenticated;

notify pgrst, 'reload schema';

commit;
