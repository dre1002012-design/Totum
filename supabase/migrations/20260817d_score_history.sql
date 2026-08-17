-- Priorité 71 (17/08/2026) — historique glissant du Score Totum (adéquation
-- nutritionnelle), pour afficher une tendance 7/30 jours plutôt qu'un seul
-- chiffre du jour (voir lib/services/totum_score.dart, recordScoreHistory /
-- fetchScoreHistory). Toujours une simple courbe de tendance, jamais une
-- notation de discipline/série à ne pas casser.
--
-- À exécuter dans Supabase Studio → SQL Editor (projet "Totum",
-- réf yqcbawsszozouhlkxtsj) puis redéployer l'app. Le code Dart fonctionne
-- avant ET après cette migration (repli local silencieux si la table
-- n'existe pas encore).
create table if not exists public.score_history (
  user_id    uuid not null references auth.users(id) on delete cascade,
  date       date not null,
  score      double precision not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, date)
);

alter table public.score_history enable row level security;

create policy "score_history_select_own"
  on public.score_history for select
  using (auth.uid() = user_id);

create policy "score_history_insert_own"
  on public.score_history for insert
  with check (auth.uid() = user_id);

create policy "score_history_update_own"
  on public.score_history for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
