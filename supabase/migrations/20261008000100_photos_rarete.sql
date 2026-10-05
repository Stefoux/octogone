-- Photos selon la rareté : chaque photo d'un combattant indique les raretés
-- de carte qu'elle illustre (combat jusqu'à Épique, célébration ou ceinture
-- pour Légendaire et Mythique). Sans photo pour une rareté, la carte garde
-- le portrait du combattant (fighters.image_id).
alter table public.images drop constraint if exists images_type_check;
alter table public.images add constraint images_type_check
  check (type in ('portrait', 'action', 'celebration', 'ceinture', 'pesee', 'walkout', 'moment', 'autre'));
alter table public.images add column if not exists raretes text[] not null default '{}';
create index if not exists images_fighter_type on public.images (fighter_id, type) where not deleted;
