-- Packs Premium+ : 5 cartes, Épique garantie, cartes à deux combattants
-- (Rivalités) tirées comme les autres ; le pack de bienvenue reste sur la Saison.
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data) values
  ('7d000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'packs.a@octogone.local', '{"pseudo":"PacksA"}');

insert into public.fighters (id, nom) select 'pp-f' || g, 'Combattant ' || g from generate_series(1, 6) g;
-- Pack Rivalités de test : cartes à deux combattants, une variante par rareté sans règle
insert into public.editions (id, nom, annee, type, famille_cadre) values ('pp-ed', 'Rivalités test', 2100, 'originale', 'original');
insert into public.series (id, edition_id, code, nom, type) values ('pp-ed:BASE', 'pp-ed', 'BASE', 'Rivalités', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, fighter_ids)
select 'pp-ed:' || g, 'pp-ed', 'pp-ed:BASE', g::text, g, 'Duel ' || g, array['pp-f' || g, 'pp-f' || (g % 6 + 1)]
  from generate_series(1, 6) g;
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel, tirage) values
  ('pp-ed:BASE:base', 'pp-ed', 'pp-ed:BASE', 'Base', 'commune', 'base', false, null),
  ('pp-ed:BASE:acier', 'pp-ed', 'pp-ed:BASE', 'Acier', 'peu_commune', 'acier', false, null),
  ('pp-ed:BASE:face_a_face', 'pp-ed', 'pp-ed:BASE', 'Face-à-Face', 'rare', 'face_a_face', false, null),
  ('pp-ed:BASE:onde_de_choc', 'pp-ed', 'pp-ed:BASE', 'Onde de Choc', 'epique', 'onde_de_choc', false, null),
  ('pp-ed:BASE:heritage', 'pp-ed', 'pp-ed:BASE', 'Héritage', 'legendaire', 'heritage', false, null),
  ('pp-ed:BASE:octogone_noir', 'pp-ed', 'pp-ed:BASE', 'Octogone Noir', 'mythique', 'octogone_noir', false, 5);
insert into public.booster_types (id, edition_id, nom, type, nb_cartes, prix_pieces, composition) values
  ('pp-plus', 'pp-ed', 'Rivalités', 'premium_plus', 5, 500,
   '{"slots":[{"nb":2,"poids":{"peu_commune":60,"rare":40}},{"nb":2,"poids":{"rare":65,"epique":35}},
              {"nb":1,"poids":{"epique":72,"legendaire":24,"mythique":4}}],"garantie":"epique"}');
-- Une Saison plus récente que la vraie (pour le pack de bienvenue)
insert into public.editions (id, nom, annee, type, famille_cadre) values ('saison-2099', 'Saison 2099', 2099, 'originale', 'original');
insert into public.series (id, edition_id, code, nom, type) values ('saison-2099:BASE', 'saison-2099', 'BASE', 'Base', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, fighter_ids)
select 'saison-2099:' || g, 'saison-2099', 'saison-2099:BASE', g::text, g, 'Carte ' || g, array['pp-f' || g]
  from generate_series(1, 6) g;
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel) values
  ('saison-2099:BASE:base', 'saison-2099', 'saison-2099:BASE', 'Base', 'commune', 'base', false);

select lives_ok($$ insert into public.booster_types (id, edition_id, nom, type, nb_cartes, composition)
                   values ('pp-ok', 'pp-ed', 'x', 'premium_plus', 1, '{"slots":[]}') $$, 'type premium_plus accepté');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"7d000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
create temp table b as select * from public.open_booster('pp-plus');
select is((select count(*)::int from b), 5, 'Premium+ : 5 cartes');
select ok((select max(public.rarity_rank(rarete)) from b) >= public.rarity_rank('epique'), 'au moins une Épique');
select is((select count(*)::int from b where rarete = 'commune'), 0, 'pas de Commune dans un Premium+');
select ok((select bool_and(cardinality(c.fighter_ids) = 2) from b join public.cards c on c.id = b.card_id),
          'cartes Face-à-Face à deux combattants tirées comme les autres');
create temp table w as select * from public.claim_welcome_pack();
select ok((select count(*) from w where card_id like 'saison-2099:%') > 0, 'pack de bienvenue : la Saison la plus récente');
select is((select count(*)::int from w where card_id like 'pp-ed:%'), 0,
          'pack de bienvenue : jamais une édition de pack Premium+, même plus récente');
reset role;

select * from finish();
rollback;
