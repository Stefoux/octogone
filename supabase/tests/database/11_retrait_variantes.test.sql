-- Retrait de variantes du jeu (Refractor) : exemplaires supprimés, fragments
-- remboursés selon la rareté, variantes désactivées, vitrine nettoyée.
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data) values
  ('7c000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'retrait.a@octogone.local', '{"pseudo":"RetraitA"}'),
  ('7c000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'retrait.b@octogone.local', '{"pseudo":"RetraitB"}');

insert into public.fighters (id, nom) values ('rv-f1', 'Combattant 1');
insert into public.editions (id, nom, annee, type, famille_cadre) values ('rv-ed', 'Test', 2099, 'reelle', 'chrome');
insert into public.series (id, edition_id, code, nom, type) values ('rv-ed:BASE', 'rv-ed', 'BASE', 'Base', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, fighter_ids) values
  ('rv-ed:1', 'rv-ed', 'rv-ed:BASE', '1', 1, 'Combattant 1', array['rv-f1']);
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel, tirage) values
  ('rv-ed:BASE:base', 'rv-ed', 'rv-ed:BASE', 'Base', 'commune', 'base', true, null),
  ('rv-ed:BASE:refractor', 'rv-ed', 'rv-ed:BASE', 'Refractor', 'peu_commune', 'refractor', true, null),
  ('rv-ed:BASE:gold', 'rv-ed', 'rv-ed:BASE', 'Gold Refractor', 'epique', 'refractor', true, 50);
-- A : 2 Refractor (peu commune) + 1 Gold /50 (épique) exposée en vitrine + 1 Base ; B : 1 Refractor
insert into public.owned_cards (id, owner_id, card_id, variant_id, numero_serie, tirage, origine) values
  ('7c100000-0000-0000-0000-000000000001', '7c000000-0000-0000-0000-000000000001', 'rv-ed:1', 'rv-ed:BASE:refractor', null, null, 'booster'),
  ('7c100000-0000-0000-0000-000000000002', '7c000000-0000-0000-0000-000000000001', 'rv-ed:1', 'rv-ed:BASE:refractor', null, null, 'booster'),
  ('7c100000-0000-0000-0000-000000000003', '7c000000-0000-0000-0000-000000000001', 'rv-ed:1', 'rv-ed:BASE:gold', 7, 50, 'booster'),
  ('7c100000-0000-0000-0000-000000000004', '7c000000-0000-0000-0000-000000000001', 'rv-ed:1', 'rv-ed:BASE:base', null, null, 'booster'),
  ('7c100000-0000-0000-0000-000000000005', '7c000000-0000-0000-0000-000000000002', 'rv-ed:1', 'rv-ed:BASE:refractor', null, null, 'booster');
insert into public.vitrine_slots (owner_id, slot, owned_card_id)
values ('7c000000-0000-0000-0000-000000000001', 0, '7c100000-0000-0000-0000-000000000003');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"7c000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select throws_ok($$ select * from public._retirer_variantes(array['rv-ed:BASE:base'], 'x') $$, '42501', null,
                 'un joueur ne retire pas de variantes');
reset role;

create temp table res as
  select * from public._retirer_variantes(array['rv-ed:BASE:refractor', 'rv-ed:BASE:gold'], 'test retrait');
-- Barème de recyclage : peu commune 15, épique 100
select is((select fragments from res where joueur = '7c000000-0000-0000-0000-000000000001'), 2 * 15 + 100,
          'A : 2 peu communes + 1 épique = 130 fragments');
select is((select fragments from res where joueur = '7c000000-0000-0000-0000-000000000002'), 15, 'B : 15 fragments');
select is((select cartes from res where joueur = '7c000000-0000-0000-0000-000000000001'), 3, 'A : 3 exemplaires retirés');
select is((select array_agg(variant_id) from public.owned_cards where card_id = 'rv-ed:1')::text, '{rv-ed:BASE:base}',
          'seule la Base reste');
select is((select fragments from public.wallets where user_id = '7c000000-0000-0000-0000-000000000002'), 15,
          'fragments crédités au portefeuille');
select is((select count(*)::int from public.wallet_ledger where ref = 'test retrait' and source = 'admin'), 2,
          'remboursements inscrits au journal');
select is((select count(*)::int from public.vitrine_slots where owner_id = '7c000000-0000-0000-0000-000000000001'), 0,
          'la carte exposée quitte la vitrine');
select is((select array_agg(id order by id) from public.variants where edition_id = 'rv-ed' and deleted)::text,
          '{rv-ed:BASE:gold,rv-ed:BASE:refractor}', 'variantes retirées du jeu');

select * from finish();
rollback;
