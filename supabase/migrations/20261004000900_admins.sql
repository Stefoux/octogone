-- =============================================================================
-- Attribution du rôle admin (2 comptes)
--
-- Remplace ADMIN_EMAIL_1 et ADMIN_EMAIL_2 par les deux adresses admin, OU
-- renseigne ADMIN_EMAIL_1 / ADMIN_EMAIL_2 dans le fichier .env : le script
-- scripts/supabase_setup.sh les insère alors sans les écrire dans un fichier
-- versionné.
--
-- Un compte dont l'email figure ici devient admin à l'inscription (trigger
-- handle_new_user) ; un compte déjà créé est promu tout de suite.
-- Tant que les valeurs de démonstration ne sont pas remplacées, personne ne
-- peut s'en servir (ce ne sont pas des adresses valides).
-- =============================================================================

insert into public.admin_emails (email)
values (lower('ADMIN_EMAIL_1')), (lower('ADMIN_EMAIL_2'))
on conflict (email) do nothing;

-- Promotion des comptes existants dont l'email est listé.
create or replace function public.sync_admin_roles()
returns void language sql security definer set search_path = '' as $$
  insert into public.user_roles (user_id, role)
  select u.id, 'admin'::public.app_role
  from auth.users u
  join public.admin_emails a on a.email = lower(u.email)
  on conflict (user_id) do update set role = 'admin', granted_at = now();
$$;
revoke all on function public.sync_admin_roles() from public, anon, authenticated;

select public.sync_admin_roles();
