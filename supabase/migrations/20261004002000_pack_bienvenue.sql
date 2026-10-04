-- =============================================================================
-- Phase 2 : pack de bienvenue
-- Une seule fois par compte, 15 cartes NON numérotées (aucun tirage limité
-- consommé) : 11 communes (7 de la saison la plus récente, 4 de la base de
-- l'édition réelle la plus récente), 2 peu communes (Acier d'Octogone ou
-- Refractor), 2 rares (Néon Main Event).
-- Le tirage au sort se fait côté serveur, dans une transaction.
-- =============================================================================

alter table public.profiles add column if not exists pack_bienvenue_le timestamptz;
-- (colonne absente des droits UPDATE du client : seul le serveur la renseigne)

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
    select * from public.owned_cards
     where owner_id = uid and origine = 'depart'
     order by obtenue_le, id;
end;
$$;

revoke all on function public.claim_welcome_pack() from public, anon;
grant execute on function public.claim_welcome_pack() to authenticated;
