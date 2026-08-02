-- Store the localized online category catalog in the database so authenticated
-- clients can receive new categories without requiring another app release.
create table if not exists public.online_categories (
  category_id text primary key
    check (category_id ~ '^[a-z][a-z0-9_]*$'),
  sort_order integer not null unique check (sort_order > 0),
  active boolean not null default true,
  aliases text[] not null default '{}'::text[]
    check (array_position(aliases, null) is null),
  updated_at timestamptz not null default now()
);

alter table public.online_categories enable row level security;

revoke all on table public.online_categories
  from public, anon, authenticated;
grant select on table public.online_categories to authenticated;

drop policy if exists "Authenticated users can read online categories"
  on public.online_categories;

create policy "Authenticated users can read online categories"
on public.online_categories
for select
to authenticated
using (true);

insert into public.online_categories (
  category_id,
  sort_order,
  active,
  aliases
)
values
  (
    'drinks',
    1,
    true,
    array['drink', 'napoj', 'wasser', 'water', 'sok', 'juice']
  ),
  (
    'coffee_tea',
    2,
    true,
    array['coffee and tea', 'kawa herbata']
  ),
  (
    'alcohol',
    3,
    true,
    array['beer', 'wine', 'piwo', 'wino', 'spirits']
  ),
  (
    'sweets',
    4,
    true,
    array['sweet', 'candy', 'chocolate', 'slodycze', 'czekolada']
  ),
  (
    'snacks',
    5,
    true,
    array['snack', 'przekaski', 'chips', 'crisps']
  ),
  (
    'fruit',
    6,
    true,
    array['fruits', 'owoce', 'apples', 'jablka']
  ),
  (
    'vegetables',
    7,
    true,
    array['vegetable', 'veggies', 'warzywa', 'gemuse']
  ),
  (
    'dairy_eggs',
    8,
    true,
    array['dairy', 'eggs', 'nabial', 'jajka', 'milk', 'mleko']
  ),
  (
    'bakery',
    9,
    true,
    array['bread', 'pieczywo', 'chleb', 'baked goods']
  ),
  ('meat', 10, true, array['mieso', 'butcher']),
  (
    'fish_seafood',
    11,
    true,
    array['fish', 'seafood', 'ryby', 'owoce morza']
  ),
  (
    'frozen',
    12,
    true,
    array['frozen food', 'mrozonki', 'freezer']
  ),
  ('dry_goods', 13, true, array['flour', 'maka']),
  (
    'canned_jars',
    14,
    true,
    array['cans', 'jars', 'konserwy', 'sloiki', 'preserves']
  ),
  (
    'spices_condiments',
    15,
    true,
    array['spices', 'condiments', 'przyprawy', 'herbs']
  ),
  ('oils_sauces', 16, true, array['oil', 'oleje', 'olive oil']),
  (
    'ready_meals',
    17,
    true,
    array['ready meal', 'dania gotowe', 'meal kits']
  ),
  (
    'household_cleaning',
    18,
    true,
    array['household', 'cleaning', 'chemia', 'detergents']
  ),
  (
    'paper_hygiene',
    19,
    true,
    array['paper', 'hygiene', 'papier', 'toilet paper']
  ),
  (
    'personal_care',
    20,
    true,
    array['cosmetics', 'kosmetyki', 'body care', 'higiena osobista']
  ),
  (
    'nuts_seeds',
    21,
    true,
    array['nuts', 'seeds', 'orzechy', 'pestki']
  ),
  (
    'vegetarian_vegan',
    22,
    true,
    array['vegetarian', 'vegan', 'plant based', 'wegetarianskie']
  ),
  (
    'cheese',
    23,
    true,
    array['cheeses', 'ser', 'queso', 'fromage']
  ),
  (
    'ham',
    24,
    true,
    array['hams', 'szynka', 'prosciutto', 'jamon']
  ),
  (
    'world_cuisines',
    25,
    true,
    array['international food', 'international cuisine', 'world food']
  ),
  (
    'organic',
    26,
    true,
    array['eco', 'ecological', 'ekologiczne', 'organic food']
  ),
  ('pasta', 27, true, array['makaron', 'noodles']),
  ('rice', 28, true, array['ryz']),
  ('sauces', 29, true, array['sauce', 'sos']),
  ('coffee', 30, true, array['kawa', 'cafe']),
  ('tea', 31, true, array['herbata']),
  (
    'other',
    32,
    true,
    array['misc', 'miscellaneous', 'inne', 'other category']
  )
