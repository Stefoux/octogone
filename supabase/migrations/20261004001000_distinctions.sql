-- Distinctions courtes et traduites, par langue : {"fr": [...], "en": [...]}.
-- Générées par data/scripts/distinctions.py ; l'app affiche la langue du téléphone
-- (repli sur le français).
alter table public.fighters
  add column if not exists distinctions jsonb not null default '{}';

comment on column public.fighters.distinctions is
  'Distinctions courtes par langue, ex. {"fr": ["Champion UFC des poids légers"], "en": ["UFC Lightweight Champion"]}';
comment on column public.fighters.accomplissements is
  'Section « Championships and accomplishments » de Wikipedia, brute ([{org, texte}]) : source, non affichée';
