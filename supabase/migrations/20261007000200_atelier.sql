-- Atelier : recycler ses doublons en fragments, fabriquer une carte précise
-- avec des fragments, protéger une carte contre le recyclage.
--
-- Doublon = exemplaire supplémentaire d'une même carte dans la même variante.
-- Jamais recyclables : cartes numérotées (/50, 1/1…), copies admin, cartes
-- protégées, cartes exposées dans la vitrine. On garde toujours au moins un
-- exemplaire de chaque (carte, variante).

create or replace function public.recycler(p_ids uuid[])
returns table (cartes integer, fragments_gagnes integer, fragments integer)
language plpgsql volatile security definer set search_path = '' as $$
#variable_conflict use_column
declare
  uid uuid := (select auth.uid());
  cfg public.economy_config;
  n integer;
  gain integer;
  w public.wallets;
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  n := coalesce(cardinality(p_ids), 0);
  if n = 0 then
    raise exception 'Aucune carte à recycler' using errcode = '22023';
  end if;
  if n <> (select count(distinct x) from unnest(p_ids) x) then
    raise exception 'Carte en double dans la demande' using errcode = 'P0007';
  end if;
  select * into cfg from public.economy_config where id;

  -- Verrou : un recyclage à la fois par joueur
  perform 1 from public.wallets where user_id = uid for update;

  if exists (select 1 from unnest(p_ids) x
              where not exists (select 1 from public.owned_cards o where o.id = x and o.owner_id = uid)) then
    raise exception 'Carte absente de ta collection' using errcode = 'P0006';
  end if;
  if exists (select 1 from public.owned_cards o
              where o.id = any(p_ids)
                and (o.numero_serie is not null or o.tirage is not null or o.copie_admin or o.verrouillee
                     or exists (select 1 from public.vitrine_slots v where v.owned_card_id = o.id))) then
    raise exception 'Carte numérotée, protégée ou exposée : non recyclable' using errcode = 'P0008';
  end if;
  -- Il doit rester au moins un exemplaire de chaque (carte, variante)
  if exists (
    select 1
      from (select card_id, variant_id, count(*) as demandes
              from public.owned_cards where id = any(p_ids) group by card_id, variant_id) d
     where d.demandes >= (select count(*) from public.owned_cards o
                           where o.owner_id = uid and o.card_id = d.card_id and o.variant_id = d.variant_id)
  ) then
    raise exception 'Il faut garder au moins un exemplaire' using errcode = 'P0009';
  end if;

  select coalesce(sum(coalesce((cfg.fragments -> 'recyclage' ->> v.rarete)::integer, 0)), 0) into gain
    from public.owned_cards o join public.variants v on v.id = o.variant_id
   where o.id = any(p_ids);

  delete from public.owned_cards where id = any(p_ids);
  w := public._crediter(uid, 'recyclage', 0, gain, null, n);
  perform public._evenement(uid, 'recycler', n);
  return query select n, gain, w.fragments;
end;
$$;
revoke all on function public.recycler(uuid[]) from public, anon;
grant execute on function public.recycler(uuid[]) to authenticated;

-- Coût de fabrication d'une variante (null si elle ne se fabrique pas).
create or replace function public.cout_fabrication(p_variant text)
returns integer
language sql stable security definer set search_path = '' as $$
  select (cfg.fragments -> 'recyclage' ->> v.rarete)::integer * (cfg.fragments ->> 'facteur_fabrication')::integer
    from public.variants v
    join public.series s on s.id = v.series_id
    cross join public.economy_config cfg
   where v.id = p_variant and not v.deleted and cfg.id
     and v.tirage is null and s.tirage is null
     and not (coalesce(v.eligibilite, '{}'::jsonb) ? 'carte');
$$;
grant execute on function public.cout_fabrication(text) to authenticated;

create or replace function public.fabriquer(p_card text, p_variant text)
returns public.owned_cards
language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
  c public.cards;
  v public.variants;
  cout integer;
  result public.owned_cards;
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  select * into c from public.cards where id = p_card and not deleted;
  select * into v from public.variants where id = p_variant and not deleted;
  if c.id is null or v.id is null or v.series_id <> c.series_id then
    raise exception 'Carte introuvable' using errcode = 'P0003';
  end if;
  cout := public.cout_fabrication(p_variant);
  if cout is null then
    raise exception 'Cette carte ne se fabrique pas (numérotée ou spéciale)' using errcode = 'P0010';
  end if;
  if cardinality(c.fighter_ids) > 0 and not public.fighter_eligible(v.eligibilite, c.fighter_ids[1]) then
    raise exception 'Rareté impossible pour ce combattant' using errcode = 'P0011';
  end if;
  perform public._crediter(uid, 'fabrication', 0, -cout, p_card || '|' || p_variant);
  insert into public.owned_cards (owner_id, card_id, variant_id, origine)
  values (uid, p_card, p_variant, 'fabrication')
  returning * into result;
  perform public._evenement(uid, 'fabriquer', 1);
  return result;
end;
$$;
revoke all on function public.fabriquer(text, text) from public, anon;
grant execute on function public.fabriquer(text, text) to authenticated;

-- Protéger (ou non) un de ses exemplaires contre le recyclage.
create or replace function public.proteger(p_id uuid, p_protegee boolean)
returns void
language plpgsql volatile security definer set search_path = '' as $$
begin
  update public.owned_cards set verrouillee = p_protegee
   where id = p_id and owner_id = (select auth.uid());
  if not found then
    raise exception 'Carte absente de ta collection' using errcode = 'P0006';
  end if;
end;
$$;
revoke all on function public.proteger(uuid, boolean) from public, anon;
grant execute on function public.proteger(uuid, boolean) to authenticated;
