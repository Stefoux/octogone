-- Vitrine : chaque joueur expose jusqu'à 9 de ses exemplaires (place 0 =
-- place d'honneur). Les emplacements pointent vers owned_cards : si un
-- exemplaire quitte la collection (échange, recyclage…), il quitte la vitrine.

create table public.vitrine_slots (
  owner_id      uuid not null references auth.users (id) on delete cascade,
  slot          smallint not null check (slot between 0 and 8),
  owned_card_id uuid not null references public.owned_cards (id) on delete cascade,
  updated_at    timestamptz not null default now(),
  primary key (owner_id, slot),
  constraint vitrine_slots_carte_unique unique (owner_id, owned_card_id)
);

alter table public.vitrine_slots enable row level security;

create policy "chacun voit sa vitrine" on public.vitrine_slots
  for select to authenticated using (owner_id = (select auth.uid()));

-- Écriture uniquement par set_vitrine (qui vérifie la propriété des cartes)
revoke all on public.vitrine_slots from anon;
revoke insert, update, delete on public.vitrine_slots from authenticated;
grant select on public.vitrine_slots to authenticated;

-- Enregistre toute la vitrine d'un coup (ajout, retrait, réorganisation).
-- p_cards[i] = exemplaire exposé à la place i-1, null = emplacement vide.
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
end;
$$;

revoke all on function public.set_vitrine(uuid[]) from public, anon;
grant execute on function public.set_vitrine(uuid[]) to authenticated;

-- Lecture de la vitrine d'un joueur avec le détail des cartes. Prévu pour la
-- consultation par les amis (phase en ligne) : pour l'instant, seulement la
-- sienne. Il suffira d'élargir la condition ci-dessous.
create or replace function public.vitrine_de(p_joueur uuid)
returns table (slot smallint, owned_card_id uuid, card_id text, variant_id text,
               numero_serie integer, tirage integer)
language sql stable security definer set search_path = '' as $$
  select v.slot, o.id, o.card_id, o.variant_id, o.numero_serie, o.tirage
    from public.vitrine_slots v
    join public.owned_cards o on o.id = v.owned_card_id
   where v.owner_id = p_joueur
     and p_joueur = (select auth.uid())
   order by v.slot;
$$;

revoke all on function public.vitrine_de(uuid) from public, anon;
grant execute on function public.vitrine_de(uuid) to authenticated;
