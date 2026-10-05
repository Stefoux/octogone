-- Succès : progression calculée par le serveur, récompense une seule fois.
begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

update public.succes_modeles set actif = false;
insert into public.succes_modeles (id, type, objectif, pieces, libelle, ordre) values
  ('t-cartes-2', 'cartes_distinctes', 2, 100, '{"fr":"2 cartes","en":"2 cards"}', 1),
  ('t-legendaire', 'legendaires', 1, 250, '{"fr":"Légendaire","en":"Legendary"}', 2),
  ('t-serie', 'series_completes', 1, 300, '{"fr":"Série","en":"Series"}', 3),
  ('t-vitrine', 'vitrine', 1, 50, '{"fr":"Vitrine","en":"Showcase"}', 4);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data) values
  ('13131313-1313-1313-1313-131313131313', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'succes.test@octogone.local', '{"pseudo":"SuccesTest"}');
insert into public.editions (id, nom, annee, type, famille_cadre) values ('sc-ed', 'Test', 2099, 'originale', 'original');
insert into public.series (id, edition_id, code, nom, type) values ('sc-ed:BASE', 'sc-ed', 'BASE', 'Base', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime) values
  ('sc-ed:1', 'sc-ed', 'sc-ed:BASE', '1', 1, 'Carte 1'),
  ('sc-ed:2', 'sc-ed', 'sc-ed:BASE', '2', 2, 'Carte 2');
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel)
values ('sc-ed:BASE:base', 'sc-ed', 'sc-ed:BASE', 'Base', 'commune', 'base', false);
insert into public.owned_cards (id, owner_id, card_id, variant_id, origine) values
  ('c1000000-0000-0000-0000-000000000001', '13131313-1313-1313-1313-131313131313', 'sc-ed:1', 'sc-ed:BASE:base', 'depart'),
  ('c1000000-0000-0000-0000-000000000002', '13131313-1313-1313-1313-131313131313', 'sc-ed:2', 'sc-ed:BASE:base', 'depart');

set local role anon;
select throws_ok($$ select * from public.mes_succes() $$, '42501', null, 'anon n''a pas de succès');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"13131313-1313-1313-1313-131313131313","role":"authenticated"}', true);

select results_eq($$ select succes_id, progression from public.mes_succes() $$,
  $$ values ('t-cartes-2', 2), ('t-legendaire', 0), ('t-serie', 1), ('t-vitrine', 0) $$,
  'progression calculée depuis la collection (série complète comprise)');
select is(public.recuperer_succes('t-cartes-2'), 600, 'récompense créditée (500 + 100)');
select throws_ok($$ select public.recuperer_succes('t-cartes-2') $$, 'P0012', null, 'une seule fois');
select throws_ok($$ select public.recuperer_succes('t-legendaire') $$, 'P0013', null, 'succès pas encore atteint');
select ok((select recupere from public.mes_succes() where succes_id = 't-cartes-2'), 'marqué comme récupéré');
select lives_ok($$ select public.set_vitrine(array['c1000000-0000-0000-0000-000000000001']::uuid[]) $$, 'exposer une carte');
select is((select progression from public.mes_succes() where succes_id = 't-vitrine'), 1, 'vitrine prise en compte');
select is((select count(*)::int from public.wallet_ledger where source = 'succes' and pieces = 100), 1, 'récompense au journal');
select throws_ok($$ insert into public.succes_joueur (user_id, succes_id) values
  ('13131313-1313-1313-1313-131313131313', 't-legendaire') $$, '42501', null, 'le joueur ne s''attribue pas de succès');

select * from finish();
rollback;
