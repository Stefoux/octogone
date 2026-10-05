-- Défis : attribution (un par type, 4 du jour, 3 de la semaine), progression
-- comptée par le serveur, récompense une seule fois, paiement en pièces journalisé.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

-- Modèles de test uniquement (les vrais modèles éventuels sont désactivés le temps du test)
update public.defi_modeles set actif = false;
insert into public.defi_modeles (id, periode, type, objectif, pieces, libelle) values
  ('t-j-connexion', 'jour', 'connexion', 1, 20, '{"fr":"Passer","en":"Drop by"}'),
  ('t-j-boosters-2', 'jour', 'ouvrir_booster', 2, 40, '{"fr":"2 boosters","en":"2 boosters"}'),
  ('t-j-boosters-3', 'jour', 'ouvrir_booster', 3, 55, '{"fr":"3 boosters","en":"3 boosters"}'),
  ('t-j-rares', 'jour', 'reveler_rare', 2, 45, '{"fr":"Rares","en":"Rares"}'),
  ('t-j-vitrine', 'jour', 'vitrine', 1, 30, '{"fr":"Vitrine","en":"Showcase"}'),
  ('t-s-boosters', 'semaine', 'ouvrir_booster', 12, 200, '{"fr":"12 boosters","en":"12 boosters"}'),
  ('t-s-recycler', 'semaine', 'recycler', 15, 170, '{"fr":"Recycler","en":"Recycle"}'),
  ('t-s-fabriquer', 'semaine', 'fabriquer', 3, 200, '{"fr":"Fabriquer","en":"Craft"}');

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data) values
  ('12121212-1212-1212-1212-121212121212', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'defis.test@octogone.local', '{"pseudo":"DefisTest"}');

-- Petite collection pour ouvrir des boosters
insert into public.fighters (id, nom) select 'df-f' || g, 'Combattant ' || g from generate_series(1, 8) g;
insert into public.editions (id, nom, annee, type, famille_cadre) values ('df-ed', 'Test', 2099, 'originale', 'original');
insert into public.series (id, edition_id, code, nom, type) values ('df-ed:BASE', 'df-ed', 'BASE', 'Base', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, fighter_ids)
select 'df-ed:' || g, 'df-ed', 'df-ed:BASE', g::text, g, 'Carte ' || g, array['df-f' || g] from generate_series(1, 8) g;
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel) values
  ('df-ed:BASE:base', 'df-ed', 'df-ed:BASE', 'Base', 'commune', 'base', false),
  ('df-ed:BASE:neon', 'df-ed', 'df-ed:BASE', 'Néon', 'rare', 'neon', false);
insert into public.booster_types (id, edition_id, nom, type, nb_cartes, prix_pieces, composition) values
  ('df-std', 'df-ed', 'Test', 'standard', 3, 100, '{"slots":[{"nb":2,"poids":{"commune":100}},{"nb":1,"poids":{"rare":100}}]}');

set local role anon;
select throws_ok($$ select * from public.mes_defis() $$, '42501', null, 'anon n''a pas de défis');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"12121212-1212-1212-1212-121212121212","role":"authenticated"}', true);

create temp table d1 as select * from public.mes_defis();
select is((select count(*)::int from d1 where periode = 'jour'), 4, '4 défis du jour');
select is((select count(*)::int from d1 where periode = 'semaine'), 3, '3 défis de la semaine');
select is((select count(distinct type)::int from d1 where periode = 'jour'), 4, 'un seul défi par type');
select is((select progression from d1 where type = 'connexion'), 1, 'la visite du jour compte pour « Passer à l''Octogone »');
select ok((select bool_and(fin > now()) from d1), 'chaque défi indique sa fin');

-- Progression par les fonctions serveur
select lives_ok($$ select * from public.open_booster('df-std') $$, 'ouvrir un booster');
create temp table d2 as select * from public.mes_defis();
select is((select progression from d2 where type = 'ouvrir_booster' and periode = 'jour'), 1, 'booster compté (jour)');
select is((select progression from d2 where type = 'ouvrir_booster' and periode = 'semaine'), 1, 'booster compté (semaine)');
select is((select progression from d2 where type = 'reveler_rare'), 1, 'carte Rare révélée comptée');

-- Récompense
select is(public.recuperer_defi('t-j-connexion'), 520, 'récompense créditée (500 + 20)');
select throws_ok($$ select public.recuperer_defi('t-j-connexion') $$, 'P0012', null, 'une seule fois');
select throws_ok($$ select public.recuperer_defi((select modele_id from d2 where type = 'ouvrir_booster' and periode = 'jour')) $$,
                 'P0013', null, 'défi pas encore accompli');
select is((select count(*)::int from public.wallet_ledger where source = 'defi' and pieces = 20), 1, 'récompense au journal');
select throws_ok($$ update public.defis_joueur set progression = 99 $$, '42501', null, 'le joueur ne triche pas sur sa progression');

-- Paiement en pièces journalisé (hors mode test)
reset role;
update public.economy_config set mode_test = false;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"12121212-1212-1212-1212-121212121212","role":"authenticated"}', true);
select * from public.open_booster('df-std', 'pieces');
select is((select pieces from public.wallet_ledger where source = 'booster' order by id desc limit 1), -100,
          'booster payé en pièces inscrit au journal');

select * from finish();
rollback;