on conflict (category_id)
do update set
  sort_order = excluded.sort_order,
  active = excluded.active,
  aliases = excluded.aliases,
  updated_at = now();

create table if not exists public.online_category_labels (
  category_id text not null
    references public.online_categories(category_id)
    on update cascade
    on delete restrict,
  language_code text not null
    check (language_code in ('en', 'pl', 'de', 'nl', 'es', 'fr', 'uk', 'it', 'pt')),
  sort_order integer not null check (sort_order > 0),
  name text not null check (nullif(trim(name), '') is not null),
  updated_at timestamptz not null default now(),
  primary key (category_id, language_code),
  unique (language_code, sort_order)
);

alter table public.online_category_labels
drop constraint if exists online_category_labels_category_id_check;

alter table public.online_category_labels
add constraint online_category_labels_category_id_check
check (category_id ~ '^[a-z][a-z0-9_]*$');

alter table public.online_category_labels enable row level security;

revoke all on table public.online_category_labels from public, anon, authenticated;
grant select on table public.online_category_labels to authenticated;

drop policy if exists "Authenticated users can read online category labels"
  on public.online_category_labels;

drop policy if exists "Online category labels are readable"
  on public.online_category_labels;

create policy "Authenticated users can read online category labels"
on public.online_category_labels
for select
to authenticated
using (true);

