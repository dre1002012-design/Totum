-- Priorité 32 (11/08/2026) — 2 causes racines confirmées par sondage direct
-- de l'API REST (clé anon, lecture seule, aucune donnée modifiée) :
--
-- 1. La table `custom_meals` n'existe pas du tout (404 sur un simple
--    select). Le code Dart (_CustomMealsStore, journal_screen.dart) est déjà
--    écrit pour la synchroniser correctement ; il échoue juste silencieusement
--    faute de table, et un "plat perso" créé/renommé/mis en favori ne survit
--    donc qu'en local (SharedPreferences) — perdu à la moindre réinstallation.
--
-- 2. `custom_foods` existe mais n'a pas les colonnes image_url/nova_score/
--    nova_estime. La photo d'un aliment scanné (Open Food Facts) ne survivait
--    donc qu'en local elle aussi — perdue à la réinstallation, même après
--    mise en favori.
--
-- À exécuter dans Supabase Studio → SQL Editor (projet "Totum",
-- réf yqcbawsszozouhlkxtsj) puis redéployer l'app. Le code Dart est déjà
-- écrit pour les deux cas (fonctionne avant ET après cette migration, sans
-- redéploiement obligatoire pour éviter la casse, mais la persistance
-- cross-appareil/réinstallation n'est réellement effective qu'une fois cette
-- migration appliquée).

-- ─────────────────────────────────────────────────────────────────────────
-- 1) Table custom_meals — même forme que la table custom_foods déjà en
--    place (id texte fourni par le client, pas de colonne "created_at"
--    exigée par le code actuel, RLS strictement par utilisateur).
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists public.custom_meals (
  user_id     uuid not null references auth.users(id) on delete cascade,
  id          text not null,
  name        text not null,
  description text not null default '',
  items       jsonb not null default '[]'::jsonb,
  updated_at  timestamptz not null default now(),
  primary key (user_id, id)
);

alter table public.custom_meals enable row level security;

create policy "custom_meals_select_own"
  on public.custom_meals for select
  using (auth.uid() = user_id);

create policy "custom_meals_insert_own"
  on public.custom_meals for insert
  with check (auth.uid() = user_id);

create policy "custom_meals_update_own"
  on public.custom_meals for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "custom_meals_delete_own"
  on public.custom_meals for delete
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────
-- 2) Colonnes photo/NOVA manquantes sur custom_foods (aliments personnels +
--    aliments scannés Open Food Facts, favoris compris).
-- ─────────────────────────────────────────────────────────────────────────
alter table public.custom_foods
  add column if not exists image_url    text,
  add column if not exists nova_score   integer,
  add column if not exists nova_estime  boolean not null default false;
