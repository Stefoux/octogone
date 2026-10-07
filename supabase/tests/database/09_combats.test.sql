-- Combats : graine tirée par le serveur, carte possédée, récompenses selon le
-- niveau de l'IA (finish +50 %), plafond quotidien, défis, succès, sécurité.
begin;
create extension if not exists pgtap with schema extensions;
select plan(21);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data) values
  ('9c000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'combat.a@octogone.local', '{"pseudo":"CombatA"}'),
  ('9c000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'combat.b@octogone.local', '{"pseudo":"CombatB"}');

insert into public.fighters (id, nom, categorie) values
  ('cb-f1', 'Combattant 1', 'legers'), ('cb-f2', 'Combattant 2', 'legers');
insert into public.editions (id, nom, annee, type, famille_cadre) values ('cb-ed', 'Test', 2099, 'originale', 'original');
insert into public.series (id, edition_id, code, nom, type) values ('cb-ed:BASE', 'cb-ed', 'BASE', 'Base', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, fighter_ids) values
  ('cb-ed:1', 'cb-ed', 'cb-ed:BASE', '1', 1, 'Combattant 1', array['cb-f1']),
  ('cb-ed:2', 'cb-ed', 'cb-ed:BASE', '2', 2, 'Duo', array['cb-f1', 'cb-f2']);
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel, bonus_stats) values
  ('cb-ed:BASE:base', 'cb-ed', 'cb-ed:BASE', 'Base', 'commune', 'base', false, 0),
  ('cb-ed:BASE:neon', 'cb-ed', 'cb-ed:BASE', 'Néon', 'rare', 'neon', false, 2);
insert into public.owned_cards (id, owner_id, card_id, variant_id, origine) values
  ('c0000000-0000-0000-0000-000000000001', '9c000000-0000-0000-0000-000000000001', 'cb-ed:1', 'cb-ed:BASE:neon', 'booster'),
  ('c0000000-0000-0000-0000-000000000002', '9c000000-0000-0000-0000-000000000001', 'cb-ed:2', 'cb-ed:BASE:base', 'booster'),
  ('c0000000-0000-0000-0000-000000000003', '9c000000-0000-0000-0000-000000000002', 'cb-ed:1', 'cb-ed:BASE:base', 'booster');
-- Défi « Gagner 2 combats » : seul défi du jour actif pendant le test
update public.defi_modeles set actif = false where periode = 'jour';
insert into public.defi_modeles (id, periode, type, objectif, pieces, libelle, actif)
values ('cb-defi', 'jour', 'gagner_combat', 2, 60, '{"fr": "Gagner 2 combats"}', true)
on conflict (id) do update set actif = true;
insert into public.succes_modeles (id, type, objectif, pieces, libelle) values
  ('cb-succes', 'combats_gagnes', 1, 50, '{"fr": "Première victoire"}');

set local role anon;
select throws_ok($$ select * from public.commencer_combat('rapide', 'c0000000-0000-0000-0000-000000000001', 'cb-f2', 'rare', 'normal', 'court') $$,
                 '42501', null, 'anon ne commence pas de combat');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"9c000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select throws_ok($$ select * from public.commencer_combat('rapide', 'c0000000-0000-0000-0000-000000000003', 'cb-f2', 'commune', 'normal', 'court') $$,
                 'P0006', null, 'la carte d''un autre joueur est refusée');
select throws_ok($$ select * from public.commencer_combat('rapide', 'c0000000-0000-0000-0000-000000000002', 'cb-f2', 'commune', 'normal', 'court') $$,
                 'P0012', null, 'une carte à deux combattants ne se joue pas');
select throws_ok($$ select * from public.commencer_combat('rapide', 'c0000000-0000-0000-0000-000000000001', 'cb-f1', 'rare', 'normal', 'court') $$,
                 'P0003', null, 'pas contre soi-même');
