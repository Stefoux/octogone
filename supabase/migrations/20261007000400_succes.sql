-- Succès permanents : progression calculée à partir des données réelles du
-- joueur (rien à tricher côté app), récompense en pièces récupérable une fois.

create table public.succes_modeles (
  id         text primary key,
  type       text not null check (type in ('boosters_ouverts', 'cartes_distinctes', 'legendaires', 'mythiques',
                                           'series_completes', 'vitrine', 'doublons_recycles', 'cartes_fabriquees',
                                           'defis_recuperes')),
  objectif   integer not null check (objectif > 0),
  pieces     integer not null check (pieces >= 0),
  libelle    jsonb not null,
  ordre      integer not null default 0,
  actif      boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.succes_modeles enable row level security;
create policy "succès lisibles" on public.succes_modeles for select to authenticated using (true);
create policy "succès modifiables par un admin (insert)" on public.succes_modeles for insert to authenticated with check (public.is_admin());
create policy "succès modifiables par un admin (update)" on public.succes_modeles for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
revoke all on public.succes_modeles from anon;
grant select, insert, update on public.succes_modeles to authenticated;

create table public.succes_joueur (
  user_id     uuid not null references auth.users (id) on delete cascade,
  succes_id   text not null references public.succes_modeles (id) on delete cascade,
  recupere_le timestamptz not null default now(),
  primary key (user_id, succes_id)
);
alter table public.succes_joueur enable row level security;
create policy "chacun lit ses succès" on public.succes_joueur for select to authenticated using (user_id = (select auth.uid()));
revoke all on public.succes_joueur from anon;
revoke insert, update, delete on public.succes_joueur from authenticated;
grant select on public.succes_joueur to authenticated;

-- Valeur actuelle d'un type de succès pour un joueur.
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
    else 0
  end)::integer;
$$;
revoke all on function public._valeur_succes(uuid, text) from public, anon, authenticated;

create or replace function public.mes_succes()
returns table (succes_id text, type text, objectif integer, pieces integer, libelle jsonb, progression integer,
               recupere boolean)
language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
declare
  uid uuid := (select auth.uid());
begin
  if uid is null then
    raise exception 'Connexion requise' using errcode = '42501';
  end if;
  return query
    with valeurs as (
      select t.type, public._valeur_succes(uid, t.type) as v
        from (select distinct type from public.succes_modeles where actif) t
    )
    select m.id, m.type, m.objectif, m.pieces, m.libelle, least(m.objectif, va.v),
           exists (select 1 from public.succes_joueur sj where sj.user_id = uid and sj.succes_id = m.id)
      from public.succes_modeles m join valeurs va on va.type = m.type
     where m.actif
     order by m.ordre, m.objectif;
end;
$$;
revoke all on function public.mes_succes() from public, anon;
grant execute on function public.mes_succes() to authenticated;

-- Récupère la récompense d'un succès atteint. Renvoie le nouveau solde de pièces.
create or replace function public.recuperer_succes(p_id text)
returns integer
language plpgsql volatile security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
  m public.succes_modeles;
  w public.wallets;
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
  return w.pieces;
end;
$$;
revoke all on function public.recuperer_succes(text) from public, anon;
grant execute on function public.recuperer_succes(text) to authenticated;
