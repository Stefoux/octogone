-- =============================================================================
-- Phase 3 : boosters
--
-- Toute l'ouverture se fait côté serveur, dans UNE transaction (fonction
-- open_booster) : paiement, tirage des raretés, garantie Premium,
-- anti-malchance, choix des cartes éligibles, numérotation globale des
-- tirages limités (verrou sur print_runs + contrainte d'unicité), journal.
-- Fonction Postgres plutôt qu'Edge Function : même garantie (le client ne
-- décide de rien), transaction native, une seule requête réseau.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Réglages de l'économie (une seule ligne, modifiable par un admin)
-- -----------------------------------------------------------------------------
create table public.economy_config (
  id                 boolean primary key default true check (id),
  mode_test          boolean not null default true,        -- ouverture illimitée pendant les tests
  intervalle_gratuit interval not null default '12 hours',  -- un booster gratuit toutes les…
  capacite_gratuite  integer not null default 2 check (capacite_gratuite between 0 and 10),
  pity_legendaire    integer not null default 40 check (pity_legendaire >= 1),
  updated_at         timestamptz not null default now()
);
insert into public.economy_config default values;
alter table public.economy_config enable row level security;
create policy "réglages lisibles" on public.economy_config for select to authenticated using (true);
create policy "réglages modifiables par un admin" on public.economy_config for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
create trigger economy_config_touch before update on public.economy_config
  for each row execute function public.touch_updated_at();

