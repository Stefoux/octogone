-- Pack de bienvenue : 15 cartes non numérotées, une seule fois, impossible à contourner.
begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data)
values ('44444444-4444-4444-4444-444444444444', '00000000-0000-0000-0000-000000000000', 'authenticated',
        'authenticated', 'pack.test@octogone.local', '{"pseudo":"PackTest"}');

-- Contenu de test plus récent que tout le reste (année 2099) pour être choisi.
insert into public.editions (id, nom, annee, type, famille_cadre) values
  ('t-saison', 'Saison test', 2099, 'originale', 'original'),
  ('t-reelle', 'Réelle test', 2099, 'reelle', 'chrome');
insert into public.series (id, edition_id, code, nom, type) values
  ('t-saison:BASE', 't-saison', 'BASE', 'Base', 'base'),
  ('t-reelle:BASE', 't-reelle', 'BASE', 'Base', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime)
select 't-saison:' || g, 't-saison', 't-saison:BASE', g::text, g, 'Saison ' || g from generate_series(1, 20) g;
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime)
select 't-reelle:' || g, 't-reelle', 't-reelle:BASE', g::text, g, 'Réelle ' || g from generate_series(1, 20) g;
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel, tirage) values
  ('t-saison:BASE:base', 't-saison', 't-saison:BASE', 'Base', 'commune', 'base', false, null),
  ('t-saison:BASE:acier', 't-saison', 't-saison:BASE', 'Acier', 'peu_commune', 'acier', false, null),
  ('t-saison:BASE:neon', 't-saison', 't-saison:BASE', 'Néon', 'rare', 'neon', false, null),
  ('t-saison:BASE:octogone_noir', 't-saison', 't-saison:BASE', 'Octogone Noir', 'mythique', 'octogone_noir', false, 1),
  ('t-reelle:BASE:base', 't-reelle', 't-reelle:BASE', 'Base', 'commune', 'base', true, null),
  ('t-reelle:BASE:refractor', 't-reelle', 't-reelle:BASE', 'Refractor', 'peu_commune', 'refractor', true, null),
  ('t-reelle:BASE:gold-refractor', 't-reelle', 't-reelle:BASE', 'Gold Refractor', 'epique', 'refractor', true, 50);

-- Anonyme : refusé
set local role anon;
select throws_ok($$ select * from public.claim_welcome_pack() $$, '42501', null, 'anon ne peut pas réclamer de pack');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}', true);

select throws_ok($$ update public.profiles set pack_bienvenue_le = now() where id = '44444444-4444-4444-4444-444444444444' $$,
                 '42501', null, 'le joueur ne peut pas marquer son pack comme reçu lui-même');

create temp table pack as select * from public.claim_welcome_pack();
select is((select count(*)::int from pack), 15, 'le pack contient 15 cartes');
select is((select count(*)::int from pack where origine <> 'depart'), 0, 'origine « depart »');
select is((select count(*)::int from pack where numero_serie is not null), 0, 'aucune carte numérotée');
select is((select count(*)::int from pack p join public.variants v on v.id = p.variant_id where v.rarete = 'commune'),
          11, '11 communes');
select is((select count(*)::int from pack p join public.variants v on v.id = p.variant_id where v.rarete = 'peu_commune'),
          2, '2 peu communes');
select is((select count(*)::int from pack p join public.variants v on v.id = p.variant_id where v.rarete = 'rare'),
          2, '2 rares');
select throws_ok($$ select * from public.claim_welcome_pack() $$, 'P0001', 'Pack de bienvenue déjà reçu',
                 'un second pack est refusé');
select is((select count(*)::int from public.owned_cards), 15, 'le joueur voit ses 15 cartes et rien de plus');
reset role;

select * from finish();
rollback;
