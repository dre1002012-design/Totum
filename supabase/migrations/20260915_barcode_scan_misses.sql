-- Audit scanner (15/09/2026, voir docs/AUDIT_SCANNER_BASE_ALIMENTS.md) :
-- mesure du taux d'échec réel des scans (ni Open Food Facts ni USDA Branded
-- Foods ne connaissent le produit) — étape 1 avant d'envisager une 3ᵉ source
-- payante, pour décider avec des données réelles plutôt qu'à l'aveugle.
-- Voir lib/screens/journal_screen.dart (_logBarcodeMiss).
--
-- À exécuter dans Supabase Studio → SQL Editor (projet "Totum",
-- réf yqcbawsszozouhlkxtsj). Le code Dart fonctionne avant ET après cette
-- migration (échec silencieux si la table n'existe pas encore — la mesure
-- est best-effort, jamais bloquante pour l'utilisateur).
create table if not exists public.barcode_scan_misses (
  id         bigint generated always as identity primary key,
  user_id    uuid references auth.users(id) on delete set null,
  barcode    text not null,
  created_at timestamptz not null default now()
);

alter table public.barcode_scan_misses enable row level security;

-- Écriture seule côté client (chaque utilisateur ne peut insérer que ses
-- propres échecs) ; pas de policy SELECT — la lecture/l'agrégation se fait
-- depuis Supabase Studio (rôle service, contourne RLS), pas depuis l'app.
create policy "barcode_scan_misses_insert_own"
  on public.barcode_scan_misses for insert
  with check (auth.uid() = user_id);
