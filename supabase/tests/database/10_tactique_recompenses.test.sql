-- Cartes Tactique gagnées : victoire en combat (1 chance sur 2, rareté selon
-- le niveau ou la Route), défis récupérés, succès de combat.
begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data) values
  ('7b000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'recompense.a@octogone.local', '{"pseudo":"RecompenseA"}');

-- Édition Tactique de test (le contenu importé est mis de côté)
update public.editions set deleted = true where type = 'tactique';
insert into public.editions (id, nom, annee, type, famille_cadre) values ('tr-ed', 'Tactique', 2099, 'tactique', 'tactique');
insert into public.series (id, edition_id, code, nom, type) values ('tr-ed:BASE', 'tr-ed', 'BASE', 'Tactique', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, tactique) values
  ('tr-ed:1', 'tr-ed', 'tr-ed:BASE', '1', 1, 'Second souffle', 'second_souffle'),
  ('tr-ed:2', 'tr-ed', 'tr-ed:BASE', '2', 2, 'Plan de match', 'plan_de_match');
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel) values
  ('tr-ed:BASE:base', 'tr-ed', 'tr-ed:BASE', 'Commune', 'commune', 'base', false),
  ('tr-ed:BASE:rare', 'tr-ed', 'tr-ed:BASE', 'Rare', 'rare', 'tactique_rare', false),
  ('tr-ed:BASE:epique', 'tr-ed', 'tr-ed:BASE', 'Épique', 'epique', 'tactique_epique', false),
  ('tr-ed:BASE:legendaire', 'tr-ed', 'tr-ed:BASE', 'Légendaire', 'legendaire', 'tactique_legendaire', false);

insert into public.fighters (id, nom, categorie) values ('tr-f1', 'Combattant 1', 'legers'), ('tr-f2', 'Combattant 2', 'legers');
-- Combats déjà commencés (graine tirée par le serveur)
insert into public.combats (id, user_id, mode, niveau, format, graine, carte, combattant, rarete, bonus_stats,
                            adversaire, adversaire_rarete) values
  ('7b100000-0000-0000-0000-000000000001', '7b000000-0000-0000-0000-000000000001', 'rapide', 'difficile', 'court', 1,
   gen_random_uuid(), 'tr-f1', 'rare', 2, 'tr-f2', 'rare'),
  ('7b100000-0000-0000-0000-000000000002', '7b000000-0000-0000-0000-000000000001', 'route', 'facile', 'court', 2,
   gen_random_uuid(), 'tr-f1', 'rare', 2, 'tr-f2', 'rare'),
  ('7b100000-0000-0000-0000-000000000003', '7b000000-0000-0000-0000-000000000001', 'rapide', 'normal', 'court', 3,
   gen_random_uuid(), 'tr-f1', 'rare', 2, 'tr-f2', 'rare'),
  ('7b100000-0000-0000-0000-000000000004', '7b000000-0000-0000-0000-000000000001', 'rapide', 'normal', 'court', 4,
   gen_random_uuid(), 'tr-f1', 'rare', 2, 'tr-f2', 'rare');

select is((select (recompenses_tactique -> 'combat' ->> 'chance')::numeric from public.economy_config where id), 0.5,
          'une victoire donne une carte Tactique 1 fois sur 2');

-- Chance forcée à 100 % : Difficile tire dans son barème, la Route dans le sien
update public.economy_config set recompenses_tactique = jsonb_set(jsonb_set(jsonb_set(recompenses_tactique,
  '{combat,chance}', '1'), '{combat,difficile}', '{"epique": 100}'), '{combat,route}', '{"legendaire": 100}');
set local role service_role;
create temp table r1 as select public._terminer_combat('7b100000-0000-0000-0000-000000000001', true, 0::smallint,
                                                         'ko', 1, '[]', null, '[]') as r;
