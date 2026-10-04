-- Rivalités réelles (2 combats ou plus entre deux combattants de la base),
-- générées par data/scripts/build_rivalries.py à partir des palmarès Wikipedia.
create table public.rivalries (
  id         text primary key,                 -- '<a>--<b>' (ordre alphabétique)
  fighter_a  text not null references public.fighters (id) on delete cascade,
  fighter_b  text not null references public.fighters (id) on delete cascade,
  nb_combats integer not null check (nb_combats >= 2),
  bilan      jsonb not null default '{}',      -- {fighter_id: victoires}
  combats    jsonb not null default '[]',      -- [{date, evenement, vainqueur, methode, round}]
  sources    jsonb not null default '[]',
  updated_at timestamptz not null default now(),
  deleted    boolean not null default false
);
alter table public.rivalries enable row level security;
create policy "contenu lisible" on public.rivalries for select to authenticated using (true);
create policy "contenu modifiable par un admin (insert)" on public.rivalries for insert to authenticated with check (public.is_admin());
create policy "contenu modifiable par un admin (update)" on public.rivalries for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "contenu modifiable par un admin (delete)" on public.rivalries for delete to authenticated using (public.is_admin());
create trigger rivalries_touch before update on public.rivalries for each row execute function public.touch_updated_at();
create index rivalries_updated_idx on public.rivalries (updated_at);
grant select, insert, update, delete on public.rivalries to authenticated;
revoke all on public.rivalries from anon;
