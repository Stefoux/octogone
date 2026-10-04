-- =============================================================================
-- Octogone — Phase 1 : fondations
-- Rôles, profils, portefeuille, contenu (combattants, éditions, séries, cartes,
-- variantes/parallèles, images, événements), exemplaires possédés.
--
-- Principes de sécurité :
--   * RLS activé sur TOUTES les tables du schéma public.
--   * Le rôle admin vit dans user_roles, sans aucune policy d'écriture :
--     un joueur ne peut ni se l'attribuer ni le lire chez les autres.
--   * Le contenu est lisible par tout joueur connecté, modifiable seulement
--     par un admin (is_admin()).
--   * Les exemplaires de cartes et les portefeuilles ne sont jamais écrits
--     directement par le client : uniquement par des fonctions serveur.
-- =============================================================================

create extension if not exists pgcrypto with schema extensions;

-- -----------------------------------------------------------------------------
-- Rôles
-- -----------------------------------------------------------------------------
create type public.app_role as enum ('joueur', 'admin');

create table public.user_roles (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  role       public.app_role not null default 'joueur',
  granted_at timestamptz not null default now()
);
alter table public.user_roles enable row level security;
create policy "chacun lit son propre rôle" on public.user_roles
  for select to authenticated using (user_id = (select auth.uid()));
-- Pas de policy insert/update/delete : seul le service_role (migrations,
-- fonctions security definer) peut écrire.

-- Emails des admins (table privée : RLS activé, aucune policy).
create table public.admin_emails (
  email text primary key check (email = lower(email))
);
alter table public.admin_emails enable row level security;

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = (select auth.uid()) and role = 'admin'
  );
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated, anon;

-- -----------------------------------------------------------------------------
-- Outils
-- -----------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Code ami : 8 caractères sans ambiguïté (pas de 0/O, 1/I/L).
create or replace function public.gen_friend_code()
returns text language plpgsql volatile set search_path = '' as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  code text;
begin
  loop
    code := '';
    for i in 1..8 loop
      code := code || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.profiles where friend_code = code);
  end loop;
  return code;
end;
$$;

-- -----------------------------------------------------------------------------
-- Profils et portefeuilles
-- -----------------------------------------------------------------------------
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  pseudo      text not null unique check (char_length(pseudo) between 3 and 20),
  friend_code text not null unique,
  vitrine     uuid[] not null default '{}' check (cardinality(vitrine) <= 5),
  admin_mode  boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
alter table public.profiles enable row level security;
create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();

create policy "profils lisibles par les joueurs connectés" on public.profiles
  for select to authenticated using (true);
create policy "chacun modifie son profil" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Seules ces colonnes sont modifiables par le client.
revoke update on public.profiles from authenticated, anon;
grant update (pseudo, vitrine, admin_mode) on public.profiles to authenticated;

-- Le mode admin ne peut être activé que par un admin.
create or replace function public.guard_admin_mode()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.admin_mode and not public.is_admin() then
    raise exception 'Mode admin réservé aux administrateurs' using errcode = '42501';
  end if;
  return new;
end;
$$;
create trigger profiles_guard_admin_mode before insert or update of admin_mode on public.profiles
  for each row execute function public.guard_admin_mode();

create table public.wallets (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  pieces     integer not null default 500 check (pieces >= 0),
  fragments  integer not null default 0 check (fragments >= 0),
  updated_at timestamptz not null default now()
);
alter table public.wallets enable row level security;
create policy "chacun lit son portefeuille" on public.wallets
  for select to authenticated using (user_id = (select auth.uid()));
create trigger wallets_touch before update on public.wallets
  for each row execute function public.touch_updated_at();

-- Pseudo libre ? (appelé avant l'inscription, donc ouvert à anon)
create or replace function public.pseudo_disponible(p text)
returns boolean language sql stable security definer set search_path = '' as $$
  select char_length(trim(p)) between 3 and 20
     and not exists (select 1 from public.profiles where lower(pseudo) = lower(trim(p)));
$$;
grant execute on function public.pseudo_disponible(text) to anon, authenticated;

-- À l'inscription : profil, portefeuille, rôle (admin si l'email est listé).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  wanted text := coalesce(nullif(trim(new.raw_user_meta_data ->> 'pseudo'), ''),
                          split_part(new.email, '@', 1));
  final  text;
begin
  wanted := left(regexp_replace(wanted, '[^[:alnum:]_ .-]', '', 'g'), 16);
  if char_length(wanted) < 3 then
    wanted := 'Joueur';
  end if;
  final := wanted;
  while exists (select 1 from public.profiles where lower(pseudo) = lower(final)) loop
    final := wanted || floor(random() * 9000 + 1000)::int;
  end loop;

  insert into public.profiles (id, pseudo, friend_code)
  values (new.id, final, public.gen_friend_code());
  insert into public.wallets (user_id) values (new.id);
  insert into public.user_roles (user_id, role)
  values (new.id,
          case when exists (select 1 from public.admin_emails where email = lower(new.email))
               then 'admin'::public.app_role else 'joueur'::public.app_role end);
  return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- Contenu de jeu
