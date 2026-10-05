-- Défis quotidiens et hebdomadaires. Chaque joueur reçoit chaque jour
-- nb_defis_jour défis et chaque lundi nb_defis_semaine défis, tirés parmi les
-- modèles actifs (un par type, ordre propre au joueur). La progression est
-- comptée par les fonctions serveur via _evenement ; la récompense se
-- récupère avec recuperer_defi. Périodes à l'heure de Paris.

create table public.defi_modeles (
  id         text primary key,
  periode    text not null check (periode in ('jour', 'semaine')),
  type       text not null,
  objectif   integer not null check (objectif > 0),
  pieces     integer not null check (pieces >= 0),
  libelle    jsonb not null,
  actif      boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.defi_modeles enable row level security;
create policy "défis lisibles" on public.defi_modeles for select to authenticated using (true);
create policy "défis modifiables par un admin (insert)" on public.defi_modeles for insert to authenticated with check (public.is_admin());
create policy "défis modifiables par un admin (update)" on public.defi_modeles for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
revoke all on public.defi_modeles from anon;
grant select, insert, update on public.defi_modeles to authenticated;

create table public.defis_joueur (
  user_id     uuid not null references auth.users (id) on delete cascade,
  modele_id   text not null references public.defi_modeles (id) on delete cascade,
  debut       date not null,
  progression integer not null default 0,
  recupere_le timestamptz,
  primary key (user_id, modele_id, debut)
);
alter table public.defis_joueur enable row level security;
create policy "chacun lit ses défis" on public.defis_joueur for select to authenticated using (user_id = (select auth.uid()));
revoke all on public.defis_joueur from anon;
revoke insert, update, delete on public.defis_joueur from authenticated;
grant select on public.defis_joueur to authenticated;

alter table public.economy_config
  add column nb_defis_jour integer not null default 4,
  add column nb_defis_semaine integer not null default 3;

-- Début de la période en cours (jour ou semaine commençant le lundi), heure de Paris.
create or replace function public._debut_periode(p_periode text)
returns date language sql stable set search_path = '' as $$
  select case p_periode
           when 'jour' then (now() at time zone 'Europe/Paris')::date
           else date_trunc('week', now() at time zone 'Europe/Paris')::date
         end;
$$;

-- Attribue au joueur ses défis de la période s'il ne les a pas encore.
create or replace function public._assurer_defis(p_user uuid)
returns void
language plpgsql volatile security definer set search_path = '' as $$
declare
  cfg public.economy_config;
  per text;
  d date;
  n integer;
begin
  select * into cfg from public.economy_config where id;
  foreach per in array array['jour', 'semaine'] loop
    d := public._debut_periode(per);
    n := case per when 'jour' then cfg.nb_defis_jour else cfg.nb_defis_semaine end;
    if not exists (select 1 from public.defis_joueur dj join public.defi_modeles m on m.id = dj.modele_id
                    where dj.user_id = p_user and dj.debut = d and m.periode = per) then
      insert into public.defis_joueur (user_id, modele_id, debut)
      select p_user, x.id, d
        from (select distinct on (m.type) m.id, m.type
                from public.defi_modeles m
               where m.periode = per and m.actif
               order by m.type, md5(p_user::text || d::text || m.id)) x
       order by md5(p_user::text || d::text || x.type)
       limit n
      on conflict do nothing;
    end if;
  end loop;
end;
$$;
revoke all on function public._assurer_defis(uuid) from public, anon, authenticated;

-- Événement de jeu : fait progresser les défis en cours du type donné.
create or replace function public._evenement(p_user uuid, p_type text, p_quantite integer default 1)
returns void
language plpgsql volatile security definer set search_path = '' as $$
begin
  if coalesce(p_quantite, 0) <= 0 then
    return;
  end if;
  perform public._assurer_defis(p_user);
  update public.defis_joueur dj
     set progression = least(m.objectif, dj.progression + p_quantite)
    from public.defi_modeles m
   where dj.modele_id = m.id and dj.user_id = p_user and m.type = p_type
     and dj.debut = public._debut_periode(m.periode) and dj.recupere_le is null;
end;
$$;
revoke all on function public._evenement(uuid, text, integer) from public, anon, authenticated;

-- Défis en cours du joueur (compte aussi la visite du jour).
create or replace function public.mes_defis()
returns table (modele_id text, periode text, type text, objectif integer, pieces integer, libelle jsonb,
               progression integer, recupere boolean, fin timestamptz)
language plpgsql volatile security definer set search_path = '' as $$
#variable_conflict use_column
declare
  uid uuid := (select auth.uid());
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  perform public._evenement(uid, 'connexion', 1);
  return query
    select m.id, m.periode, m.type, m.objectif, m.pieces, m.libelle, dj.progression, dj.recupere_le is not null,
           ((dj.debut + case m.periode when 'jour' then 1 else 7 end)::timestamp at time zone 'Europe/Paris')
      from public.defis_joueur dj join public.defi_modeles m on m.id = dj.modele_id
     where dj.user_id = uid and dj.debut = public._debut_periode(m.periode)
     order by m.periode, (dj.recupere_le is not null), m.pieces;
end;
$$;
revoke all on function public.mes_defis() from public, anon;
grant execute on function public.mes_defis() to authenticated;

-- Récupère la récompense d'un défi accompli. Renvoie le nouveau solde de pièces.
create or replace function public.recuperer_defi(p_modele text)
returns integer
language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
  m public.defi_modeles;
  dj public.defis_joueur;
  w public.wallets;
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  select * into m from public.defi_modeles where id = p_modele;
  select * into dj from public.defis_joueur
   where user_id = uid and modele_id = p_modele and debut = public._debut_periode(m.periode)
   for update;
  if dj.user_id is null then
    raise exception 'Défi introuvable' using errcode = 'P0003';
  end if;
  if dj.recupere_le is not null then
    raise exception 'Récompense déjà récupérée' using errcode = 'P0012';
  end if;
  if dj.progression < m.objectif then
    raise exception 'Défi pas encore accompli' using errcode = 'P0013';
  end if;
  update public.defis_joueur set recupere_le = now()
   where user_id = uid and modele_id = p_modele and debut = dj.debut;
  w := public._crediter(uid, 'defi', m.pieces, 0, m.id);
  return w.pieces;
end;
$$;
revoke all on function public.recuperer_defi(text) from public, anon;
grant execute on function public.recuperer_defi(text) to authenticated;

-- Ouverture de booster : paiement en pièces inscrit au journal, défis.
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

-- Vitrine : compte pour le défi « Modifier ta vitrine ».
create or replace function public.set_vitrine(p_cards uuid[])
returns void
language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  if coalesce(cardinality(p_cards), 0) > 9 then
    raise exception 'La vitrine compte 9 emplacements' using errcode = 'P0005';
  end if;
  if exists (
    select 1 from unnest(p_cards) as c(id)
     where c.id is not null
       and not exists (select 1 from public.owned_cards o where o.id = c.id and o.owner_id = uid)
  ) then
    raise exception 'Carte absente de ta collection' using errcode = 'P0006';
  end if;
  if (select count(c.id) - count(distinct c.id) from unnest(p_cards) as c(id)) > 0 then
    raise exception 'Une carte ne peut être exposée qu''une fois' using errcode = 'P0007';
  end if;

  delete from public.vitrine_slots where owner_id = uid;
  insert into public.vitrine_slots (owner_id, slot, owned_card_id)
  select uid, (t.ord - 1)::smallint, t.id
    from unnest(p_cards) with ordinality as t(id, ord)
   where t.id is not null;
  perform public._evenement(uid, 'vitrine', 1);
end;
$$;
