-- Keep backend category validation and legacy label normalization in sync with
-- the client-side OnlineCategories registry.
create or replace function app_private.online_category_ids()
returns text[]
language sql
immutable
set search_path = ''
as $$
  select array[
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
    'nuts_seeds',
    'vegetarian_vegan',
    'cheese',
    'ham',
    'world_cuisines',
    'organic',
    'pasta',
    'rice',
    'sauces',
    'coffee',
    'tea',
    'other'
  ]::text[];
$$;

create or replace function app_private.online_category_id_for_value(value text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  cleaned text := lower(trim(coalesce(value, '')));
  key text := app_private.online_category_key(value);
begin
  if app_private.is_online_category_id(cleaned) then
    return cleaned;
  end if;

  return case
    when key in (
      'drinks', 'drink', 'napoje', 'getrnke', 'dranken', 'bebidas',
      'boissons', 'bevande', 'water', 'wasser', 'sok', 'juice'
    ) then 'drinks'
    when key in (
      'coffee', 'kawy', 'kawa', 'kaffee', 'koffie', 'cafs', 'cafes',
      'cafe', 'caff', 'caffe', 'кава'
    ) then 'coffee'
    when key in (
      'tea', 'herbaty', 'herbata', 'tee', 'thee', 'ts', 'tes', 'ths',
      'thes', 't', 'te', 'chs', 'chas', 'чай'
    ) then 'tea'
    when key in (
      'coffeetea', 'kawaiherbata', 'kaffeeundtee', 'koffieenthee',
      'cafete', 'cafyt', 'cafeetthe', 'caffeete', 'cafecha'
    ) then 'coffee_tea'
    when key in (
      'alcohol', 'alkohol', 'alcool', 'alcol', 'alcolici', 'lcool',
      'beer', 'piwo', 'wine', 'wino'
    ) then 'alcohol'
    when key in (
      'sweets', 'sweet', 'slodycze', 'sussigkeiten', 'sigkeiten', 'snoep',
      'dulces', 'confiseries', 'dolci', 'doces', 'candy', 'chocolate'
    ) then 'sweets'
    when key in (
      'snacks', 'snack', 'przekaski', 'aperitivos', 'chips', 'crisps'
    ) then 'snacks'
    when key in (
      'nutsseeds', 'nutsandseeds', 'nuts', 'seeds', 'orzechyipestki',
      'orzechy', 'pestki', 'nsseundsamen', 'nusseundsamen',
      'notenenzaden', 'frutossecosysemillas', 'noixetgraines',
      'горіхи та насіння', 'fruttaseccaesemi', 'frutossecosesementes'
    ) then 'nuts_seeds'
    when key in (
      'vegetarianvegan', 'vegetarianandvegan', 'vegetarian', 'vegan',
      'plantbased', 'wege', 'wegetarianskie', 'vegetarischvegan',
      'vegetarischenveganistisch', 'vegetarianoyvegano',
      'vgtarienetvgan', 'vegetarienetvegan',
      'вегетаріанські та веганські продукти', 'vegetarianoevegano'
    ) then 'vegetarian_vegan'
    when key in (
      'fruit', 'fruits', 'owoce', 'obst', 'fruta', 'frutas', 'frutta'
    ) then 'fruit'
    when key in (
      'vegetables', 'vegetable', 'warzywa', 'gemuse', 'gemse', 'groenten',
      'verduras', 'legumes', 'lgumes', 'verdure', 'vegetais'
    ) then 'vegetables'
    when key in (
      'cheese', 'cheeses', 'sery', 'ser', 'kse', 'kase', 'kaas',
      'quesos', 'queso', 'fromages', 'fromage', 'сири', 'formaggi',
      'queijos'
    ) then 'cheese'
    when key in (
      'dairyeggs', 'dairy', 'eggs', 'nabial', 'nabialijajka',
      'molkereiprodukte', 'milchprodukteundeier', 'zuivel',
      'zuiv eleneieren', 'lcteos', 'lacteos', 'lcteosyhuevos',
      'lacteosyhuevos', 'produitslaitiers', 'latticini', 'laticinios',
      'milk', 'mleko', 'jajka'
    ) then 'dairy_eggs'
    when key in (
      'bakery', 'piekarnia', 'pieczywo', 'backerei', 'bckerei',
      'bakkerij', 'panaderia', 'panadera', 'boulangerie', 'panetteria',
      'padaria', 'bread', 'chleb'
    ) then 'bakery'
    when key in (
      'ham', 'hams', 'szynki', 'szynka', 'schinken', 'jamones', 'jamon',
      'jambons', 'шинки', 'prosciutti', 'prosciutto', 'presuntos'
    ) then 'ham'
    when key in (
      'meat', 'mieso', 'fleisch', 'vlees', 'carne', 'viande'
    ) then 'meat'
    when key in (
      'fishseafood', 'fish', 'seafood', 'ryby', 'rybyiowocemorza',
      'pescadoymarisco', 'poissonetfruitsdemer', 'pesceefruttidimare',
      'peixeemarisco'
    ) then 'fish_seafood'
    when key in (
      'frozen', 'mrozonki', 'tiefkuhlkost', 'tiefkhlkost', 'diepvries',
      'congelados', 'surgeles', 'surgels', 'surgelati'
    ) then 'frozen'
    when key in (
      'pasta', 'pastas', 'makarony', 'makaron', 'nudeln', 'ptes', 'pates',
      'макаронні вироби', 'massa', 'massas', 'noodles'
    ) then 'pasta'
    when key in (
      'rice', 'ryze', 'ryz', 'reis', 'rijst', 'arroces', 'riz', 'рис',
      'riso', 'arroz'
    ) then 'rice'
    when key in (
      'drygoods', 'pastariceflour', 'makaronryzimaka',
      'makaronryzimka', 'nudelnreisundmehl', 'pastarijstenbloem',
      'pastaarrozyharina', 'ptesrizetfarine', 'patesrizetfarine',
      'pastarisoefarina', 'massaarrozefarinha', 'flour', 'maka', 'mka'
    ) then 'dry_goods'
    when key in (
      'cannedjars', 'cansjars', 'konserwyisloiki', 'konserwyisloiki',
      'konservenundglaser', 'blikkenenpotten', 'conservasytarros',
      'conservesetbocaux', 'scatoletteebarattoli', 'conservasefrascos',
      'cans', 'jars', 'konserwy', 'sloiki'
    ) then 'canned_jars'
    when key in (
      'spicescondiments', 'spices', 'condiments', 'przyprawy',
      'gewurze', 'gewrze', 'kruidenenspecerijen',
      'especiasycondimentos', 'epicesetcondiments',
      'picesetcondiments', 'spezieecondimenti',
      'especiariasecondimentos'
    ) then 'spices_condiments'
    when key in (
      'sauces', 'sauce', 'sosy', 'sos', 'soen', 'sossen', 'sauzen',
      'salsas', 'соуси', 'salse', 'molhos'
    ) then 'sauces'
    when key in (
      'oilssauces', 'oilsauces', 'olejeisosy', 'oleundsoen',
      'leundsoen', 'olienensauzen', 'olinenensauzen',
      'aceitesysalsas', 'huilesetsauces', 'oliesalse',
      'oleosemolhos', 'oil', 'olej'
    ) then 'oils_sauces'
    when key in (
      'worldcuisines', 'worldfood', 'internationalfood',
      'internationalcuisine', 'kuchnieswiata', 'internationalekche',
      'internationalekuche', 'wereldkeuken', 'cocinasdelmundo',
      'cuisinesdumonde', 'кухні світу', 'cucinedalmondo',
      'cozinhasdomundo'
    ) then 'world_cuisines'
    when key in (
      'organic', 'organicfood', 'bio', 'eco', 'ecological',
      'ekologiczne', 'biologisch', 'ecolgico', 'ecologico',
      'органічні продукти', 'biologico', 'biolgico'
    ) then 'organic'
    when key in (
      'readymeals', 'daniagotowe', 'fertiggerichte',
      'kantenklaarmaaltijden', 'platospreparados', 'platsprepares',
      'platsprpars', 'piattipronti', 'refeicoesprontas',
      'refeiesprontas'
    ) then 'ready_meals'
    when key in (
      'householdcleaning', 'household', 'cleaning', 'chemia',
      'chemiadomowa', 'haushalt', 'haushaltsreinigung', 'huishouden',
      'huishoudelijkeschoonmaak', 'hogar', 'limpiezadelhogar',
      'maison', 'entretiendelamaison', 'casa', 'limpezadomestica',
      'limpezadomstica'
    ) then 'household_cleaning'
    when key in (
      'paperhygiene', 'paper', 'hygiene', 'papierihigiena',
      'papierundhygiene', 'papierenhygiene', 'papelehigiene',
      'papierethygiene', 'cartaeigiene'
    ) then 'paper_hygiene'
    when key in (
      'personalcare', 'higienaosobista', 'korperpflege', 'krperpflege',
      'persoonlijkeverzorging', 'cuidadopersonal', 'soinspersonnels',
      'curapersonale', 'cuidadospessoais', 'cosmetics', 'kosmetyki'
    ) then 'personal_care'
    when key in ('other', 'inne', 'andere', 'overig', 'otros', 'autre', 'altro')
      then 'other'
    else 'other'
  end;
end;
$$;

notify pgrst, 'reload schema';
