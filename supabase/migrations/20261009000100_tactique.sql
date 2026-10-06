-- =============================================================================
-- Phase 4 : cartes Tactique
--
-- Bonus de combat (2 au plus par combat, une fois chacune), créations
-- originales : une édition à part (type « tactique »), 8 cartes (une par
-- effet) en 5 raretés (Commune → Légendaire). La carte reste dans la
-- collection après le combat.
--   - 1 carte Tactique en plus dans chaque booster (composition.tactique) ;
--   - 3 cartes de départ pour chaque joueur (comptes existants compris),
--     reçues une fois avec recevoir_tactiques_depart() ;
--   - fabricables et recyclables à l'Atelier comme les autres cartes.
-- =============================================================================

alter table public.editions drop constraint if exists editions_type_check;
alter table public.editions add constraint editions_type_check
  check (type in ('reelle', 'originale', 'evenement', 'tactique'));

-- Effet d'une carte Tactique (clé de game_core TacticKind), null pour une carte de combattant.
alter table public.cards add column if not exists tactique text;

alter table public.profiles add column if not exists tactiques_depart_le timestamptz;
-- (colonne absente des droits UPDATE du client : seul le serveur la renseigne)

-- -----------------------------------------------------------------------------
-- Cartes Tactique de départ : Second souffle, Coin du coach, Instinct de tueur
-- (Communes), une seule fois par compte.
-- -----------------------------------------------------------------------------
create or replace function public.recevoir_tactiques_depart()
returns setof public.owned_cards
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
  ids uuid[];
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  -- Verrou logique : la ligne du profil n'est mise à jour qu'une fois.
  update public.profiles set tactiques_depart_le = now()
   where id = uid and tactiques_depart_le is null;
  if not found then
    raise exception 'Cartes Tactique de départ déjà reçues' using errcode = 'P0001';
  end if;

  with ins as (
    insert into public.owned_cards (owner_id, card_id, variant_id, origine)
    select uid, c.id, c.series_id || ':base', 'depart'
      from public.cards c join public.editions e on e.id = c.edition_id
     where e.type = 'tactique' and not e.deleted and not c.deleted
       and c.tactique = any (array['second_souffle', 'coin_du_coach', 'instinct_tueur'])
       and exists (select 1 from public.variants v where v.id = c.series_id || ':base' and not v.deleted)
    returning id
  )
  select array_agg(id) into ids from ins;
  if coalesce(cardinality(ids), 0) = 0 then
    -- Contenu pas encore importé : rien n'est enregistré, le joueur réessaiera
    raise exception 'Cartes Tactique indisponibles' using errcode = 'P0003';
  end if;

  return query
    select o.* from public.owned_cards o join public.cards c on c.id = o.card_id
     where o.id = any (ids)
     order by c.ordre;
end;
$$;
revoke all on function public.recevoir_tactiques_depart() from public, anon;
grant execute on function public.recevoir_tactiques_depart() to authenticated;

