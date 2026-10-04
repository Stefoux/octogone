-- Boosters : composition, ordre de révélation, garantie, anti-malchance,
-- numérotation globale, éligibilité, recharges gratuites, pièces, sécurité.
begin;
create extension if not exists pgtap with schema extensions;
select plan(26);

insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data)
values ('55555555-5555-5555-5555-555555555555', '00000000-0000-0000-0000-000000000000', 'authenticated',
        'authenticated', 'booster.test@octogone.local', '{"pseudo":"BoosterTest"}');

-- Collection de test : 10 combattants (1 champion), 10 cartes, une variante par rareté.
insert into public.fighters (id, nom, champion_actuel) select 'bt-f' || g, 'Combattant ' || g, g = 1 from generate_series(1, 10) g;
insert into public.editions (id, nom, annee, type, famille_cadre) values ('bt-ed', 'Test', 2099, 'originale', 'original');
insert into public.series (id, edition_id, code, nom, type) values ('bt-ed:BASE', 'bt-ed', 'BASE', 'Base', 'base');
insert into public.cards (id, edition_id, series_id, numero, ordre, nom_imprime, fighter_ids)
select 'bt-ed:' || g, 'bt-ed', 'bt-ed:BASE', g::text, g, 'Carte ' || g, array['bt-f' || g] from generate_series(1, 10) g;
insert into public.variants (id, edition_id, series_id, nom, rarete, effet, reel, tirage, eligibilite) values
  ('bt-ed:BASE:base', 'bt-ed', 'bt-ed:BASE', 'Base', 'commune', 'base', false, null, null),
  ('bt-ed:BASE:acier', 'bt-ed', 'bt-ed:BASE', 'Acier', 'peu_commune', 'acier', false, null, '{}'),
  ('bt-ed:BASE:neon', 'bt-ed', 'bt-ed:BASE', 'Néon', 'rare', 'neon', false, null, '{}'),
  ('bt-ed:BASE:ceinture', 'bt-ed', 'bt-ed:BASE', 'Ceinture', 'legendaire', 'ceinture_or', false, null, '{"champion": true}'),
  ('bt-ed:BASE:noir', 'bt-ed', 'bt-ed:BASE', 'Noir', 'mythique', 'octogone_noir', false, 2, '{}');
insert into public.booster_types (id, edition_id, nom, type, nb_cartes, prix_pieces, composition) values
  ('bt-std', 'bt-ed', 'Test', 'standard', 6, 100,
   '{"slots":[{"nb":4,"poids":{"commune":100}},{"nb":1,"poids":{"peu_commune":100}},{"nb":1,"poids":{"rare":100}}]}'),
  ('bt-prem', 'bt-ed', 'Test', 'premium', 3, 250,
   '{"slots":[{"nb":3,"poids":{"commune":100}}],"garantie":"rare"}'),
  ('bt-leg', 'bt-ed', 'Test', 'premium', 3, 0,
   '{"slots":[{"nb":3,"poids":{"legendaire":100}}]}'),
  ('bt-myth', 'bt-ed', 'Test', 'premium', 3, 0,
   '{"slots":[{"nb":3,"poids":{"mythique":100}}]}'),
  ('bt-off', 'bt-ed', 'Test', 'standard', 1, 0, '{"slots":[{"nb":1,"poids":{"commune":100}}]}');
update public.booster_types set actif = false where id = 'bt-off';

-- Anonyme et fonctions internes
set local role anon;
select throws_ok($$ select * from public.open_booster('bt-std') $$, '42501', null, 'anon ne peut pas ouvrir de booster');
reset role;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}', true);

select throws_ok($$ select public._draw_card('55555555-5555-5555-5555-555555555555', 'bt-ed', 'mythique') $$,
                 '42501', null, 'le joueur ne peut pas tirer une carte directement');
select throws_ok($$ select * from public.simulate_booster_tiers('bt-std', 10) $$, '42501', null,
                 'la simulation est réservée aux scripts');
select throws_ok($$ update public.booster_stats set depuis_legendaire = 39 $$, '42501', null,
                 'le joueur ne modifie pas son compteur anti-malchance');
select is_empty($$ update public.economy_config set mode_test = false returning id $$,
                'le joueur ne modifie pas les réglages');
select throws_ok($$ select * from public.open_booster('bt-off') $$, 'P0003', null, 'booster désactivé refusé');

-- Booster standard : 6 cartes, ordre de révélation, cartes « nouvelles »
create temp table b1 as select * from public.open_booster('bt-std');
select is((select count(*)::int from b1), 6, 'booster standard : 6 cartes');
select is((select array_agg(rarete) from b1)::text,
          '{commune,commune,commune,commune,peu_commune,rare}', 'les plus rares sont révélées en dernier');
