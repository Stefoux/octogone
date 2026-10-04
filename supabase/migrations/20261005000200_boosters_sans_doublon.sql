-- Boosters : pas deux fois la même carte dans un même booster (tant que la
-- collection le permet) et « nouvelle » affichée sur un seul exemplaire.

drop function if exists public._draw_card(uuid, text, text);

-- Tire UNE carte d'une rareté donnée et l'attribue au joueur (voir
-- 20261005000100_boosters.sql). p_exclude : cartes déjà sorties dans ce booster.
create or replace function public._draw_card(p_user uuid, p_edition text, p_tier text, p_exclude text[] default '{}')
returns public.owned_cards language plpgsql volatile set search_path = '' as $$
declare
  tiers constant text[] := array['commune', 'peu_commune', 'rare', 'epique', 'legendaire', 'mythique'];
  tier text := p_tier;
  v public.variants;
  c_id text;
  serial integer;
  result public.owned_cards;
  attempt integer := 0;
begin
  while attempt < 25 loop
    attempt := attempt + 1;
    select * into v from public.variants
     where edition_id = p_edition and rarete = tier and not deleted
       and not (coalesce(eligibilite, '{}'::jsonb) ? 'carte')
     order by -ln(1 - random()) / coalesce(tirage, 500)::numeric
     limit 1;
    if not found then
      if tier = 'commune' then
        raise exception 'Collection sans carte : %', p_edition;
      end if;
      tier := tiers[array_position(tiers, tier) - 1];
      continue;
    end if;

    select c.id into c_id from public.cards c
     where c.series_id = v.series_id and not c.deleted
       and (cardinality(c.fighter_ids) = 0 or public.fighter_eligible(v.eligibilite, c.fighter_ids[1]))
       and (v.tirage is null or not exists (
             select 1 from public.print_runs pr
              where pr.card_id = c.id and pr.variant_id = v.id and pr.prochain_numero > pr.tirage))
     order by (c.id = any(p_exclude)), random()  -- pas de doublon dans un même booster si possible
     limit 1;
    if c_id is null then
      if attempt % 5 = 0 and tier <> 'commune' then
        tier := tiers[array_position(tiers, tier) - 1];
      end if;
      continue;
    end if;

    serial := null;
    if v.tirage is not null then
      insert into public.print_runs (card_id, variant_id, tirage) values (c_id, v.id, v.tirage)
      on conflict do nothing;
      update public.print_runs set prochain_numero = prochain_numero + 1
       where card_id = c_id and variant_id = v.id and prochain_numero <= tirage
       returning prochain_numero - 1 into serial;
      if serial is null then
        continue;  -- épuisé par une ouverture concurrente : on retire
      end if;
    end if;

    insert into public.owned_cards (owner_id, card_id, variant_id, numero_serie, tirage, origine)
    values (p_user, c_id, v.id, serial, case when serial is null then null else v.tirage end, 'booster')
    returning * into result;
    return result;
  end loop;
  return public._draw_card(p_user, p_edition, 'commune', p_exclude);
end;
$$;

revoke all on function public._draw_card(uuid, text, text, text[]) from public, anon, authenticated;

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
  cids text[] := '{}';
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
    update public.wallets w set pieces = w.pieces - bt.prix_pieces
     where w.user_id = uid and w.pieces >= bt.prix_pieces;
    if not found then
      raise exception 'Pas assez de pièces' using errcode = 'P0004';
    end if;
    paid := 'pieces';
  end if;

  -- 2. Raretés (garantie Premium incluse), puis anti-malchance
  tiers := public.draw_tiers(bt.composition);
  select max(public.rarity_rank(x)) into best from unnest(tiers) x;
  if st.depuis_legendaire + 1 >= cfg.pity_legendaire and best < public.rarity_rank('legendaire') then
    tiers[cardinality(tiers)] := 'legendaire';
    pity := true;
  end if;

  -- 3. Cartes
  for i in 1 .. cardinality(tiers) loop
    o := public._draw_card(uid, bt.edition_id, tiers[i], cids);
    ids := ids || o.id;
    cids := cids || o.card_id;
  end loop;

  -- 4. Compteurs et journal
  select max(public.rarity_rank(v.rarete)) into best
    from public.owned_cards oc join public.variants v on v.id = oc.variant_id
   where oc.id = any(ids);
  update public.booster_stats s set
    ouverts = s.ouverts + 1,
    depuis_legendaire = case when best >= public.rarity_rank('legendaire') then 0 else s.depuis_legendaire + 1 end,
    charges = st.charges,
    charges_le = st.charges_le,
    updated_at = now()
   where s.user_id = uid;
  insert into public.booster_openings (user_id, booster_type_id, paiement, cartes, pity)
  values (uid, bt.id, paid, ids, pity);

  -- « nouvelle » : carte jamais possédée avant ce booster, sur son premier
  -- exemplaire révélé seulement
  return query
    with r as (
      select oc.id as oid, oc.card_id as cid, oc.variant_id as vid, v.rarete as rar,
             oc.numero_serie as num, oc.tirage as tir,
             row_number() over (order by public.rarity_rank(v.rarete), (oc.numero_serie is not null),
                                         oc.tirage desc nulls first, oc.id) as pos
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
