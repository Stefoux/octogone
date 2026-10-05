-- Socle de l'économie : journal des pièces et fragments, crédit/débit
-- centralisé, barème des fragments, point d'entrée des événements de jeu
-- (défis et succès s'y branchent).

-- Journal : chaque gain ou dépense est tracé (anti-triche, historique, XP plus tard).
create table public.wallet_ledger (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  pieces     integer not null default 0,
  fragments  integer not null default 0,
  source     text not null check (source in ('booster', 'defi', 'succes', 'recyclage', 'fabrication',
                                             'admin', 'combat', 'depart')),
  ref        text,
  quantite   integer not null default 1,
  created_at timestamptz not null default now()
);
create index wallet_ledger_user on public.wallet_ledger (user_id, created_at desc);
alter table public.wallet_ledger enable row level security;
create policy "chacun lit son journal" on public.wallet_ledger
  for select to authenticated using (user_id = (select auth.uid()));
revoke all on public.wallet_ledger from anon;
revoke insert, update, delete on public.wallet_ledger from authenticated;
grant select on public.wallet_ledger to authenticated;

-- Barème des fragments : gain au recyclage par rareté ; la fabrication coûte
-- « facteur » fois ce gain. Les cartes numérotées ne se recyclent ni ne se
-- fabriquent.
alter table public.economy_config
  add column fragments jsonb not null default
    '{"recyclage": {"commune": 5, "peu_commune": 15, "rare": 40, "epique": 100, "legendaire": 400, "mythique": 1600},
      "facteur_fabrication": 6}'::jsonb,
  -- Plafond quotidien de pièces gagnées en combat (phase 4)
  add column plafond_combat_jour integer not null default 600;

-- Crédite (ou débite, montants négatifs) un joueur et l'inscrit au journal.
-- Refuse si le solde deviendrait négatif (P0004).
create or replace function public._crediter(p_user uuid, p_source text, p_pieces integer, p_fragments integer,
                                           p_ref text default null, p_quantite integer default 1)
returns public.wallets
language plpgsql volatile security definer set search_path = '' as $$
declare
  w public.wallets;
begin
  update public.wallets set pieces = pieces + p_pieces, fragments = fragments + p_fragments
   where user_id = p_user and pieces + p_pieces >= 0 and fragments + p_fragments >= 0
  returning * into w;
  if not found then
    raise exception 'Solde insuffisant' using errcode = 'P0004';
  end if;
  insert into public.wallet_ledger (user_id, pieces, fragments, source, ref, quantite)
  values (p_user, p_pieces, p_fragments, p_source, p_ref, p_quantite);
  return w;
end;
$$;
revoke all on function public._crediter(uuid, text, integer, integer, text, integer) from public, anon, authenticated;

-- Événement de jeu (booster ouvert, doublon recyclé…). Vide pour l'instant :
-- les défis s'y branchent (migration suivante). Appelé uniquement par les
-- fonctions serveur.
create or replace function public._evenement(p_user uuid, p_type text, p_quantite integer default 1)
returns void
language plpgsql volatile security definer set search_path = '' as $$
begin
  null;
end;
$$;
revoke all on function public._evenement(uuid, text, integer) from public, anon, authenticated;