select ok((select bool_and(nouvelle) from b1 where card_id not in (select card_id from b1 group by card_id having count(*) > 1)),
          'premières cartes marquées nouvelles');
select is((select count(*)::int from public.owned_cards where owner_id = '55555555-5555-5555-5555-555555555555'),
          6, 'cartes ajoutées à la collection');
select is((select paiement from public.booster_openings where cartes @> array[(select owned_id from b1 limit 1)]),
          'test', 'mode test : gratuit');

-- Garantie Premium
create temp table b2 as select * from public.open_booster('bt-prem');
select ok((select max(public.rarity_rank(rarete)) from b2) >= public.rarity_rank('rare'), 'Premium : au moins une rare');

-- Éligibilité : la Ceinture d'Or ne sort que sur le champion (bt-f1)
create temp table b3 as select * from public.open_booster('bt-leg');
select is((select count(*)::int from b3 where variant_id = 'bt-ed:BASE:ceinture' and card_id <> 'bt-ed:1'), 0,
          'Ceinture d''Or réservée aux champions');

-- Numérotation globale : Octogone Noir /2 par carte, jamais plus
create temp table myth as select * from public.open_booster('bt-myth');
insert into myth select * from public.open_booster('bt-myth');
insert into myth select * from public.open_booster('bt-myth');
insert into myth select * from public.open_booster('bt-myth');
insert into myth select * from public.open_booster('bt-myth');
insert into myth select * from public.open_booster('bt-myth');
insert into myth select * from public.open_booster('bt-myth');
select is((select count(*)::int from (select card_id, numero_serie from myth where numero_serie is not null
                                      group by 1, 2 having count(*) > 1) d), 0, 'aucun numéro attribué deux fois');
select ok((select coalesce(max(numero_serie), 0) from myth) <= 2, 'jamais au-delà du tirage (/2)');
select ok((select count(*) from myth where variant_id = 'bt-ed:BASE:noir') <= 20, '10 cartes × /2 = 20 exemplaires au plus');
reset role;
select is((select count(*)::int from public.owned_cards where variant_id = 'bt-ed:BASE:noir'),
          (select count(*)::int from myth where variant_id = 'bt-ed:BASE:noir'), 'compteurs cohérents');

-- Anti-malchance : seuil à 3 boosters sans légendaire
update public.economy_config set pity_legendaire = 3;
update public.booster_stats set depuis_legendaire = 0 where user_id = '55555555-5555-5555-5555-555555555555';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}', true);
create temp table p1 as select * from public.open_booster('bt-std');
create temp table p2 as select * from public.open_booster('bt-std');
create temp table p3 as select * from public.open_booster('bt-std');
select is((select count(*)::int from p1 where rarete = 'legendaire') + (select count(*)::int from p2 where rarete = 'legendaire'),
          0, 'pas de légendaire avant le seuil');
select is((select rarete from p3 order by public.rarity_rank(rarete) desc limit 1), 'legendaire',
          'anti-malchance : légendaire garantie au 3e booster');
select ok((select pity from public.booster_openings where cartes @> array[(select owned_id from p3 limit 1)]),
          'ouverture marquée « anti-malchance »');
reset role;

-- Recharges gratuites (mode test désactivé) : 2 en réserve, puis une toutes les 12 h
update public.economy_config set mode_test = false, pity_legendaire = 40, capacite_gratuite = 2, intervalle_gratuit = '12 hours';
update public.booster_stats set charges = 2, charges_le = now() where user_id = '55555555-5555-5555-5555-555555555555';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}', true);
select lives_ok($$ select * from public.open_booster('bt-std', 'gratuit') $$, '1er booster gratuit');
select lives_ok($$ select * from public.open_booster('bt-std', 'gratuit') $$, '2e booster gratuit');
select throws_ok($$ select * from public.open_booster('bt-std', 'gratuit') $$, 'P0002', null, 'réserve vide : refusé');
reset role;
update public.booster_stats set charges_le = now() - interval '12 hours 1 minute'
 where user_id = '55555555-5555-5555-5555-555555555555';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}', true);
select is((public.booster_status() ->> 'charges')::int, 1, '12 h plus tard : une recharge');

-- Pièces : 500 au départ, Premium à 250
select lives_ok($$ select * from public.open_booster('bt-prem', 'pieces') $$, 'Premium payé en pièces');
select is((select pieces from public.wallets), 250, '250 pièces débitées');
reset role;

select * from finish();
rollback;