update public.online_category_labels
set sort_order = 1000
where category_id = 'other';

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

  ('nuts_seeds', 'en', 21, 'Nuts & seeds'),
  ('nuts_seeds', 'pl', 21, 'Orzechy i pestki'),
  ('nuts_seeds', 'de', 21, 'Nüsse und Samen'),
  ('nuts_seeds', 'nl', 21, 'Noten en zaden'),
  ('nuts_seeds', 'es', 21, 'Frutos secos y semillas'),
  ('nuts_seeds', 'fr', 21, 'Noix et graines'),
  ('nuts_seeds', 'uk', 21, 'Горіхи та насіння'),
  ('nuts_seeds', 'it', 21, 'Frutta secca e semi'),
  ('nuts_seeds', 'pt', 21, 'Frutos secos e sementes'),

  ('vegetarian_vegan', 'en', 22, 'Vegetarian & vegan'),
  ('vegetarian_vegan', 'pl', 22, 'Wege'),
  ('vegetarian_vegan', 'de', 22, 'Vegetarisch & vegan'),
  ('vegetarian_vegan', 'nl', 22, 'Vegetarisch en veganistisch'),
  ('vegetarian_vegan', 'es', 22, 'Vegetariano y vegano'),
  ('vegetarian_vegan', 'fr', 22, 'Végétarien et végan'),
  ('vegetarian_vegan', 'uk', 22, 'Вегетаріанські та веганські продукти'),
  ('vegetarian_vegan', 'it', 22, 'Vegetariano e vegano'),
  ('vegetarian_vegan', 'pt', 22, 'Vegetariano e vegano'),

  ('cheese', 'en', 23, 'Cheese'),
  ('cheese', 'pl', 23, 'Sery'),
  ('cheese', 'de', 23, 'Käse'),
  ('cheese', 'nl', 23, 'Kaas'),
  ('cheese', 'es', 23, 'Quesos'),
  ('cheese', 'fr', 23, 'Fromages'),
  ('cheese', 'uk', 23, 'Сири'),
  ('cheese', 'it', 23, 'Formaggi'),
  ('cheese', 'pt', 23, 'Queijos'),

  ('ham', 'en', 24, 'Ham'),
  ('ham', 'pl', 24, 'Szynki'),
  ('ham', 'de', 24, 'Schinken'),
  ('ham', 'nl', 24, 'Ham'),
  ('ham', 'es', 24, 'Jamones'),
  ('ham', 'fr', 24, 'Jambons'),
  ('ham', 'uk', 24, 'Шинки'),
  ('ham', 'it', 24, 'Prosciutti'),
  ('ham', 'pt', 24, 'Presuntos'),

  ('world_cuisines', 'en', 25, 'World cuisines'),
  ('world_cuisines', 'pl', 25, 'Kuchnie świata'),
  ('world_cuisines', 'de', 25, 'Internationale Küche'),
  ('world_cuisines', 'nl', 25, 'Wereldkeuken'),
  ('world_cuisines', 'es', 25, 'Cocinas del mundo'),
  ('world_cuisines', 'fr', 25, 'Cuisines du monde'),
  ('world_cuisines', 'uk', 25, 'Кухні світу'),
  ('world_cuisines', 'it', 25, 'Cucine dal mondo'),
  ('world_cuisines', 'pt', 25, 'Cozinhas do mundo'),

  ('organic', 'en', 26, 'Organic'),
  ('organic', 'pl', 26, 'Bio'),
  ('organic', 'de', 26, 'Bio'),
  ('organic', 'nl', 26, 'Biologisch'),
  ('organic', 'es', 26, 'Ecológico'),
  ('organic', 'fr', 26, 'Bio'),
  ('organic', 'uk', 26, 'Органічні продукти'),
  ('organic', 'it', 26, 'Biologico'),
  ('organic', 'pt', 26, 'Biológico'),

  ('pasta', 'en', 27, 'Pasta'),
  ('pasta', 'pl', 27, 'Makarony'),
  ('pasta', 'de', 27, 'Nudeln'),
  ('pasta', 'nl', 27, 'Pasta'),
  ('pasta', 'es', 27, 'Pastas'),
  ('pasta', 'fr', 27, 'Pâtes'),
  ('pasta', 'uk', 27, 'Макаронні вироби'),
  ('pasta', 'it', 27, 'Pasta'),
  ('pasta', 'pt', 27, 'Massas'),

  ('rice', 'en', 28, 'Rice'),
  ('rice', 'pl', 28, 'Ryże'),
  ('rice', 'de', 28, 'Reis'),
  ('rice', 'nl', 28, 'Rijst'),
  ('rice', 'es', 28, 'Arroces'),
  ('rice', 'fr', 28, 'Riz'),
  ('rice', 'uk', 28, 'Рис'),
  ('rice', 'it', 28, 'Riso'),
  ('rice', 'pt', 28, 'Arroz'),

  ('sauces', 'en', 29, 'Sauces'),
  ('sauces', 'pl', 29, 'Sosy'),
  ('sauces', 'de', 29, 'Soßen'),
  ('sauces', 'nl', 29, 'Sauzen'),
  ('sauces', 'es', 29, 'Salsas'),
  ('sauces', 'fr', 29, 'Sauces'),
  ('sauces', 'uk', 29, 'Соуси'),
  ('sauces', 'it', 29, 'Salse'),
  ('sauces', 'pt', 29, 'Molhos'),

  ('coffee', 'en', 30, 'Coffee'),
  ('coffee', 'pl', 30, 'Kawy'),
  ('coffee', 'de', 30, 'Kaffee'),
  ('coffee', 'nl', 30, 'Koffie'),
  ('coffee', 'es', 30, 'Cafés'),
  ('coffee', 'fr', 30, 'Cafés'),
  ('coffee', 'uk', 30, 'Кава'),
  ('coffee', 'it', 30, 'Caffè'),
  ('coffee', 'pt', 30, 'Cafés'),

  ('tea', 'en', 31, 'Tea'),
  ('tea', 'pl', 31, 'Herbaty'),
  ('tea', 'de', 31, 'Tee'),
  ('tea', 'nl', 31, 'Thee'),
  ('tea', 'es', 31, 'Tés'),
  ('tea', 'fr', 31, 'Thés'),
  ('tea', 'uk', 31, 'Чай'),
  ('tea', 'it', 31, 'Tè'),
  ('tea', 'pt', 31, 'Chás'),

  ('other', 'en', 32, 'Other'),
  ('other', 'pl', 32, 'Inne'),
  ('other', 'de', 32, 'Andere'),
  ('other', 'nl', 32, 'Overig'),
  ('other', 'es', 32, 'Otros'),
  ('other', 'fr', 32, 'Autre'),
  ('other', 'uk', 32, 'Інше'),
  ('other', 'it', 32, 'Altro'),
  ('other', 'pt', 32, 'Outros')
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
    select category_id, sort_order
    from public.online_categories
    where active
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
  to authenticated;

