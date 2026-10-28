-- Audit 27/10/2026 (constats C1, C2, M4, E1, E4) — requêtes en LECTURE SEULE.
--
-- Usage : Supabase Studio → SQL Editor (projet "Totum", réf
-- yqcbawsszozouhlkxtsj). Exécuter chaque bloc séparément et conserver les
-- résultats (capture ou export CSV). Aucune de ces requêtes ne modifie quoi
-- que ce soit.

-- 1) C2 — RLS activée sur chaque table publique ? (attendu : true partout)
select c.relname as table_name, c.relrowsecurity as rls_enabled, c.relforcerowsecurity as rls_forced
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
order by c.relname;

-- 2) C2 — toutes les politiques (attendu : qual / with_check limités à
--    auth.uid() = user_id, ou = id pour user_status ; aucune politique
--    "true" ni ouverte au rôle anon)
select tablename, policyname, cmd, roles, qual, with_check
from pg_policies where schemaname = 'public'
order by tablename, cmd;

-- 3) C1 — le client (rôle authenticated) peut-il modifier les colonnes
--    d'accès de user_status ? Une ligne UPDATE sur is_premium /
--    premium_until / trial_start = contournement possible du paiement.
select grantee, privilege_type, column_name
from information_schema.column_privileges
where table_schema = 'public' and table_name in ('user_status', 'play_purchases')
  and grantee in ('anon', 'authenticated')
order by table_name, column_name, privilege_type;

-- 4) C1 — triggers éventuels protégeant user_status
select c.relname, t.tgname, pg_get_triggerdef(t.oid)
from pg_trigger t join pg_class c on c.oid = t.tgrelid
where c.relname in ('user_status', 'play_purchases') and not t.tgisinternal;

-- 5) M4 — valeur par défaut de trial_start et comptes sans date d'essai
--    (sans date, l'app ouvre l'accès indéfiniment — main.dart PremiumGate)
select column_name, data_type, column_default, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'user_status'
order by ordinal_position;

select count(*) filter (where trial_start is null) as sans_date_essai,
       count(*) filter (where is_premium)          as acces_a_vie,
       count(*) filter (where premium_until > now()) as abonnement_en_cours,
       count(*) as total
from public.user_status;

-- 6) E1 — accès à vie potentiellement accordés à tort : is_premium = true
--    alors que le compte a un abonnement Play enregistré. Les clients
--    historiques légitimes (achat unique 2,99 €/6,99 €, avant l'abonnement)
--    peuvent aussi apparaître ici s'ils se sont abonnés ensuite : à revoir
--    au cas par cas avant toute correction.
select s.id, s.is_premium, s.premium_until, s.stripe_customer_id,
       p.subscription_id, p.updated_at
from public.user_status s
join public.play_purchases p on p.user_id = s.id
where s.is_premium = true
order by p.updated_at desc;

-- 7) E4 — demandes de suppression en attente (RGPD : 1 mois maximum).
--    Si la table n'existe pas : la migration 20260813 n'a jamais été
--    appliquée, et aucune demande n'a jamais été enregistrée.
select count(*) as en_attente, min(requested_at) as plus_ancienne
from public.account_deletion_requests;

-- 8) E3 — tables existantes (migrations réellement appliquées ?)
select table_name from information_schema.tables
where table_schema = 'public' order by table_name;
