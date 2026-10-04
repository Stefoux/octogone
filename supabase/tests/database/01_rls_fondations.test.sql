-- Tests des policies RLS de la phase 1 (supabase test db).
-- On simule de vrais utilisateurs : rôle Postgres « authenticated » + JWT avec leur id.
begin;
create extension if not exists pgtap with schema extensions;
select plan(30);

-- Deux comptes : un joueur et un admin (email listé dans admin_emails).
insert into public.admin_emails (email) values ('admin.test@octogone.local');
insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'joueur.test@octogone.local', '{"pseudo":"JoueurTest"}'),
  ('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'Admin.Test@octogone.local', '{"pseudo":"AdminTest"}'),
  ('33333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'autre.test@octogone.local', '{"pseudo":"JoueurTest"}');

-- Contenu minimal (inséré en superutilisateur)
insert into public.fighters (id, nom) values ('test-fighter', 'Test Fighter');
insert into public.editions (id, nom, annee, type, famille_cadre) values ('ed-test', 'Édition test', 2024, 'reelle', 'chrome');
insert into public.series (id, edition_id, code, nom, type) values ('ed-test:BASE', 'ed-test', 'BASE', 'Base', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, fighter_ids)
  values ('ed-test:1', 'ed-test', 'ed-test:BASE', '1', 1, 'Test Fighter', '{test-fighter}');
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel, tirage)
  values ('ed-test:BASE:gold', 'ed-test', 'ed-test:BASE', 'Gold Refractor', 'legendaire', 'gold', true, 50);
insert into public.owned_cards (owner_id, card_id, variant_id, numero_serie, tirage, origine)
  values ('33333333-3333-3333-3333-333333333333', 'ed-test:1', 'ed-test:BASE:gold', 7, 50, 'booster');

-- 1. Inscription : profil, portefeuille et rôle créés automatiquement
select is((select role::text from public.user_roles where user_id = '11111111-1111-1111-1111-111111111111'),
          'joueur', 'un nouveau compte est joueur');
select is((select role::text from public.user_roles where user_id = '22222222-2222-2222-2222-222222222222'),
          'admin', 'un email listé (casse ignorée) devient admin');
select is((select pieces from public.wallets where user_id = '11111111-1111-1111-1111-111111111111'),
          500, 'portefeuille de départ créé');
select isnt((select pseudo from public.profiles where id = '33333333-3333-3333-3333-333333333333'),
            'JoueurTest', 'pseudo en double : suffixe automatique');
select matches((select friend_code from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
               '^[A-HJ-NP-Z2-9]{8}$', 'code ami de 8 caractères sans ambiguïté');

-- 2. Anonyme : aucun accès au contenu ni aux profils
set local role anon;
select throws_ok($$ select count(*) from public.fighters $$, '42501', null, 'anon ne lit pas les combattants');
select throws_ok($$ select count(*) from public.profiles $$, '42501', null, 'anon ne lit pas les profils');
select ok(public.pseudo_disponible('PseudoLibre'), 'anon peut vérifier un pseudo avant inscription');
reset role;

-- 3. Joueur connecté
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);

select ok(not public.is_admin(), 'le joueur n''est pas admin');
select is((select count(*)::int from public.fighters where id = 'test-fighter'), 1, 'le joueur lit le contenu');
select throws_ok($$ insert into public.fighters (id, nom) values ('pirate', 'Pirate') $$,
                 '42501', null, 'le joueur ne crée pas de combattant');
select is_empty($$ update public.fighters set nom = 'Modifié' where id = 'test-fighter' returning id $$,
                'le joueur ne modifie pas un combattant');
select is_empty($$ delete from public.cards where id = 'ed-test:1' returning id $$,
                'le joueur ne supprime pas une carte');
select is_empty($$ update public.variants set tirage = 5000 where id = 'ed-test:BASE:gold' returning id $$,
                'le joueur ne change pas un tirage');

-- Rôles : ni lecture des autres, ni écriture
select is((select count(*)::int from public.user_roles), 1, 'le joueur ne voit que son propre rôle');
select throws_ok($$ update public.user_roles set role = 'admin' where user_id = '11111111-1111-1111-1111-111111111111' $$,
                 '42501', null, 'le joueur ne peut pas se promouvoir admin');
select throws_ok($$ insert into public.user_roles (user_id, role) values ('11111111-1111-1111-1111-111111111111', 'admin') $$,
                 '42501', null, 'le joueur ne peut pas insérer de rôle');
select throws_ok($$ select * from public.admin_emails $$, '42501', null, 'la liste des admins est privée');

-- Profil : mode admin interdit, colonnes protégées, profils des autres intouchables
select throws_ok($$ update public.profiles set admin_mode = true where id = '11111111-1111-1111-1111-111111111111' $$,
                 '42501', null, 'le joueur ne peut pas activer le mode admin');
select throws_ok($$ update public.profiles set friend_code = 'AAAAAAAA' where id = '11111111-1111-1111-1111-111111111111' $$,
                 '42501', null, 'le code ami n''est pas modifiable');
select is_empty($$ update public.profiles set pseudo = 'Usurpateur' where id = '22222222-2222-2222-2222-222222222222' returning id $$,
                'le joueur ne modifie pas le profil d''un autre');
select lives_ok($$ update public.profiles set pseudo = 'NouveauPseudo' where id = '11111111-1111-1111-1111-111111111111' $$,
                'le joueur peut changer son pseudo');

-- Économie et cartes : aucune écriture directe, aucune lecture chez les autres
select throws_ok($$ update public.wallets set pieces = 999999 $$, '42501', null, 'le joueur ne se donne pas de pièces');
select is((select count(*)::int from public.wallets), 1, 'le joueur ne voit que son portefeuille');
select is((select count(*)::int from public.owned_cards), 0, 'le joueur ne voit pas les cartes des autres');
select throws_ok($$ insert into public.owned_cards (owner_id, card_id, variant_id, origine)
                    values ('11111111-1111-1111-1111-111111111111', 'ed-test:1', 'ed-test:BASE:gold', 'admin') $$,
                 '42501', null, 'le joueur ne s''attribue pas de carte');
select throws_ok($$ update public.print_runs set prochain_numero = 1 $$, '42501', null,
                 'le joueur ne touche pas aux compteurs de tirage');

-- Stockage : pas d'upload d'image
select throws_ok($$ insert into storage.objects (bucket_id, name, owner) values ('cartes', 'pirate.webp', '11111111-1111-1111-1111-111111111111') $$,
                 '42501', null, 'le joueur ne dépose pas d''image');
reset role;

-- 4. Admin
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
select lives_ok($$ insert into public.fighters (id, nom) values ('nouveau', 'Nouveau Combattant') $$,
                'l''admin ajoute un combattant');
select lives_ok($$ update public.profiles set admin_mode = true where id = '22222222-2222-2222-2222-222222222222' $$,
                'l''admin active le mode admin');
reset role;

select * from finish();
rollback;
