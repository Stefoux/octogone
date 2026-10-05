-- Atelier : recyclage des doublons, fabrication, protection, journal.
begin;
create extension if not exists pgtap with schema extensions;
select plan(20);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data) values
  ('88888888-8888-8888-8888-888888888888', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'atelier.a@octogone.local', '{"pseudo":"AtelierA"}'),
  ('99999999-9999-9999-9999-999999999999', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'atelier.b@octogone.local', '{"pseudo":"AtelierB"}');

insert into public.fighters (id, nom, champion_actuel) values ('at-f1', 'Champion', true), ('at-f2', 'Challenger', false);
insert into public.editions (id, nom, annee, type, famille_cadre) values ('at-ed', 'Test', 2099, 'originale', 'original');
insert into public.series (id, edition_id, code, nom, type) values ('at-ed:BASE', 'at-ed', 'BASE', 'Base', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, fighter_ids) values
  ('at-ed:1', 'at-ed', 'at-ed:BASE', '1', 1, 'Champion', array['at-f1']),
  ('at-ed:2', 'at-ed', 'at-ed:BASE', '2', 2, 'Challenger', array['at-f2']);
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel, tirage, eligibilite) values
  ('at-ed:BASE:base', 'at-ed', 'at-ed:BASE', 'Base', 'commune', 'base', false, null, null),
  ('at-ed:BASE:neon', 'at-ed', 'at-ed:BASE', 'Néon', 'rare', 'neon', false, null, '{}'),
  ('at-ed:BASE:or', 'at-ed', 'at-ed:BASE', 'Or', 'epique', 'refractor', false, 50, '{}'),
  ('at-ed:BASE:ceinture', 'at-ed', 'at-ed:BASE', 'Ceinture', 'legendaire', 'ceinture_or', false, null, '{"champion": true}'),
  ('at-ed:BASE:duel', 'at-ed', 'at-ed:BASE', 'Duel', 'rare', 'face_a_face', false, null, '{"carte": "duel"}');

-- A : 3 × carte 1 base, 1 × carte 2 base, 1 × carte 1 numérotée 7/50 ; B : 1 × carte 2 base
insert into public.owned_cards (id, owner_id, card_id, variant_id, numero_serie, tirage, origine) values
  ('a1000000-0000-0000-0000-000000000001', '88888888-8888-8888-8888-888888888888', 'at-ed:1', 'at-ed:BASE:base', null, null, 'depart'),
  ('a1000000-0000-0000-0000-000000000002', '88888888-8888-8888-8888-888888888888', 'at-ed:1', 'at-ed:BASE:base', null, null, 'depart'),
  ('a1000000-0000-0000-0000-000000000003', '88888888-8888-8888-8888-888888888888', 'at-ed:1', 'at-ed:BASE:base', null, null, 'depart'),
  ('a1000000-0000-0000-0000-000000000004', '88888888-8888-8888-8888-888888888888', 'at-ed:2', 'at-ed:BASE:base', null, null, 'depart'),
  ('a1000000-0000-0000-0000-000000000005', '88888888-8888-8888-8888-888888888888', 'at-ed:1', 'at-ed:BASE:or', 7, 50, 'booster'),
  ('b1000000-0000-0000-0000-000000000001', '99999999-9999-9999-9999-999999999999', 'at-ed:2', 'at-ed:BASE:base', null, null, 'depart');

set local role anon;
select throws_ok($$ select * from public.recycler(array['a1000000-0000-0000-0000-000000000001'::uuid]) $$, '42501', null,
                 'anon ne recycle pas');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"88888888-8888-8888-8888-888888888888","role":"authenticated"}', true);

-- Recyclage
select results_eq($$ select cartes, fragments_gagnes, fragments from public.recycler(array[
  'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002']::uuid[]) $$,
  $$ values (2, 10, 10) $$, 'deux doublons communs : +10 fragments');
select is((select count(*)::int from public.owned_cards where card_id = 'at-ed:1' and variant_id = 'at-ed:BASE:base'), 1,
          'il reste un exemplaire');
select throws_ok($$ select * from public.recycler(array['a1000000-0000-0000-0000-000000000003'::uuid]) $$, 'P0009', null,
                 'impossible de recycler le dernier exemplaire');
select throws_ok($$ select * from public.recycler(array['a1000000-0000-0000-0000-000000000005'::uuid]) $$, 'P0008', null,
                 'une carte numérotée ne se recycle pas');
select throws_ok($$ select * from public.recycler(array['b1000000-0000-0000-0000-000000000001'::uuid]) $$, 'P0006', null,
                 'impossible de recycler la carte d''un autre');
select is((select count(*)::int from public.wallet_ledger where source = 'recyclage' and quantite = 2 and fragments = 10), 1,
          'recyclage inscrit au journal');
select throws_ok($$ update public.wallets set fragments = 99999 $$, '42501', null, 'le joueur ne modifie pas son portefeuille');

-- Protection et vitrine
reset role;
insert into public.owned_cards (id, owner_id, card_id, variant_id, origine) values
  ('a1000000-0000-0000-0000-000000000006', '88888888-8888-8888-8888-888888888888', 'at-ed:2', 'at-ed:BASE:base', 'depart'),
  ('a1000000-0000-0000-0000-000000000007', '88888888-8888-8888-8888-888888888888', 'at-ed:2', 'at-ed:BASE:base', 'depart');
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"88888888-8888-8888-8888-888888888888","role":"authenticated"}', true);
select lives_ok($$ select public.proteger('a1000000-0000-0000-0000-000000000006', true) $$, 'protéger une carte');
select throws_ok($$ select * from public.recycler(array['a1000000-0000-0000-0000-000000000006'::uuid]) $$, 'P0008', null,
                 'une carte protégée ne se recycle pas');
select lives_ok($$ select public.set_vitrine(array['a1000000-0000-0000-0000-000000000007']::uuid[]) $$, 'exposer une carte');
select throws_ok($$ select * from public.recycler(array['a1000000-0000-0000-0000-000000000007'::uuid]) $$, 'P0008', null,
                 'une carte exposée ne se recycle pas');

-- Fabrication
select is(public.cout_fabrication('at-ed:BASE:neon'), 240, 'Rare : 40 × 6 = 240 fragments');
select is(public.cout_fabrication('at-ed:BASE:or'), null::integer, 'numérotée : pas de fabrication');
select is(public.cout_fabrication('at-ed:BASE:duel'), null::integer, 'variante spéciale (duel) : pas de fabrication');
select throws_ok($$ select public.fabriquer('at-ed:2', 'at-ed:BASE:neon') $$, 'P0004', null, 'pas assez de fragments');
reset role;
update public.wallets set fragments = 3000 where user_id = '88888888-8888-8888-8888-888888888888';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"88888888-8888-8888-8888-888888888888","role":"authenticated"}', true);
select is((select origine from public.fabriquer('at-ed:2', 'at-ed:BASE:neon')), 'fabrication', 'carte fabriquée');
select is((select fragments from public.wallets), 2760, 'fragments débités (3000 - 240)');
select throws_ok($$ select public.fabriquer('at-ed:2', 'at-ed:BASE:ceinture') $$, 'P0011', null,
                 'Ceinture d''Or : seulement pour un champion');
select throws_ok($$ select public.fabriquer('at-ed:1', 'at-ed:BASE:or') $$, 'P0010', null,
                 'une carte numérotée ne se fabrique pas');

select * from finish();
rollback;