create or replace function public.get_online_category_catalog()
returns table (
  category_id text,
  sort_order integer,
  active boolean,
  labels jsonb,
  aliases text[]
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    categories.category_id,
    categories.sort_order,
    categories.active,
    jsonb_object_agg(
      labels.language_code,
      labels.name
      order by labels.language_code
    ) as labels,
    categories.aliases
  from public.online_categories categories
  join public.online_category_labels labels
    on labels.category_id = categories.category_id
  group by
    categories.category_id,
    categories.sort_order,
    categories.active,
    categories.aliases
  having bool_or(labels.language_code = 'en')
  order by categories.sort_order, categories.category_id;
$$;

revoke all on function public.get_online_category_catalog()
  from public, anon, authenticated;
grant execute on function public.get_online_category_catalog()
  to authenticated;

create or replace function app_private.online_category_ids()
returns text[]
language sql
stable
set search_path = ''
as $$
  select coalesce(
    array_agg(categories.category_id order by categories.sort_order),
    '{}'::text[]
  )
  from public.online_categories categories;
$$;

create or replace function app_private.is_online_category_id(value text)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.online_categories categories
    where categories.category_id = lower(trim(coalesce(value, '')))
  );
$$;

create or replace function app_private.online_category_id_for_value(value text)
returns text
language plpgsql
stable
set search_path = ''
as $$
declare
  cleaned text := lower(trim(coalesce(value, '')));
  key text := app_private.online_category_key(value);
  matched_category_id text;
begin
  if app_private.is_online_category_id(cleaned) then
    return cleaned;
  end if;

  select categories.category_id
  into matched_category_id
  from public.online_categories categories
  where exists (
    select 1
    from public.online_category_labels labels
    where labels.category_id = categories.category_id
      and app_private.online_category_key(labels.name) = key
  )
  or exists (
    select 1
    from unnest(categories.aliases) aliases(alias)
    where app_private.online_category_key(aliases.alias) = key
  )
  order by categories.active desc, categories.sort_order
  limit 1;

  return coalesce(matched_category_id, 'other');
end;
$$;

create or replace function app_private.is_online_category_order(value jsonb)
returns boolean
language plpgsql
stable
set search_path = ''
as $$
begin
  if jsonb_typeof(value) <> 'array' then
    return false;
  end if;

  return not exists (
    select 1
    from jsonb_array_elements_text(value) categories(category_id)
    where not app_private.is_online_category_id(categories.category_id)
  );
end;
$$;

create or replace function app_private.normalize_legacy_online_category_order(
  value jsonb
)
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  normalized jsonb;
begin
  if jsonb_typeof(value) <> 'array' then
    return '[]'::jsonb;
  end if;

  select coalesce(jsonb_agg(category_id order by first_index), '[]'::jsonb)
  into normalized
  from (
    select
      app_private.online_category_id_for_value(categories.category)
        as category_id,
      min(categories.ordinality) as first_index
    from jsonb_array_elements_text(value)
      with ordinality as categories(category, ordinality)
    where nullif(trim(categories.category), '') is not null
    group by app_private.online_category_id_for_value(categories.category)
  ) deduplicated;

  return normalized;
end;
$$;

create or replace function app_private.validate_online_category_order(
  value jsonb
)
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  normalized jsonb;
begin
  if jsonb_typeof(value) <> 'array' then
    raise exception 'Category order must be a JSON array';
  end if;

  if exists (
    select 1
    from jsonb_array_elements_text(value) categories(category_id)
    where not app_private.is_online_category_id(categories.category_id)
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'INVALID_ONLINE_CATEGORY',
      detail = 'INVALID_ONLINE_CATEGORY';
  end if;

  select coalesce(jsonb_agg(category_id order by first_index), '[]'::jsonb)
  into normalized
  from (
    select
      lower(trim(categories.category_id)) as category_id,
      min(categories.ordinality) as first_index
    from jsonb_array_elements_text(value)
      with ordinality as categories(category_id, ordinality)
    where nullif(trim(categories.category_id), '') is not null
    group by lower(trim(categories.category_id))
  ) deduplicated;

  return normalized;
end;
$$;

notify pgrst, 'reload schema';