create temp table r2 as select public._terminer_combat('7b100000-0000-0000-0000-000000000002', true, 0::smallint,
                                                         'decisionUnanime', 3, '[]', null, '[]') as r;
create temp table r3 as select public._terminer_combat('7b100000-0000-0000-0000-000000000003', true, 1::smallint,
                                                         'ko', 2, '[]', null, '[]') as r;
reset role;
select is((select r -> 'carte' ->> 'rarete' from r1), 'epique', 'victoire en Difficile : carte du barème Difficile');
select is((select origine from public.owned_cards where id = (select (r -> 'carte' ->> 'owned_id')::uuid from r1)),
          'recompense', 'la carte est ajoutée à la collection (origine récompense)');
select is((select r -> 'carte' ->> 'rarete' from r2), 'legendaire', 'Route vers la ceinture : barème de la Route, quel que soit le niveau');
select is((select r -> 'carte' from r3), 'null'::jsonb, 'défaite : pas de carte');

-- Chance nulle : jamais de carte
update public.economy_config set recompenses_tactique = jsonb_set(recompenses_tactique, '{combat,chance}', '0');
set local role service_role;
select is((public._terminer_combat('7b100000-0000-0000-0000-000000000004', true, 0::smallint, 'ko', 1, '[]', null, '[]')
            -> 'carte'), 'null'::jsonb, 'chance nulle : pas de carte');
reset role;

-- Défis : une carte à chaque récupération, barème selon la période
update public.economy_config set recompenses_tactique = jsonb_set(recompenses_tactique, '{defi,semaine}', '{"legendaire": 100}');
insert into public.defi_modeles (id, periode, type, objectif, pieces, libelle, actif) values
  ('tr-jour', 'jour', 'ouvrir_booster', 1, 20, '{"fr": "Test"}', true),
  ('tr-semaine', 'semaine', 'ouvrir_booster', 1, 80, '{"fr": "Test"}', true);
insert into public.defis_joueur (user_id, modele_id, debut, progression) values
  ('7b000000-0000-0000-0000-000000000001', 'tr-jour', public._debut_periode('jour'), 1),
  ('7b000000-0000-0000-0000-000000000001', 'tr-semaine', public._debut_periode('semaine'), 1);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"7b000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
create temp table d1 as select public.reclamer_defi('tr-semaine') as r;
select is((select r -> 'carte' ->> 'rarete' from d1), 'legendaire', 'défi de la semaine : carte de son barème');
select ok((select (r ->> 'pieces')::int from d1) >= 80, 'pièces du défi créditées, nouveau solde renvoyé');
select ok(public.recuperer_defi('tr-jour') >= 100, 'ancienne fonction : renvoie toujours le solde');
select is((select count(*)::int from public.owned_cards
            where owner_id = '7b000000-0000-0000-0000-000000000001' and origine = 'recompense'), 4,
          'une carte par défi récupéré (2) en plus des victoires (2)');
select throws_ok($$ select public.reclamer_defi('tr-semaine') $$, 'P0012', null, 'un défi ne se récupère qu''une fois');
reset role;

-- Succès : une Épique pour les succès de combat seulement
insert into public.succes_modeles (id, type, objectif, pieces, libelle) values
  ('tr-combat', 'combats_gagnes', 1, 50, '{"fr": "Première victoire"}'),
  ('tr-cartes', 'cartes_distinctes', 1, 10, '{"fr": "Une carte"}');
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"7b000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select is(public.reclamer_succes('tr-combat') -> 'carte' ->> 'rarete', 'epique', 'succès de combat : carte Épique');
select is(public.reclamer_succes('tr-cartes') -> 'carte', 'null'::jsonb, 'autre succès : pas de carte');
select throws_ok($$ select public._donner_tactique('7b000000-0000-0000-0000-000000000001', '{"legendaire": 1}') $$,
                 '42501', null, 'le joueur ne se donne pas de carte lui-même');
reset role;

select * from finish();
rollback;
