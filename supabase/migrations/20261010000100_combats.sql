-- =============================================================================
-- Phase 4 : combats contre l'IA, vérifiés par le serveur
--
-- 1. commencer_combat : le serveur tire la graine et note la carte jouée,
--    l'adversaire et les réglages (le joueur ne choisit pas sa graine).
-- 2. Fin du combat : l'app envoie le journal à l'Edge Function
--    valider-combat, qui le rejoue avec game_core (compilé en JavaScript)
--    puis appelle _terminer_combat (service uniquement) : récompense en
--    pièces selon le niveau de l'IA, défis, succès, historique.
--    Un journal qui ne correspond pas au combat recalculé est refusé.
-- =============================================================================

alter table public.economy_config
  add column if not exists recompenses_combat jsonb not null default
    '{"victoire": {"facile": 25, "normal": 50, "difficile": 90}, "defaite": 5, "bonus_finish": 0.5}';

create table public.combats (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users (id) on delete cascade,
  mode              text not null check (mode in ('rapide', 'soiree', 'route', 'rivalite')),
  niveau            text not null check (niveau in ('facile', 'normal', 'difficile')),
  format            text not null check (format in ('court', 'complet')),
  titre             boolean not null default false,
  poids_libre       boolean not null default false,
  graine            bigint not null check (graine >= 0 and graine < 2147483648),
  carte             uuid not null,          -- owned_cards.id (la carte peut être recyclée ensuite)
  combattant        text not null references public.fighters (id),
  rarete            text not null,
  bonus_stats       integer not null,
  adversaire        text not null references public.fighters (id),
  adversaire_rarete text not null,
  statut            text not null default 'en_cours' check (statut in ('en_cours', 'valide', 'refuse', 'abandon')),
  vainqueur         smallint check (vainqueur in (0, 1)),   -- 0 : le joueur ; null : nul ou non terminé
  methode           text,
  round             integer,
  pieces            integer not null default 0,
  journal           jsonb,
  habitudes         jsonb,
  tactiques         jsonb,
  cree_le           timestamptz not null default now(),
  termine_le        timestamptz
);
create index combats_user_idx on public.combats (user_id, cree_le desc);
alter table public.combats enable row level security;
create policy "chacun lit ses combats" on public.combats for select to authenticated
  using (user_id = (select auth.uid()));
revoke all on public.combats from anon;
revoke insert, update, delete on public.combats from authenticated;
grant select on public.combats to authenticated;

-- -----------------------------------------------------------------------------
-- Début d'un combat : vérifie la carte jouée et tire la graine.
-- -----------------------------------------------------------------------------
create or replace function public.commencer_combat(
  p_mode text, p_carte uuid, p_adversaire text, p_adversaire_rarete text,
  p_niveau text, p_format text, p_titre boolean default false, p_poids_libre boolean default false
)
returns table (id uuid, graine bigint)
language plpgsql volatile security definer set search_path = '' as $$
#variable_conflict use_column
declare
  uid uuid := (select auth.uid());
  card_fighters text[];
  card_tactic text;
  card_rarity text;
  card_bonus integer;
  g bigint := floor(random() * 2147483647)::bigint;
  new_id uuid;
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  select ca.fighter_ids, ca.tactique, va.rarete, va.bonus_stats
    into card_fighters, card_tactic, card_rarity, card_bonus
    from public.owned_cards o
    join public.cards ca on ca.id = o.card_id
    join public.variants va on va.id = o.variant_id
   where o.id = p_carte and o.owner_id = uid;
  if not found then
    raise exception 'Carte absente de ta collection' using errcode = 'P0006';
  end if;
  if cardinality(card_fighters) <> 1 or card_tactic is not null then
    raise exception 'Cette carte ne se joue pas en combat' using errcode = 'P0012';
  end if;
  if not exists (select 1 from public.fighters f where f.id = p_adversaire and not f.deleted)
     or p_adversaire = card_fighters[1] then
    raise exception 'Adversaire inconnu' using errcode = 'P0003';
  end if;
  -- L'adversaire a au plus une rareté de plus que ma carte (Route vers la ceinture)
  if public.rarity_rank(p_adversaire_rarete) is null
     or public.rarity_rank(p_adversaire_rarete) > public.rarity_rank(card_rarity) + 1 then
    raise exception 'Rareté de l''adversaire invalide' using errcode = '22023';
  end if;
  insert into public.combats (user_id, mode, niveau, format, titre, poids_libre, graine, carte, combattant,
                              rarete, bonus_stats, adversaire, adversaire_rarete)
  values (uid, p_mode, p_niveau, p_format, coalesce(p_titre, false), coalesce(p_poids_libre, false), g, p_carte,
          card_fighters[1], card_rarity, card_bonus, p_adversaire, p_adversaire_rarete)
  returning combats.id into new_id;
  return query select new_id, g;