-- -----------------------------------------------------------------------------
create table public.images (
  id           uuid primary key default gen_random_uuid(),
  storage_path text not null unique,           -- chemin dans le bucket « cartes »
  type         text not null default 'portrait'
               check (type in ('portrait', 'action', 'celebration', 'pesee', 'walkout', 'moment', 'autre')),
  fighter_id   text,
  titre        text,
  auteur       text,
  licence      text,
  licence_url  text,
  source_url   text,                           -- page d'origine (Wikimedia Commons…)
  largeur      integer,
  hauteur      integer,
  focal_x      real check (focal_x between 0 and 1),   -- centre du visage
  focal_y      real check (focal_y between 0 and 1),
  visage       jsonb,                          -- boîte du visage détecté {x,y,w,h} en 0..1
  importe_par  uuid references auth.users (id) on delete set null,
  updated_at   timestamptz not null default now(),
  deleted      boolean not null default false
);

create table public.fighters (
  id                 text primary key,
  nom                text not null,
  surnom             text,
  sexe               text check (sexe in ('M', 'F')),
  pays               text check (pays ~ '^[A-Z]{2}$'),
  categorie          text check (categorie in ('paille_f', 'mouche_f', 'coq_f', 'plume_f', 'mouche', 'coq',
                                               'plume', 'legers', 'mi_moyens', 'moyens', 'mi_lourds', 'lourds')),
  statut             text check (statut in ('actif', 'retraite', 'inactif')),
  date_naissance     date,
  taille_cm          integer,
  allonge_cm         integer,
  style              text,
  champion_actuel    boolean not null default false,
  ancien_champion    boolean not null default false,
  palmares           jsonb not null default '{}',
  stats_ufc          jsonb not null default '{}',
  ufc                jsonb not null default '{}',
  stats_jeu          jsonb not null default '{}',
  stats_jeu_override jsonb,                   -- retouches admin (phase 6)
  accomplissements   jsonb not null default '[]',
  image_id           uuid references public.images (id) on delete set null,
  sources            jsonb not null default '{}',
  champs_sources     jsonb not null default '{}',
  a_verifier         text[] not null default '{}',
  updated_at         timestamptz not null default now(),
  deleted            boolean not null default false
);
alter table public.images
  add constraint images_fighter_fk foreign key (fighter_id) references public.fighters (id) on delete set null;

create table public.events (
  id         text primary key,
  nom        text not null,
  date       date,
  lieu       text,
  ville      text,
  pays       text,
  resultat   text,
  contexte   text,
  resultats  jsonb not null default '[]',
  tirage     integer check (tirage > 0),      -- tirage des cartes Moment Historique (ex. 250)
  sources    jsonb not null default '[]',
  a_verifier text[] not null default '{}',
  updated_at timestamptz not null default now(),
  deleted    boolean not null default false
);

create table public.editions (
  id            text primary key,
  nom           text not null,
  annee         integer not null,
  type          text not null check (type in ('reelle', 'originale', 'evenement')),
  marque        text,
  gamme         text,
  famille_cadre text not null,
  date_sortie   text,
  description   text,
  sources       jsonb not null default '[]',
  a_verifier    text[] not null default '{}',
  ordre         integer not null default 0,
  updated_at    timestamptz not null default now(),
  deleted       boolean not null default false
);

create table public.series (
  id          text primary key,                -- '<edition>:<code>'
  edition_id  text not null references public.editions (id) on delete cascade,
  code        text not null,
  nom         text not null,
  type        text not null check (type in ('base', 'insert', 'autographe', 'relique', 'moment', 'celebration')),
  insert_type text,                            -- séries originales : aftermath, pesee, walkout…
  nb_cartes   integer,
  cote        text,
  exclusivite text,
  tirage      integer check (tirage > 0),      -- série entièrement numérotée (ex. /10)
  notes       jsonb not null default '[]',
  source      text,
  ordre       integer not null default 0,
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false,
  unique (edition_id, code)
);

create table public.cards (
  id          text primary key,                -- '<edition>:<numero>'
  edition_id  text not null references public.editions (id) on delete cascade,
  series_id   text not null references public.series (id) on delete cascade,
  numero      text not null,
  ordre       integer not null,
  fighter_ids text[] not null default '{}',    -- 2 combattants pour Rivalités, Face-à-Face, Trilogie
  nom_imprime text not null,
  sous_titre  text,
  mentions    text[] not null default '{}',    -- RC…
  event_id    text references public.events (id) on delete set null,
  image_id    uuid references public.images (id) on delete set null,
  texte_verso text,
  sources     jsonb not null default '[]',
  a_verifier  text[] not null default '{}',
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false,
  unique (edition_id, numero)
);
create index cards_series_idx on public.cards (series_id, ordre);
create index cards_fighters_idx on public.cards using gin (fighter_ids);

