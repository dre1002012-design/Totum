-- Priorité 48 (13/08/2026) — Écran Paramètres : suppression de compte.
--
-- Aucune fonction serveur d'admin-delete n'existe côté Supabase (supprimer
-- réellement une ligne auth.users demande une clé de service, pas
-- accessible depuis le client Flutter). Cette table sert de file d'attente :
-- l'app y insère une ligne avec la clé anon (RLS restreinte à l'utilisateur
-- courant), puis se déconnecte et efface ses données locales. Le traitement
-- réel (suppression auth.users + données liées) reste à faire côté
-- Supabase Studio / Edge Function tant qu'aucune automatisation n'est en
-- place — cette table permet au moins de ne perdre aucune demande.
--
-- À exécuter dans Supabase Studio → SQL Editor (projet "Totum",
-- réf yqcbawsszozouhlkxtsj). Le code Dart (settings_screen.dart) fonctionne
-- avant ET après cette migration (insert échoue silencieusement si la table
-- n'existe pas encore, la déconnexion/le nettoyage local s'appliquent quand
-- même).
create table if not exists public.account_deletion_requests (
  user_id      uuid not null references auth.users(id) on delete cascade,
  requested_at timestamptz not null default now(),
  primary key (user_id)
);

alter table public.account_deletion_requests enable row level security;

create policy "account_deletion_requests_insert_own"
  on public.account_deletion_requests for insert
  with check (auth.uid() = user_id);

create policy "account_deletion_requests_select_own"
  on public.account_deletion_requests for select
  using (auth.uid() = user_id);
