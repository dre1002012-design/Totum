-- Audit 27/10/2026 (constat C1) — PHASE 2 : retirer au client le droit de
-- s'attribuer lui-même l'accès Premium.
--
-- ⚠️ NE PAS EXÉCUTER AVANT D'AVOIR VALIDÉ, DANS CET ORDRE :
--   1. audit_rls_readonly.sql exécuté, résultats relus (noms de colonnes
--      réels de user_status / play_purchases identiques à ceux ci-dessous) ;
--   2. fonction verify-play-purchase DÉPLOYÉE et un achat de test (License
--      testing) débloqué PAR ELLE (logs de la fonction : 200, active: true) ;
--   3. version de l'app qui appelle verify-play-purchase publiée sur le Play
--      Store ET adoptée (Play Console → Statistiques → versions installées :
--      les anciennes versions écrivent premium_until elles-mêmes ; après ce
--      script, un ACHAT fait depuis une ancienne version ne débloquerait plus
--      l'accès tant que l'utilisateur n'a pas mis l'app à jour).
--   L'idéal : imposer la mise à jour (version minimale) avant ce script.
--
-- Ce fichier est volontairement hors de supabase/migrations/ : il ne doit
-- jamais être appliqué automatiquement par un outil.
--
-- Effet : le rôle authenticated (l'app) peut toujours LIRE son statut et
-- CRÉER sa ligne (id seul — c'est tout ce qu'envoient main.dart et
-- auth_screen.dart), mais plus écrire is_premium, premium_until,
-- trial_start, stripe_customer_id, ni lier un purchaseToken. Ces écritures
-- sont désormais réservées aux fonctions serveur (clé de service, qui
-- contourne ces privilèges) : verify-play-purchase, play-webhook,
-- stripe-webhook.

begin;

alter table public.user_status enable row level security;
alter table public.play_purchases enable row level security;

-- Nouvel utilisateur : l'essai démarre à la création de la ligne (M4 :
-- sans date, PremiumGate ouvre l'accès indéfiniment).
alter table public.user_status alter column trial_start set default now();

revoke insert, update, delete on public.user_status from anon, authenticated;
grant select on public.user_status to authenticated;
-- upsert({'id': ...}, onConflict: 'id') de l'app = INSERT (id) ... ON
-- CONFLICT (id) DO UPDATE SET id = excluded.id → droits sur la seule
-- colonne id.
grant insert (id), update (id) on public.user_status to authenticated;

revoke insert, update, delete on public.play_purchases from anon, authenticated;

commit;

-- Contrôle immédiat (doit ne lister que SELECT, et INSERT/UPDATE sur id) :
-- select grantee, privilege_type, column_name from information_schema.column_privileges
-- where table_schema='public' and table_name='user_status' and grantee='authenticated';

-- ─── Optionnel, décision produit : donner une date d'essai aux comptes
-- existants qui n'en ont pas (ils passeraient au Paywall 7 jours plus tard).
-- update public.user_status set trial_start = now()
-- where trial_start is null and not coalesce(is_premium, false)
--   and (premium_until is null or premium_until < now());

-- ─── RETOUR ARRIÈRE (si un achat légitime ne débloque plus l'accès) ───
-- begin;
-- grant insert, update on public.user_status to authenticated;
-- grant insert, update on public.play_purchases to authenticated;
-- commit;