select throws_ok($$ select * from public.commencer_combat('route', 'c0000000-0000-0000-0000-000000000001', 'cb-f2', 'legendaire', 'normal', 'court') $$,
                 '22023', null, 'adversaire de plus d''une rareté au-dessus refusé');
create temp table c1 as select * from public.commencer_combat('rapide', 'c0000000-0000-0000-0000-000000000001', 'cb-f2', 'epique', 'difficile', 'court');
grant select on c1 to public;
select ok((select graine from c1) between 0 and 2147483647, 'graine tirée par le serveur (31 bits)');
select is((select rarete || '/' || bonus_stats from public.combats where id = (select id from c1)), 'rare/2',
          'rareté et bonus de la carte relevés par le serveur');
select throws_ok($$ update public.combats set statut = 'valide' $$, '42501', null, 'le joueur ne modifie pas ses combats');
select throws_ok($$ select public._terminer_combat((select id from c1), true, 0::smallint, 'ko', 2, '[]', null, '[]') $$,
                 '42501', null, 'seul le service termine un combat');
reset role;

-- Victoire en difficile par KO : 90 × 1,5 = 135 pièces
set local role service_role;
select is((public._terminer_combat((select id from c1), true, 0::smallint, 'ko', 2, '[]', null, '[]') ->> 'pieces')::int, 135,
          'victoire difficile par KO : 135 pièces');
select is((public._terminer_combat((select id from c1), true, 0::smallint, 'ko', 2, '[]', null, '[]') ->> 'deja')::boolean, true,
          'un combat n''est récompensé qu''une fois');
reset role;
select is((select pieces from public.wallet_ledger where ref = (select id::text from c1)), 135, 'pièces inscrites au journal');
select is((select statut || '/' || vainqueur || '/' || methode from public.combats where id = (select id from c1)), 'valide/0/ko',
          'combat validé et enregistré');

-- Défaite : 5 pièces ; journal refusé : rien
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"9c000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
create temp table c2 as select * from public.commencer_combat('rapide', 'c0000000-0000-0000-0000-000000000001', 'cb-f2', 'rare', 'facile', 'court');
create temp table c3 as select * from public.commencer_combat('rapide', 'c0000000-0000-0000-0000-000000000001', 'cb-f2', 'rare', 'normal', 'complet');
create temp table c4 as select * from public.commencer_combat('rapide', 'c0000000-0000-0000-0000-000000000001', 'cb-f2', 'rare', 'normal', 'court');
grant select on c2, c3, c4 to public;
reset role;
set local role service_role;
select is((public._terminer_combat((select id from c2), true, 1::smallint, 'decisionUnanime', 3, '[]', null, '[]') ->> 'pieces')::int, 5,
          'défaite : 5 pièces');
select is(public._terminer_combat((select id from c3), false, null, null, null, '[]', null, '[]') ->> 'statut', 'refuse',
          'journal refusé : combat refusé');
reset role;
select is((select pieces from public.combats where id = (select id from c3)), 0, 'combat refusé : aucune pièce');

-- Plafond quotidien : il ne reste que 20 pièces à gagner aujourd'hui
update public.economy_config set plafond_combat_jour = 160;
set local role service_role;
select is((public._terminer_combat((select id from c4), true, 0::smallint, 'decisionUnanime', 3, '[]', null, '[]') ->> 'pieces')::int, 20,
          'plafond quotidien : gain réduit à ce qu''il reste (160 - 140)');
reset role;

-- Défis et succès
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"9c000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select is((select progression from public.defis_joueur where modele_id = 'cb-defi'
            and user_id = '9c000000-0000-0000-0000-000000000001'), 2, 'défi « Gagner 2 combats » complété');
select is((select progression from public.mes_succes() where succes_id = 'cb-succes'), 1,
          'succès « Première victoire » atteint');
select lives_ok($$ select public.abandonner_combat((select id from c1)) $$, 'abandon d''un combat déjà terminé : sans effet');
reset role;
select is((select statut from public.combats where id = (select id from c1)), 'valide', 'un combat terminé reste validé');

select * from finish();
rollback;
