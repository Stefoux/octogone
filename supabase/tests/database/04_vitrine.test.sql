-- Vitrine : 9 emplacements, seulement ses propres cartes, écriture par set_vitrine.
begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data) values
  ('66666666-6666-6666-6666-666666666666', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'vitrine.a@octogone.local', '{"pseudo":"VitrineA"}'),
  ('77777777-7777-7777-7777-777777777777', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'vitrine.b@octogone.local', '{"pseudo":"VitrineB"}');

insert into public.editions (id, nom, annee, type, famille_cadre) values ('vt-ed', 'Test', 2099, 'originale', 'original');
insert into public.series (id, edition_id, code, nom, type) values ('vt-ed:BASE', 'vt-ed', 'BASE', 'Base', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime)
select 'vt-ed:' || g, 'vt-ed', 'vt-ed:BASE', g::text, g, 'Carte ' || g from generate_series(1, 12) g;
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel)
values ('vt-ed:BASE:base', 'vt-ed', 'vt-ed:BASE', 'Base', 'commune', 'base', false);

-- 11 exemplaires pour A (a1…a11), 1 pour B (b1)
insert into public.owned_cards (id, owner_id, card_id, variant_id, origine)
select ('a0000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid, '66666666-6666-6666-6666-666666666666',
       'vt-ed:' || g, 'vt-ed:BASE:base', 'depart'
  from generate_series(1, 11) g;
insert into public.owned_cards (id, owner_id, card_id, variant_id, origine) values
  ('b0000000-0000-0000-0000-000000000001', '77777777-7777-7777-7777-777777777777', 'vt-ed:12', 'vt-ed:BASE:base', 'depart');

-- Anonyme
set local role anon;
select throws_ok($$ select public.set_vitrine(array['a0000000-0000-0000-0000-000000000001'::uuid]) $$, '42501', null,
                 'anon ne peut pas modifier de vitrine');
select throws_ok($$ select * from public.vitrine_slots $$, '42501', null, 'anon ne lit pas les vitrines');
reset role;

-- Joueur A
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"66666666-6666-6666-6666-666666666666","role":"authenticated"}', true);

select lives_ok($$ select public.set_vitrine(array[
  'a0000000-0000-0000-0000-000000000003', null, 'a0000000-0000-0000-0000-000000000001']::uuid[]) $$,
  'A expose deux cartes (place 0 et place 2)');
select results_eq($$ select slot::int, owned_card_id::text from public.vitrine_slots order by slot $$,
  $$ values (0, 'a0000000-0000-0000-0000-000000000003'), (2, 'a0000000-0000-0000-0000-000000000001') $$,
  'places et cartes enregistrées');
select is((select count(*)::int from public.vitrine_de('66666666-6666-6666-6666-666666666666')), 2,
          'vitrine_de renvoie sa propre vitrine');

-- Réorganisation : on renvoie le nouvel ordre
select lives_ok($$ select public.set_vitrine(array[
  'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003']::uuid[]) $$, 'réorganiser');
select results_eq($$ select owned_card_id::text from public.vitrine_slots order by slot $$,
  $$ values ('a0000000-0000-0000-0000-000000000001'), ('a0000000-0000-0000-0000-000000000003') $$,
  'nouvel ordre enregistré');

select throws_ok($$ select public.set_vitrine(array['b0000000-0000-0000-0000-000000000001'::uuid]) $$, 'P0006', null,
                 'impossible d''exposer la carte d''un autre joueur');
select throws_ok($$ select public.set_vitrine(array[
  'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001']::uuid[]) $$, 'P0007', null,
  'une carte ne peut être exposée qu''une fois');
select throws_ok($$ select public.set_vitrine(array(
  select ('a0000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid from generate_series(1, 10) g)) $$, 'P0005', null,
  'pas plus de 9 emplacements');
select throws_ok($$ insert into public.vitrine_slots (owner_id, slot, owned_card_id) values
  ('66666666-6666-6666-6666-666666666666', 5, 'a0000000-0000-0000-0000-000000000005') $$, '42501', null,
  'écriture directe interdite (passer par set_vitrine)');

-- Joueur B ne voit pas la vitrine de A
select set_config('request.jwt.claims', '{"sub":"77777777-7777-7777-7777-777777777777","role":"authenticated"}', true);
select is_empty($$ select 1 from public.vitrine_slots $$, 'B ne voit pas la vitrine de A');
select is_empty($$ select 1 from public.vitrine_de('66666666-6666-6666-6666-666666666666') $$,
                'vitrine_de : la vitrine des autres reste privée pour l''instant');
reset role;

-- Un exemplaire qui quitte la collection quitte la vitrine
delete from public.owned_cards where id = 'a0000000-0000-0000-0000-000000000001';
select is((select count(*)::int from public.vitrine_slots where owner_id = '66666666-6666-6666-6666-666666666666'), 1,
          'carte retirée de la collection : retirée de la vitrine');

select * from finish();
rollback;
