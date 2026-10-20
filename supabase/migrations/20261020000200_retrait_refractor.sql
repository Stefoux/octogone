-- =============================================================================
-- Retrait des Refractor (choix de jeu du 20 octobre 2026)
--
-- Tous les parallèles Refractor de l'édition 2024 Topps Chrome UFC, X-Fractor
-- compris, sortent du jeu : il reste la Base de chaque série et la
-- SuperFractor 1/1. Les exemplaires possédés sont supprimés et chaque joueur
-- reçoit les fragments de leur rareté (barème de recyclage), inscrits au
-- journal (source admin). La checklist réelle reste dans
-- data/editions/2024-topps-chrome-ufc.json (« paralleles_hors_jeu »).
-- =============================================================================

-- Retire des variantes du jeu : exemplaires supprimés et remboursés en
-- fragments, variantes désactivées. Réservé au service (migrations, scripts).
create or replace function public._retirer_variantes(p_variantes text[], p_ref text)
returns table (joueur uuid, cartes integer, fragments integer)
language plpgsql volatile security definer set search_path = '' as $$
#variable_conflict use_column
declare
  cfg public.economy_config;
  r record;
begin
  select * into cfg from public.economy_config where id;
  for r in
    select o.owner_id as uid, count(*)::integer as n,
           coalesce(sum((cfg.fragments -> 'recyclage' ->> v.rarete)::integer), 0)::integer as frag
      from public.owned_cards o join public.variants v on v.id = o.variant_id
     where o.variant_id = any (p_variantes)
     group by o.owner_id
  loop
    delete from public.owned_cards o where o.owner_id = r.uid and o.variant_id = any (p_variantes);
    if r.frag > 0 then
      perform public._crediter(r.uid, 'admin', 0, r.frag, p_ref, r.n);
    end if;
    joueur := r.uid;
    cartes := r.n;
    fragments := r.frag;
    return next;
  end loop;
  update public.variants set deleted = true where id = any (p_variantes) and not deleted;
end;
$$;
revoke all on function public._retirer_variantes(text[], text) from public, anon, authenticated;

select count(*) as joueurs_rembourses
  from public._retirer_variantes(
    array(select id from public.variants
           where edition_id = '2024-topps-chrome-ufc'
             and (nom ilike '%refractor%' or nom ilike '%x-fractor%')),
    'retrait des Refractor');