-- -----------------------------------------------------------------------------
-- Types de boosters (contenu synchronisé dans l'app)
-- -----------------------------------------------------------------------------
create table public.booster_types (
  id          text primary key,                       -- '<edition>:<type>'
  edition_id  text not null references public.editions (id) on delete cascade,
  nom         text not null,
  type        text not null check (type in ('standard', 'premium', 'evenement')),
  nb_cartes   integer not null check (nb_cartes between 1 and 20),
  prix_pieces integer not null default 100 check (prix_pieces >= 0),
  en_vedette  boolean not null default false,
  actif       boolean not null default true,
  debut       timestamptz,                            -- boosters Événement : fenêtre de disponibilité
  fin         timestamptz,
  ordre       integer not null default 0,
  visuel      jsonb not null default '{}',
  composition jsonb not null,                         -- {slots: [{nb, poids: {rareté: poids}}], garantie}
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false
);
alter table public.booster_types enable row level security;
create policy "contenu lisible" on public.booster_types for select to authenticated using (true);
create policy "contenu modifiable par un admin (insert)" on public.booster_types for insert to authenticated with check (public.is_admin());
create policy "contenu modifiable par un admin (update)" on public.booster_types for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "contenu modifiable par un admin (delete)" on public.booster_types for delete to authenticated using (public.is_admin());
create trigger booster_types_touch before update on public.booster_types
  for each row execute function public.touch_updated_at();
create index booster_types_updated_idx on public.booster_types (updated_at);

-- -----------------------------------------------------------------------------
-- Compteurs par joueur (recharges gratuites, anti-malchance) et journal
-- -----------------------------------------------------------------------------
create table public.booster_stats (
  user_id           uuid primary key references auth.users (id) on delete cascade,
  ouverts           integer not null default 0,
  depuis_legendaire integer not null default 0,   -- boosters ouverts depuis la dernière légendaire (ou mieux)
  charges           integer not null default 2,   -- boosters gratuits en réserve (à l'instant charges_le)
  charges_le        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
alter table public.booster_stats enable row level security;
create policy "chacun lit ses compteurs" on public.booster_stats for select to authenticated
  using (user_id = (select auth.uid()));

create table public.booster_openings (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  booster_type_id text not null references public.booster_types (id),
  paiement        text not null check (paiement in ('gratuit', 'pieces', 'test')),
  cartes          uuid[] not null,
  pity            boolean not null default false,
  created_at      timestamptz not null default now()
);
create index booster_openings_user_idx on public.booster_openings (user_id, created_at desc);
alter table public.booster_openings enable row level security;
create policy "chacun lit ses ouvertures" on public.booster_openings for select to authenticated
  using (user_id = (select auth.uid()));

grant select on public.economy_config, public.booster_types, public.booster_stats, public.booster_openings to authenticated;
grant update on public.economy_config to authenticated;
grant insert, update, delete on public.booster_types to authenticated;
revoke insert, update, delete on public.booster_stats, public.booster_openings from anon, authenticated;
revoke all on public.economy_config, public.booster_types, public.booster_stats, public.booster_openings from anon;

-- -----------------------------------------------------------------------------
-- Outils
-- -----------------------------------------------------------------------------
create or replace function public.rarity_rank(r text)
returns integer language sql immutable set search_path = '' as $$
  select array_position(array['commune', 'peu_commune', 'rare', 'epique', 'legendaire', 'mythique'], r) - 1;
$$;

-- Miroir de game_core Eligibility.isEligible pour une carte simple.
create or replace function public.fighter_eligible(rule jsonb, p_fighter text)
returns boolean language plpgsql stable set search_path = '' as $$
declare
  f public.fighters;
begin
  if rule is null or rule = '{}'::jsonb then
    return true;
  end if;
  if rule ? 'carte' then
    return false;  -- duel, événement, célébration : pas sur une carte simple
  end if;
  select * into f from public.fighters where id = p_fighter;
  if not found then
    return false;
  end if;
  if (rule ->> 'champion')::boolean is true and not (f.champion_actuel or f.ancien_champion) then
    return false;
  end if;
  if (rule ->> 'legende_retraitee')::boolean is true
     and not (f.statut = 'retraite' and (f.ancien_champion or coalesce((f.ufc ->> 'victoires_ufc')::numeric, 0) >= 10)) then
    return false;
  end if;
  if rule ? 'fotn_min' and coalesce((f.ufc ->> 'bonus_fotn')::numeric, 0) < (rule ->> 'fotn_min')::numeric then
    return false;
  end if;
  if rule ? 'ko_min' and coalesce((f.palmares ->> 'victoires_ko')::numeric, 0) < (rule ->> 'ko_min')::numeric then
    return false;
  end if;
  if rule ? 'sub_min' and coalesce((f.palmares ->> 'victoires_soumission')::numeric, 0) < (rule ->> 'sub_min')::numeric then
    return false;
  end if;
  return true;
end;
$$;

-- Tire une rareté selon des poids relatifs {"commune": 75, "rare": 25}.
create or replace function public.pick_weighted(weights jsonb)
returns text language plpgsql volatile set search_path = '' as $$
declare
  total numeric;
  r numeric;
  k text;
  v numeric;
begin
  select sum(value::numeric) into total from jsonb_each_text(weights);
  if total is null or total <= 0 then
    return null;
  end if;
  r := random() * total;
  for k, v in select key, value::numeric from jsonb_each_text(weights) order by public.rarity_rank(key) loop
    r := r - v;
    if r < 0 then
      return k;
    end if;
  end loop;
  return k;
end;
$$;

-- Raretés tirées pour un booster (garantie incluse, sans anti-malchance).
create or replace function public.draw_tiers(composition jsonb)
returns text[] language plpgsql volatile set search_path = '' as $$
declare
  slot jsonb;
  i integer;
  tiers text[] := '{}';
  best integer;
begin
  for slot in select value from jsonb_array_elements(composition -> 'slots') loop
    for i in 1 .. coalesce((slot ->> 'nb')::integer, 1) loop
      tiers := tiers || public.pick_weighted(slot -> 'poids');
    end loop;
  end loop;
  if composition ->> 'garantie' is not null then
    select max(public.rarity_rank(x)) into best from unnest(tiers) x;
    if best < public.rarity_rank(composition ->> 'garantie') then
      tiers[cardinality(tiers)] := composition ->> 'garantie';
    end if;
  end if;
  return tiers;
end;
$$;

-- Tire UNE carte d'une rareté donnée et l'attribue au joueur.
-- Variante pondérée par son tirage (les /299 sortent plus que les /5),
-- carte éligible (règles des raretés originales), numéro global attribué
-- sous verrou de ligne. Si rien n'est disponible : rareté inférieure.
create or replace function public._draw_card(p_user uuid, p_edition text, p_tier text)
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
     order by random()
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
  return public._draw_card(p_user, p_edition, 'commune');
end;
$$;

-- -----------------------------------------------------------------------------
-- État des boosters gratuits du joueur (sans rien consommer)
-- -----------------------------------------------------------------------------
create or replace function public.booster_status()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
  cfg public.economy_config;
  st public.booster_stats;
  regen integer;
  charges integer;
  ref_time timestamptz;
  step numeric;
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  select * into cfg from public.economy_config where id;
  select * into st from public.booster_stats where user_id = uid;
  step := extract(epoch from cfg.intervalle_gratuit);
  if not found then
    charges := cfg.capacite_gratuite;
    ref_time := now();
  else
    regen := greatest(0, floor(extract(epoch from (now() - st.charges_le)) / step)::integer);
    charges := least(cfg.capacite_gratuite, st.charges + regen);
    ref_time := st.charges_le + regen * cfg.intervalle_gratuit;
  end if;
  return jsonb_build_object(
    'mode_test', cfg.mode_test,
    'charges', charges,
    'capacite', cfg.capacite_gratuite,
    'intervalle_s', step,
    'prochain_dans_s', case when charges >= cfg.capacite_gratuite then null
                            else greatest(0, step - extract(epoch from (now() - ref_time))) end,
    'pity_legendaire', cfg.pity_legendaire,
    'depuis_legendaire', coalesce(st.depuis_legendaire, 0),
    'ouverts', coalesce(st.ouverts, 0)
  );
end;
$$;

-- -----------------------------------------------------------------------------
-- Ouverture d'un booster
--   p_paiement : 'gratuit' (recharge gratuite, boosters Standard) ou 'pieces'.
--   En mode test, tout est gratuit et illimité.
-- Renvoie les cartes dans l'ordre de révélation : les plus rares à la fin.
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
    o := public._draw_card(uid, bt.edition_id, tiers[i]);
    ids := ids || o.id;
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

  return query
    select oc.id, oc.card_id, oc.variant_id, v.rarete, oc.numero_serie, oc.tirage,
           not exists (select 1 from public.owned_cards o2
                        where o2.owner_id = uid and o2.card_id = oc.card_id and not (o2.id = any(ids)))
      from public.owned_cards oc join public.variants v on v.id = oc.variant_id
     where oc.id = any(ids)
     order by public.rarity_rank(v.rarete), (oc.numero_serie is not null), oc.tirage desc nulls first, oc.id;
end;
$$;

-- -----------------------------------------------------------------------------
-- Simulation (tests d'équilibrage) : raretés de N boosters, sans rien attribuer.
-- Réservé au service (scripts de test), pas aux joueurs.
-- -----------------------------------------------------------------------------
create or replace function public.simulate_booster_tiers(p_type text, p_n integer)
returns table (rarete text, cartes bigint, boosters_avec bigint)
language plpgsql volatile security definer set search_path = '' as $$
declare
  comp jsonb;
begin
  select composition into comp from public.booster_types where id = p_type;
  return query
    with packs as (
      select g as n, public.draw_tiers(comp) as t from generate_series(1, p_n) g
    ), flat as (
      select n, unnest(t) as r from packs
    )
    select f.r, count(*), count(distinct f.n) from flat f group by f.r
    order by public.rarity_rank(f.r);
end;
$$;

revoke all on function public._draw_card(uuid, text, text) from public, anon, authenticated;
revoke all on function public.pick_weighted(jsonb) from public, anon, authenticated;
revoke all on function public.draw_tiers(jsonb) from public, anon, authenticated;
revoke all on function public.simulate_booster_tiers(text, integer) from public, anon, authenticated;
revoke all on function public.fighter_eligible(jsonb, text) from public, anon, authenticated;
revoke all on function public.open_booster(text, text) from public, anon;
revoke all on function public.booster_status() from public, anon;
grant execute on function public.open_booster(text, text) to authenticated;
grant execute on function public.booster_status() to authenticated;