-- -----------------------------------------------------------------------------
-- Pack de bienvenue : ne renvoie que ses propres cartes (pas les Tactique de
-- départ, qui ont aussi l'origine « depart »).
-- -----------------------------------------------------------------------------
create or replace function public.claim_welcome_pack()
returns setof public.owned_cards
language plpgsql security definer
set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
  saison text;
  base_reelle text;
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;

  -- Verrou logique : la ligne du profil n'est mise à jour qu'une fois.
  update public.profiles set pack_bienvenue_le = now()
   where id = uid and pack_bienvenue_le is null;
  if not found then
    raise exception 'Pack de bienvenue déjà reçu' using errcode = 'P0001';
  end if;

  select s.id into saison
    from public.series s join public.editions e on e.id = s.edition_id
   where e.type = 'originale' and s.type = 'base' and not e.deleted and not s.deleted
   order by e.annee desc limit 1;
  select s.id into base_reelle
    from public.series s join public.editions e on e.id = s.edition_id
   where e.type = 'reelle' and s.type = 'base' and not e.deleted and not s.deleted
   order by e.annee desc limit 1;

  insert into public.owned_cards (owner_id, card_id, variant_id, origine)
  select uid, ch.card_id, ch.variant_id, 'depart'
    from (
      (select c.id as card_id, saison || ':base' as variant_id
         from public.cards c where c.series_id = saison and not c.deleted
        order by random() limit 7)
      union all
      (select c.id, base_reelle || ':base'
         from public.cards c where c.series_id = base_reelle and not c.deleted
        order by random() limit 4)
      union all
      (select pc.card_id, pc.variant_id from (
          select c.id as card_id, saison || ':acier' as variant_id
            from public.cards c where c.series_id = saison and not c.deleted
          union all
          select c.id, base_reelle || ':refractor'
            from public.cards c where c.series_id = base_reelle and not c.deleted
        ) pc order by random() limit 2)
      union all
      (select c.id, saison || ':neon'
         from public.cards c where c.series_id = saison and not c.deleted
        order by random() limit 2)
    ) ch
   where exists (
     select 1 from public.variants v
      where v.id = ch.variant_id and v.tirage is null and not v.deleted
   );

  return query
    select o.* from public.owned_cards o join public.cards c on c.id = o.card_id
     where o.owner_id = uid and o.origine = 'depart' and c.tactique is null
     order by o.obtenue_le, o.id;
end;
$$;
revoke all on function public.claim_welcome_pack() from public, anon;
grant execute on function public.claim_welcome_pack() to authenticated;

-- -----------------------------------------------------------------------------
-- Ouverture de booster : + composition.tactique = {nb, edition, poids}, tiré
-- après les cartes de combattants. La garantie Premium et l'anti-malchance ne
-- portent que sur les cartes de combattants.
-- -----------------------------------------------------------------------------
create or replace function public.open_booster(p_type text, p_paiement text default 'gratuit')
returns table (owned_id uuid, card_id text, variant_id text, rarete text,
               numero_serie integer, tirage integer, nouvelle boolean)
language plpgsql volatile security definer set search_path = '' as $$
#variable_conflict use_column
declare
  uid uuid := (select auth.uid());
  bt public.booster_types;
  cfg public.economy_config;
  st public.booster_stats;
  tiers text[];
  best integer;
  regen integer;
  paid text;
  pity boolean := false;
  o public.owned_cards;
  ids uuid[] := '{}';
  tids uuid[] := '{}';
  cids text[] := '{}';
  tac jsonb;
  i integer;
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  select * into bt from public.booster_types b
   where b.id = p_type and b.actif and not b.deleted
     and (b.debut is null or b.debut <= now()) and (b.fin is null or b.fin > now());
  if not found then
    raise exception 'Booster indisponible' using errcode = 'P0003';
  end if;
  select * into cfg from public.economy_config where id;

  insert into public.booster_stats (user_id, charges, charges_le)
  values (uid, cfg.capacite_gratuite, now()) on conflict do nothing;
  select * into st from public.booster_stats s where s.user_id = uid for update;  -- un booster à la fois par joueur

  -- 1. Paiement
  if cfg.mode_test then
    paid := 'test';
  elsif p_paiement = 'gratuit' and bt.type = 'standard' then
    regen := greatest(0, floor(extract(epoch from (now() - st.charges_le)) / extract(epoch from cfg.intervalle_gratuit))::integer);
    st.charges := least(cfg.capacite_gratuite, st.charges + regen);
    if st.charges >= cfg.capacite_gratuite then
      st.charges_le := now();  -- réserve pleine : le compte à rebours repart de maintenant
    else
      st.charges_le := st.charges_le + regen * cfg.intervalle_gratuit;
    end if;
    if st.charges < 1 then
      raise exception 'Aucun booster gratuit disponible' using errcode = 'P0002';
    end if;
    st.charges := st.charges - 1;
    paid := 'gratuit';
  else
    perform public._crediter(uid, 'booster', -bt.prix_pieces, 0, bt.id);  -- P0004 si pas assez
    paid := 'pieces';
  end if;

  -- 2. Raretés (garantie Premium incluse), puis anti-malchance
  tiers := public.draw_tiers(bt.composition);
  select max(public.rarity_rank(x)) into best from unnest(tiers) x;
  if st.depuis_legendaire + 1 >= cfg.pity_legendaire and best < public.rarity_rank('legendaire') then
    tiers[cardinality(tiers)] := 'legendaire';
    pity := true;
  end if;

  -- 3. Cartes de combattants, puis carte(s) Tactique
  for i in 1 .. cardinality(tiers) loop
    o := public._draw_card(uid, bt.edition_id, tiers[i], cids);
    ids := ids || o.id;
    cids := cids || o.card_id;
  end loop;
  tac := bt.composition -> 'tactique';
  if tac is not null and tac ->> 'edition' is not null
     and exists (select 1 from public.editions e where e.id = tac ->> 'edition' and not e.deleted) then
    for i in 1 .. coalesce((tac ->> 'nb')::integer, 1) loop
      o := public._draw_card(uid, tac ->> 'edition', coalesce(public.pick_weighted(tac -> 'poids'), 'commune'), cids);
      ids := ids || o.id;
      tids := tids || o.id;
      cids := cids || o.card_id;
    end loop;
  end if;

  -- 4. Compteurs et journal
  select max(public.rarity_rank(v.rarete)) into best
    from public.owned_cards oc join public.variants v on v.id = oc.variant_id
   where oc.id = any(ids) and not (oc.id = any(tids));
  update public.booster_stats s set
    ouverts = s.ouverts + 1,
    depuis_legendaire = case when best >= public.rarity_rank('legendaire') then 0 else s.depuis_legendaire + 1 end,
    charges = st.charges,
    charges_le = st.charges_le,
    updated_at = now()
   where s.user_id = uid;
  insert into public.booster_openings (user_id, booster_type_id, paiement, cartes, pity)
  values (uid, bt.id, paid, ids, pity);

  -- 5. Défis : booster ouvert, raretés révélées, cartes nouvelles
  perform public._evenement(uid, 'ouvrir_booster', 1);
  if bt.type = 'premium' then
    perform public._evenement(uid, 'ouvrir_premium', 1);
  end if;
  perform public._evenement(uid, 'reveler_rare',
    (select count(*)::integer from public.owned_cards oc join public.variants v on v.id = oc.variant_id
      where oc.id = any(ids) and public.rarity_rank(v.rarete) >= public.rarity_rank('rare')));
  perform public._evenement(uid, 'reveler_epique',
    (select count(*)::integer from public.owned_cards oc join public.variants v on v.id = oc.variant_id
      where oc.id = any(ids) and public.rarity_rank(v.rarete) >= public.rarity_rank('epique')));
  perform public._evenement(uid, 'nouvelle_carte',
    (select count(distinct oc.card_id)::integer from public.owned_cards oc
      where oc.id = any(ids)
        and not exists (select 1 from public.owned_cards o2
                         where o2.owner_id = uid and o2.card_id = oc.card_id and not (o2.id = any(ids)))));

  -- « nouvelle » : carte jamais possédée avant ce booster, sur son premier
  -- exemplaire révélé seulement. La carte Tactique est révélée en premier.
  return query
    with r as (
      select oc.id as oid, oc.card_id as cid, oc.variant_id as vid, v.rarete as rar,
             oc.numero_serie as num, oc.tirage as tir,
             row_number() over (order by (oc.id = any(tids)) desc, public.rarity_rank(v.rarete),
                                         (oc.numero_serie is not null), oc.tirage desc nulls first, oc.id) as pos
        from public.owned_cards oc join public.variants v on v.id = oc.variant_id
       where oc.id = any(ids)
    ), r2 as (
      select r.*, row_number() over (partition by r.cid order by r.pos) as occ from r
    )
    select r2.oid, r2.cid, r2.vid, r2.rar, r2.num, r2.tir,
           r2.occ = 1 and not exists (select 1 from public.owned_cards o2
                                       where o2.owner_id = uid and o2.card_id = r2.cid and not (o2.id = any(ids)))
      from r2
     order by r2.pos;
end;
$$;
revoke all on function public.open_booster(text, text) from public, anon;
grant execute on function public.open_booster(text, text) to authenticated;