-- Variantes : parallèles réels d'une série (Refractor, Gold /50…) et raretés
-- originales (Acier d'Octogone, Ceinture d'Or…).
create table public.variants (
  id             text primary key,
  edition_id     text references public.editions (id) on delete cascade,
  series_id      text references public.series (id) on delete cascade,
  nom            text not null,
  rarete         text not null check (rarete in ('commune', 'peu_commune', 'rare', 'epique', 'legendaire', 'mythique')),
  effet          text not null,
  couleur        text,
  tirage         integer check (tirage > 0),   -- null = illimité
  cote           text,
  exclusivite    text,
  reel           boolean not null,
  eligibilite    jsonb,                        -- règles d'attribution des raretés originales
  bonus_stats    integer not null default 0 check (bonus_stats between 0 and 6),
  coup_signature boolean not null default false,
  ordre          integer not null default 0,
  updated_at     timestamptz not null default now(),
  deleted        boolean not null default false
);
create index variants_series_idx on public.variants (series_id);

-- Compteur de numérotation globale par (carte, variante) : une /50 n'existe
-- qu'en 50 exemplaires parmi tous les joueurs.
create table public.print_runs (
  card_id         text not null references public.cards (id) on delete cascade,
  variant_id      text not null references public.variants (id) on delete cascade,
  tirage          integer not null check (tirage > 0),
  prochain_numero integer not null default 1 check (prochain_numero between 1 and tirage + 1),
  primary key (card_id, variant_id)
);

create table public.owned_cards (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null references auth.users (id) on delete cascade,
  card_id      text not null references public.cards (id),
  variant_id   text not null references public.variants (id),
  numero_serie integer check (numero_serie > 0),
  tirage       integer check (tirage > 0),
  copie_admin  boolean not null default false,
  origine      text not null check (origine in ('booster', 'fabrication', 'recompense', 'echange', 'admin', 'depart')),
  obtenue_le   timestamptz not null default now(),
  verrouillee  boolean not null default false,
  -- Unicité du numéro : deux exemplaires ne peuvent pas porter le même 12/50.
  constraint owned_cards_numero_unique unique (card_id, variant_id, numero_serie),
  constraint owned_cards_numero_coherent check (
    (numero_serie is null and (tirage is null or copie_admin))
    or (numero_serie is not null and tirage is not null and numero_serie <= tirage and not copie_admin)
  )
);
create index owned_cards_owner_idx on public.owned_cards (owner_id);
alter table public.owned_cards enable row level security;
create policy "chacun voit ses cartes, l'admin voit tout" on public.owned_cards
  for select to authenticated using (owner_id = (select auth.uid()) or public.is_admin());

alter table public.print_runs enable row level security;
create policy "tirages lisibles" on public.print_runs for select to authenticated using (true);

-- RLS du contenu : lecture pour tous les joueurs connectés, écriture admin.
do $$
declare t text;
begin
  foreach t in array array['images', 'fighters', 'events', 'editions', 'series', 'cards', 'variants'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "contenu lisible" on public.%I for select to authenticated using (true)', t);
    execute format('create policy "contenu modifiable par un admin (insert)" on public.%I for insert to authenticated with check (public.is_admin())', t);
    execute format('create policy "contenu modifiable par un admin (update)" on public.%I for update to authenticated using (public.is_admin()) with check (public.is_admin())', t);
    execute format('create policy "contenu modifiable par un admin (delete)" on public.%I for delete to authenticated using (public.is_admin())', t);
    execute format('create trigger %I before update on public.%I for each row execute function public.touch_updated_at()', t || '_touch', t);
    execute format('create index %I on public.%I (updated_at)', t || '_updated_idx', t);
  end loop;
end $$;

-- -----------------------------------------------------------------------------
-- Stockage des images : bucket public en lecture, écriture réservée aux admins
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('cartes', 'cartes', true, 2097152, array['image/webp', 'image/jpeg', 'image/png'])
on conflict (id) do nothing;

create policy "images de cartes : écriture admin" on storage.objects
  for insert to authenticated with check (bucket_id = 'cartes' and public.is_admin());
create policy "images de cartes : modification admin" on storage.objects
  for update to authenticated using (bucket_id = 'cartes' and public.is_admin());
create policy "images de cartes : suppression admin" on storage.objects
  for delete to authenticated using (bucket_id = 'cartes' and public.is_admin());

-- -----------------------------------------------------------------------------
-- Privilèges explicites (la RLS reste le vrai garde-fou)
-- -----------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;
-- Un visiteur non connecté n'a accès à aucune table (seulement à pseudo_disponible).
revoke all on all tables in schema public from anon;
alter default privileges in schema public revoke all on tables from anon;
grant select, insert, update, delete
  on public.images, public.fighters, public.events, public.editions, public.series,
     public.cards, public.variants
  to authenticated;
grant select on public.profiles, public.wallets, public.user_roles, public.owned_cards, public.print_runs
  to authenticated;
revoke insert, update, delete on public.wallets, public.user_roles, public.owned_cards, public.print_runs
  from anon, authenticated;
revoke insert, delete on public.profiles from anon, authenticated;
revoke all on public.admin_emails from anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.guard_admin_mode() from public, anon, authenticated;
