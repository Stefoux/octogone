-- =============================================================================
-- Cartes Tactique : plus dans les boosters, gagnées en jouant
--   - victoire en combat : 1 chance sur 2, rareté selon le niveau de l'IA
--     (Difficile et Route vers la ceinture : jusqu'à Légendaire) ;
--   - chaque défi récupéré : une carte (défi de la semaine : Rare ou mieux) ;
--   - succès de combat : une Épique.
-- Barèmes dans economy_config.recompenses_tactique (modifiables par un admin).
-- Les boosters gardent la possibilité technique d'une carte Tactique
-- (composition.tactique), mais data/boosters.json ne l'utilise plus.
-- =============================================================================

alter table public.economy_config
  add column if not exists recompenses_tactique jsonb not null default
    '{"combat": {"chance": 0.5,
                 "facile": {"commune": 70, "peu_commune": 30},
                 "normal": {"commune": 45, "peu_commune": 35, "rare": 20},
                 "difficile": {"peu_commune": 35, "rare": 40, "epique": 20, "legendaire": 5},
                 "route": {"peu_commune": 35, "rare": 40, "epique": 20, "legendaire": 5}},
      "defi": {"jour": {"commune": 60, "peu_commune": 30, "rare": 10},
               "semaine": {"rare": 60, "epique": 30, "legendaire": 10}},
      "succes_combat": {"epique": 100}}';

-- Donne une carte Tactique tirée selon les poids de rareté (rareté inférieure
-- si besoin). Renvoie {owned_id, card_id, variant_id, rarete}, ou null si
-- l'édition Tactique n'est pas importée.
create or replace function public._donner_tactique(p_user uuid, p_poids jsonb)
returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  tiers constant text[] := array['commune', 'peu_commune', 'rare', 'epique', 'legendaire', 'mythique'];
  tier text := coalesce(public.pick_weighted(p_poids), 'commune');
  v public.variants;
  cid text;
  o public.owned_cards;
begin
  loop
    select v2.* into v
      from public.variants v2 join public.editions e on e.id = v2.edition_id
     where e.type = 'tactique' and not e.deleted and not v2.deleted and v2.rarete = tier
     order by random() limit 1;
    exit when found or tier = 'commune';
    tier := tiers[array_position(tiers, tier) - 1];
  end loop;
  if v.id is null then
    return null;
  end if;
  select c.id into cid from public.cards c
   where c.series_id = v.series_id and not c.deleted
   order by random() limit 1;
  if cid is null then
    return null;
  end if;
  insert into public.owned_cards (owner_id, card_id, variant_id, origine)
  values (p_user, cid, v.id, 'recompense')
  returning * into o;
  return jsonb_build_object('owned_id', o.id, 'card_id', o.card_id, 'variant_id', o.variant_id, 'rarete', v.rarete);
end;
$$;
revoke all on function public._donner_tactique(uuid, jsonb) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Fin d'un combat : + carte Tactique (1 chance sur 2 après une victoire)
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
  carte jsonb;
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
    if random() < coalesce((cfg.recompenses_tactique -> 'combat' ->> 'chance')::numeric, 0) then
      carte := public._donner_tactique(cb.user_id,
        cfg.recompenses_tactique -> 'combat' -> (case when cb.mode = 'route' then 'route' else cb.niveau end));
    end if;
  end if;
  return jsonb_build_object('statut', 'valide', 'pieces', gain, 'plafond', gain < base, 'carte', carte);
end;
$$;
revoke all on function public._terminer_combat(uuid, boolean, smallint, text, integer, jsonb, jsonb, jsonb)
  from public, anon, authenticated;
grant execute on function public._terminer_combat(uuid, boolean, smallint, text, integer, jsonb, jsonb, jsonb)
  to service_role;

-- -----------------------------------------------------------------------------
-- Défis : récupérer donne aussi une carte Tactique. reclamer_defi renvoie
-- {pieces (nouveau solde), carte} ; recuperer_defi (anciennes versions de
-- l'app) renvoie toujours le solde.
-- -----------------------------------------------------------------------------
create or replace function public.reclamer_defi(p_modele text)
returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
  m public.defi_modeles;
  dj public.defis_joueur;
  w public.wallets;
  carte jsonb;
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
  carte := public._donner_tactique(uid,
    (select cfg.recompenses_tactique -> 'defi' -> m.periode from public.economy_config cfg where cfg.id));
  return jsonb_build_object('pieces', w.pieces, 'carte', carte);
end;
$$;
revoke all on function public.reclamer_defi(text) from public, anon;
grant execute on function public.reclamer_defi(text) to authenticated;

create or replace function public.recuperer_defi(p_modele text)
returns integer
language sql volatile security definer set search_path = '' as $$
  select (public.reclamer_defi(p_modele) ->> 'pieces')::integer;
$$;
revoke all on function public.recuperer_defi(text) from public, anon;
grant execute on function public.recuperer_defi(text) to authenticated;

-- -----------------------------------------------------------------------------
-- Succès : les succès de combat donnent aussi une carte Tactique Épique.
-- -----------------------------------------------------------------------------
create or replace function public.reclamer_succes(p_id text)
returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
  m public.succes_modeles;
  w public.wallets;
  carte jsonb;
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  select * into m from public.succes_modeles where id = p_id and actif;
  if m.id is null then
    raise exception 'Succès introuvable' using errcode = 'P0003';
  end if;
  if public._valeur_succes(uid, m.type) < m.objectif then
    raise exception 'Succès pas encore atteint' using errcode = 'P0013';
  end if;
  insert into public.succes_joueur (user_id, succes_id) values (uid, m.id)
  on conflict do nothing;
  if not found then
    raise exception 'Récompense déjà récupérée' using errcode = 'P0012';
  end if;
  w := public._crediter(uid, 'succes', m.pieces, 0, m.id);
  if m.type like 'combats_%' then
    carte := public._donner_tactique(uid,
      (select cfg.recompenses_tactique -> 'succes_combat' from public.economy_config cfg where cfg.id));
  end if;
  return jsonb_build_object('pieces', w.pieces, 'carte', carte);
end;
$$;
revoke all on function public.reclamer_succes(text) from public, anon;
grant execute on function public.reclamer_succes(text) to authenticated;

create or replace function public.recuperer_succes(p_id text)
returns integer
language sql volatile security definer set search_path = '' as $$
  select (public.reclamer_succes(p_id) ->> 'pieces')::integer;
$$;
revoke all on function public.recuperer_succes(text) from public, anon;
grant execute on function public.recuperer_succes(text) to authenticated;
