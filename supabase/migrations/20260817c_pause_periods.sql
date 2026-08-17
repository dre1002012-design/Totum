-- Priorité 71 (17/08/2026) — retour d'Alex : "la personne part en
-- vacances, elle ne va pas se peser... est-ce que ça ne va pas impacter
-- le calcul global [de la calibration adaptative]... sans culpabiliser
-- la personne." Table des périodes de pause déclarées par l'utilisateur
-- (vacances, week-end, événement) — voir lib/services/pause_service.dart
-- et lib/services/calibration_service.dart (_isPausedOn).
--
-- À exécuter dans Supabase Studio → SQL Editor (projet "Totum",
-- réf yqcbawsszozouhlkxtsj) puis redéployer l'app. Le code Dart fonctionne
-- avant ET après cette migration (repli local silencieux si la table
-- n'existe pas encore).
create table if not exists public.pause_periods (
  user_id    uuid not null references auth.users(id) on delete cascade,
  start_date date not null,
  end_date   date, -- null = pause toujours en cours
  updated_at timestamptz not null default now(),
  primary key (user_id, start_date)
);

alter table public.pause_periods enable row level security;

create policy "pause_periods_select_own"
  on public.pause_periods for select
  using (auth.uid() = user_id);

create policy "pause_periods_insert_own"
  on public.pause_periods for insert
  with check (auth.uid() = user_id);

create policy "pause_periods_update_own"
  on public.pause_periods for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