end;
$$;
revoke all on function public.commencer_combat(text, uuid, text, text, text, text, boolean, boolean) from public, anon;
grant execute on function public.commencer_combat(text, uuid, text, text, text, text, boolean, boolean) to authenticated;

-- Abandon (ou combat non terminé) : aucune récompense.
create or replace function public.abandonner_combat(p_id uuid)
returns void
language sql volatile security definer set search_path = '' as $$
  update public.combats set statut = 'abandon', termine_le = now()
   where id = p_id and user_id = (select auth.uid()) and statut = 'en_cours';
$$;
revoke all on function public.abandonner_combat(uuid) from public, anon;
grant execute on function public.abandonner_combat(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Fin d'un combat, après le rejeu par l'Edge Function (service uniquement).
-- Récompense : victoire 25 / 50 / 90 pièces selon le niveau de l'IA, +50 %
-- sur un finish (KO, KO technique, soumission), défaite ou nul 5 pièces ;
-- plafond quotidien (economy_config.plafond_combat_jour, jour de Paris).
-- -----------------------------------------------------------------------------
create or replace function public._terminer_combat(
  p_id uuid, p_valide boolean, p_vainqueur smallint, p_methode text, p_round integer,
  p_journal jsonb, p_habitudes jsonb, p_tactiques jsonb
)
returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  cb public.combats;
  cfg public.economy_config;
  base integer;
  deja integer;
  gain integer := 0;
  finish boolean := p_methode in ('ko', 'tko', 'soumission');
begin
  select * into cb from public.combats where id = p_id for update;
  if not found then
    raise exception 'Combat introuvable' using errcode = 'P0003';
  end if;
  if cb.statut <> 'en_cours' then
    return jsonb_build_object('statut', cb.statut, 'pieces', cb.pieces, 'deja', true);
  end if;
  if not p_valide then
    update public.combats set statut = 'refuse', journal = p_journal, habitudes = p_habitudes,
                              tactiques = p_tactiques, termine_le = now()
     where id = p_id;
    return jsonb_build_object('statut', 'refuse', 'pieces', 0);
  end if;

  select * into cfg from public.economy_config where id;
  if p_vainqueur = 0 then
    base := coalesce((cfg.recompenses_combat -> 'victoire' ->> cb.niveau)::integer, 0);
    if finish then
      base := round(base * (1 + coalesce((cfg.recompenses_combat ->> 'bonus_finish')::numeric, 0)));
    end if;
  else
    base := coalesce((cfg.recompenses_combat ->> 'defaite')::integer, 0);
  end if;
  select coalesce(sum(l.pieces), 0) into deja from public.wallet_ledger l
   where l.user_id = cb.user_id and l.source = 'combat'
     and (l.created_at at time zone 'Europe/Paris')::date = (now() at time zone 'Europe/Paris')::date;
  gain := greatest(0, least(base, cfg.plafond_combat_jour - deja));

  update public.combats set statut = 'valide', vainqueur = p_vainqueur, methode = p_methode, round = p_round,
                            pieces = gain, journal = p_journal, habitudes = p_habitudes, tactiques = p_tactiques,
                            termine_le = now()
   where id = p_id;
  if gain > 0 then
    perform public._crediter(cb.user_id, 'combat', gain, 0, p_id::text);
  end if;
  perform public._evenement(cb.user_id, 'jouer_combat', 1);
  if p_vainqueur = 0 then
    perform public._evenement(cb.user_id, 'gagner_combat', 1);
    if finish then
      perform public._evenement(cb.user_id, 'gagner_finish', 1);
    end if;
  end if;
  return jsonb_build_object('statut', 'valide', 'pieces', gain, 'plafond', gain < base);
end;
$$;
revoke all on function public._terminer_combat(uuid, boolean, smallint, text, integer, jsonb, jsonb, jsonb)
  from public, anon, authenticated;
grant execute on function public._terminer_combat(uuid, boolean, smallint, text, integer, jsonb, jsonb, jsonb)
  to service_role;

-- -----------------------------------------------------------------------------
-- Succès de combat (calculés depuis les combats validés)
-- -----------------------------------------------------------------------------
alter table public.succes_modeles drop constraint if exists succes_modeles_type_check;
alter table public.succes_modeles add constraint succes_modeles_type_check
  check (type in ('boosters_ouverts', 'cartes_distinctes', 'legendaires', 'mythiques', 'series_completes', 'vitrine',
                  'doublons_recycles', 'cartes_fabriquees', 'defis_recuperes',
                  'combats_gagnes', 'combats_ko', 'combats_soumission', 'combats_difficile'));

create or replace function public._valeur_succes(p_user uuid, p_type text)
returns integer
language sql stable security definer set search_path = '' as $$
  select (case p_type
    when 'boosters_ouverts' then (select coalesce(max(ouverts), 0) from public.booster_stats where user_id = p_user)
    when 'cartes_distinctes' then (select count(distinct card_id) from public.owned_cards where owner_id = p_user)
    when 'legendaires' then (select count(*) from public.owned_cards o join public.variants v on v.id = o.variant_id
                              where o.owner_id = p_user and public.rarity_rank(v.rarete) >= public.rarity_rank('legendaire'))
    when 'mythiques' then (select count(*) from public.owned_cards o join public.variants v on v.id = o.variant_id
                            where o.owner_id = p_user and v.rarete = 'mythique')
    when 'series_completes' then (
      select count(*) from public.series s
       where not s.deleted
         and exists (select 1 from public.cards c where c.series_id = s.id and not c.deleted)
         and not exists (select 1 from public.cards c
                          where c.series_id = s.id and not c.deleted
                            and not exists (select 1 from public.owned_cards o where o.owner_id = p_user and o.card_id = c.id)))
    when 'vitrine' then (select count(*) from public.vitrine_slots where owner_id = p_user)
    when 'doublons_recycles' then (select coalesce(sum(quantite), 0) from public.wallet_ledger
                                    where user_id = p_user and source = 'recyclage')
    when 'cartes_fabriquees' then (select count(*) from public.wallet_ledger where user_id = p_user and source = 'fabrication')
    when 'defis_recuperes' then (select count(*) from public.wallet_ledger where user_id = p_user and source = 'defi')
    when 'combats_gagnes' then (select count(*) from public.combats
                                 where user_id = p_user and statut = 'valide' and vainqueur = 0)
    when 'combats_ko' then (select count(*) from public.combats
                             where user_id = p_user and statut = 'valide' and vainqueur = 0 and methode in ('ko', 'tko'))
    when 'combats_soumission' then (select count(*) from public.combats
                                     where user_id = p_user and statut = 'valide' and vainqueur = 0 and methode = 'soumission')
    when 'combats_difficile' then (select count(*) from public.combats
                                    where user_id = p_user and statut = 'valide' and vainqueur = 0 and niveau = 'difficile')
    else 0
  end)::integer;
$$;
revoke all on function public._valeur_succes(uuid, text) from public, anon, authenticated;
