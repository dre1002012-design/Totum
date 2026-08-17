-- Priorité 67 (17/08/2026) — Bilan 7/30/90j : l'objectif comparé pour un
-- jour passé était systématiquement l'objectif ACTUEL, jamais celui
-- réellement en vigueur ce jour-là (retour répété d'Alex : un objectif
-- recalculé aujourd'hui apparaît identique il y a 7/30/90 jours, faussant
-- entièrement l'écart moyen affiché).
--
-- La mécanique d'historisation elle-même (goals_snapshots_v1, voir
-- profile.dart _appendGoalsSnapshot / bilan_screen.dart _goalsRawForDay)
-- était déjà correctement écrite et déjà appelée à chaque sauvegarde de
-- profil — MAIS elle n'existait qu'en SharedPreferences local, jamais
-- synchronisée. Exactement la même cause racine, déjà rencontrée et
-- corrigée pour `weight_log` (voir calibration_service.dart) et
-- `custom_meals` (migration 20260811) : perdue à chaque réinstallation de
-- l'app — ce qui explique pourquoi le problème "revient" à chaque nouveau
-- test alors qu'il avait déjà été traité côté code.
--
-- À exécuter dans Supabase Studio → SQL Editor (projet "Totum",
-- réf yqcbawsszozouhlkxtsj) puis redéployer l'app. Le code Dart fonctionne
-- avant ET après cette migration (repli local silencieux si la table
-- n'existe pas encore), mais l'historique ne survit à une réinstallation /
-- un changement d'appareil qu'une fois cette migration appliquée.
create table if not exists public.goal_snapshots (
  user_id        uuid not null references auth.users(id) on delete cascade,
  date           date not null,
  kcal           double precision not null,
  prot           double precision not null,
  carb           double precision not null,
  fat            double precision not null,
  fiber          double precision not null,
  sat            double precision not null,
  o9             double precision not null,
  o6             double precision not null,
  o3             double precision not null,
  epa            double precision not null,
  dha            double precision not null,
  sugars         double precision not null,
  salt           double precision not null,
  ca_mg          double precision not null,
  cu_mg          double precision not null,
  fe_mg          double precision not null,
  i_ug           double precision not null,
  mg_mg          double precision not null,
  mn_mg          double precision not null,
  p_mg           double precision not null,
  k_mg           double precision not null,
  se_ug          double precision not null,
  na_mg          double precision not null,
  zn_mg          double precision not null,
  vit_a_ug       double precision not null,
  vit_betacar_ug double precision not null,
  vit_d_ug       double precision not null,
  vit_e_mg       double precision not null,
  vit_k_ug       double precision not null,
  vit_c_mg       double precision not null,
  b1_mg          double precision not null,
  b2_mg          double precision not null,
  b3_mg          double precision not null,
  b5_mg          double precision not null,
  b6_mg          double precision not null,
  b9_ug          double precision not null,
  b12_ug         double precision not null,
  updated_at     timestamptz not null default now(),
  primary key (user_id, date)
);

alter table public.goal_snapshots enable row level security;

create policy "goal_snapshots_select_own"
  on public.goal_snapshots for select
  using (auth.uid() = user_id);

create policy "goal_snapshots_insert_own"
  on public.goal_snapshots for insert
  with check (auth.uid() = user_id);

create policy "goal_snapshots_update_own"
  on public.goal_snapshots for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
