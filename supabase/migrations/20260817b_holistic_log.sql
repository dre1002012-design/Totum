-- Priorité 69 (17/08/2026) — retour d'Alex : "il ne garde pas en mémoire
-- [le sommeil/stress] ... à chaque désinstallation/réinstallation, il n'a
-- pas pris en compte mon sommeil et mon stress." Même cause racine que
-- goal_snapshots (migration 20260817) et weight_log avant elle : le
-- sommeil/stress/eau saisis dans Conseils (_saveHolisticLog /
-- _readHolisticLog, conseils_screen.dart) n'existaient qu'en
-- SharedPreferences local, sous des clés datées (holistic_sleep_h_YYYY-MM-DD
-- etc.) — jamais synchronisées, donc perdues à chaque réinstallation ou
-- changement d'appareil.
--
-- À exécuter dans Supabase Studio → SQL Editor (projet "Totum",
-- réf yqcbawsszozouhlkxtsj) puis redéployer l'app. Le code Dart fonctionne
-- avant ET après cette migration (repli local silencieux si la table
-- n'existe pas encore).
create table if not exists public.holistic_log (
  user_id      uuid not null references auth.users(id) on delete cascade,
  date         date not null,
  sleep_hours  double precision,
  water_liters double precision,
  stress       integer,
  updated_at   timestamptz not null default now(),
  primary key (user_id, date)
);

alter table public.holistic_log enable row level security;

create policy "holistic_log_select_own"
  on public.holistic_log for select
  using (auth.uid() = user_id);

create policy "holistic_log_insert_own"
  on public.holistic_log for insert
  with check (auth.uid() = user_id);

create policy "holistic_log_update_own"
  on public.holistic_log for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
