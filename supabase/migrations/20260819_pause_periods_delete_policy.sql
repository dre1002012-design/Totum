-- 19/08/2026 — comble un trou de la migration 20260817c_pause_periods.sql :
-- aucune politique RLS n'autorisait DELETE sur pause_periods (seulement
-- select/insert/update), ce qui a fait échouer silencieusement une
-- suppression tentée côté app (voir lib/services/pause_service.dart,
-- endActivePause() — le bug et son contournement complet sont documentés
-- là-bas). Le contournement (mise à jour vers un intervalle vide plutôt que
-- suppression) fonctionne déjà SANS cette migration — celle-ci n'est donc
-- PAS bloquante, elle sert juste à permettre un vrai DELETE si un futur
-- besoin s'en présente, et à pouvoir nettoyer manuellement d'anciennes
-- lignes depuis Supabase Studio si souhaité.
--
-- À exécuter dans Supabase Studio → SQL Editor (projet "Totum",
-- réf yqcbawsszozouhlkxtsj) — optionnel, aucune conséquence si non appliquée.
create policy "pause_periods_delete_own"
  on public.pause_periods for delete
  using (auth.uid() = user_id);
