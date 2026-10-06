-- Cartes Tactique : cartes de départ (une fois), carte Tactique en plus dans
-- les boosters (révélée en premier, hors anti-malchance), Atelier.
begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data) values
  ('7a000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'tactique.a@octogone.local', '{"pseudo":"TactiqueA"}'),
  ('7a000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'tactique.b@octogone.local', '{"pseudo":"TactiqueB"}');

-- Le contenu importé (vraie édition Tactique) est mis de côté pendant le test
update public.editions set deleted = true where type = 'tactique';

-- Sans édition Tactique : rien n'est enregistré, on pourra réessayer
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"7a000000-0000-0000-0000-000000000002","role":"authenticated"}', true);
select throws_ok($$ select * from public.recevoir_tactiques_depart() $$, 'P0003', null,
                 'contenu absent : refus explicite');
reset role;
select is((select tactiques_depart_le from public.profiles where id = '7a000000-0000-0000-0000-000000000002'), null,
          'contenu absent : le droit aux cartes de départ est conservé');

-- Édition Tactique de test : 8 effets, 5 raretés
insert into public.editions (id, nom, annee, type, famille_cadre) values ('tq-ed', 'Tactique', 2099, 'tactique', 'tactique');
insert into public.series (id, edition_id, code, nom, type) values ('tq-ed:BASE', 'tq-ed', 'BASE', 'Tactique', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, tactique)
select 'tq-ed:' || g, 'tq-ed', 'tq-ed:BASE', g::text, g, k, k
  from unnest(array['second_souffle', 'coin_du_coach', 'foule_en_delire', 'machoire_acier', 'instinct_tueur',
                    'sortie_de_crise', 'plan_de_match', 'pression_totale']) with ordinality as t(k, g);
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel) values
  ('tq-ed:BASE:base', 'tq-ed', 'tq-ed:BASE', 'Commune', 'commune', 'base', false),
  ('tq-ed:BASE:peu_commune', 'tq-ed', 'tq-ed:BASE', 'Peu commune', 'peu_commune', 'tactique_peu_commune', false),
  ('tq-ed:BASE:rare', 'tq-ed', 'tq-ed:BASE', 'Rare', 'rare', 'tactique_rare', false),
  ('tq-ed:BASE:epique', 'tq-ed', 'tq-ed:BASE', 'Épique', 'epique', 'tactique_epique', false),
  ('tq-ed:BASE:legendaire', 'tq-ed', 'tq-ed:BASE', 'Légendaire', 'legendaire', 'tactique_legendaire', false);

-- Collection de combattants pour les boosters
insert into public.fighters (id, nom) select 'tq-f' || g, 'Combattant ' || g from generate_series(1, 6) g;
insert into public.editions (id, nom, annee, type, famille_cadre) values ('tqc-ed', 'Test', 2099, 'originale', 'original');
insert into public.series (id, edition_id, code, nom, type) values ('tqc-ed:BASE', 'tqc-ed', 'BASE', 'Base', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, fighter_ids)
select 'tqc-ed:' || g, 'tqc-ed', 'tqc-ed:BASE', g::text, g, 'Carte ' || g, array['tq-f' || g] from generate_series(1, 6) g;
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel) values
  ('tqc-ed:BASE:base', 'tqc-ed', 'tqc-ed:BASE', 'Base', 'commune', 'base', false);
insert into public.booster_types (id, edition_id, nom, type, nb_cartes, prix_pieces, composition) values
  ('tq-std', 'tqc-ed', 'Test', 'standard', 4, 100,
   '{"slots":[{"nb":3,"poids":{"commune":100}}],"tactique":{"nb":1,"edition":"tq-ed","poids":{"legendaire":100}}}');

set local role anon;
select throws_ok($$ select * from public.recevoir_tactiques_depart() $$, '42501', null, 'anon ne reçoit rien');
reset role;

-- Cartes de départ
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"7a000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
create temp table dep as select * from public.recevoir_tactiques_depart();
select is((select count(*)::int from dep), 3, '3 cartes Tactique de départ');
select is((select array_agg(c.tactique order by c.ordre) from dep d join public.cards c on c.id = d.card_id)::text,
          '{second_souffle,coin_du_coach,instinct_tueur}', 'Second souffle, Coin du coach, Instinct de tueur');
select ok((select bool_and(variant_id = 'tq-ed:BASE:base' and origine = 'depart') from dep),
          'Communes, origine « départ »');
select throws_ok($$ select * from public.recevoir_tactiques_depart() $$, 'P0001', null, 'une seule fois par compte');
select throws_ok($$ update public.profiles set tactiques_depart_le = null where id = '7a000000-0000-0000-0000-000000000001' $$,
                 '42501', null, 'le joueur ne remet pas son droit à zéro');
select is((select count(*)::int from public.claim_welcome_pack() w join public.cards c on c.id = w.card_id
            where c.tactique is not null), 0, 'le pack de bienvenue ne renvoie pas les cartes Tactique');

-- Booster : 3 combattants + 1 Tactique, révélée en premier, hors anti-malchance
create temp table b1 as select * from public.open_booster('tq-std');
select is((select count(*)::int from b1), 4, 'booster : 3 combattants + 1 carte Tactique');
select is((select card_id from b1 limit 1) like 'tq-ed:%', true, 'la carte Tactique est révélée en premier');
select is((select count(*)::int from b1 where card_id like 'tq-ed:%' and rarete = 'legendaire'), 1,
          'rareté tirée selon les poids de l''emplacement Tactique');
select is((select depuis_legendaire from public.booster_stats where user_id = '7a000000-0000-0000-0000-000000000001'),
          1, 'une Tactique légendaire ne remet pas l''anti-malchance à zéro');
select ok((select count(*) from public.owned_cards
            where owner_id = '7a000000-0000-0000-0000-000000000001' and card_id like 'tq-ed:%') = 4,
          'cartes Tactique ajoutées à la collection');
reset role;

-- Atelier : fabriquer et recycler une carte Tactique
select public._crediter('7a000000-0000-0000-0000-000000000001', 'admin', 0, 1000);
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"7a000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
select isnt(public.cout_fabrication('tq-ed:BASE:rare'), null, 'une carte Tactique se fabrique');
select is((public.fabriquer('tq-ed:7', 'tq-ed:BASE:rare')).card_id, 'tq-ed:7', 'Plan de match Rare fabriqué');
select lives_ok($$ select public.fabriquer('tq-ed:7', 'tq-ed:BASE:rare') $$, 'doublon fabriqué');
select is((select cartes from public.recycler(array[(select id from public.owned_cards
            where owner_id = '7a000000-0000-0000-0000-000000000001' and variant_id = 'tq-ed:BASE:rare' limit 1)])), 1,
          'doublon Tactique recyclé');
reset role;

select * from finish();
rollback;
