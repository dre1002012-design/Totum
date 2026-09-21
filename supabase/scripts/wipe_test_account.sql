-- Effacer proprement un compte de test à partir de son email (19/09/2026,
-- rendu défensif le 21/09/2026 après 2 échecs réels — voir plus bas).
--
-- Usage : à coller dans Supabase Studio → SQL Editor (projet "Totum",
-- réf yqcbawsszozouhlkxtsj), après avoir remplacé la valeur de
-- `target_email` ci-dessous. Supprime TOUTES les données applicatives liées
-- à ce compte, table par table (liste établie par grep de tous les
-- `.from('...')` Supabase du code Dart — à tenir à jour si une nouvelle
-- table utilisateur est ajoutée). Ne touche à aucune autre ligne.
--
-- Cette étape seule NE supprime PAS le compte d'authentification lui-même
-- (auth.users) : Supabase recommande de le faire via Authentication → Users
-- → chercher l'email → "Delete user" dans l'interface de Studio plutôt
-- qu'en SQL brut, car l'action de l'UI nettoie aussi les tables internes
-- d'auth (identities, sessions, refresh tokens) que ce script ne touche pas.
-- Faire donc : 1) ce script, 2) suppression du user dans Authentication →
-- Users. Une fois les deux faits, recréer un compte avec le même email
-- repart entièrement à zéro et redéclenche le parcours d'onboarding
-- (needsOnboarding() dans profile.dart ne trouve plus ni cache local ni
-- ligne user_profile).
--
-- Étape appareil (avant ou après ce script, l'ordre n'a pas d'importance) :
-- dans l'app, Compte → "Supprimer mon compte" (PAS "Se déconnecter", qui ne
-- vide pas le cache local) — vide SharedPreferences sur l'appareil de test
-- et déconnecte la session en cours.
--
-- Pourquoi une version défensive : la 1ʳᵉ tentative d'Alex a échoué sur
-- user_status (sa clé primaire est "id", pas "user_id" — corrigé), la 2ᵉ
-- sur account_deletion_requests, dont la migration n'a en fait jamais été
-- appliquée sur ce projet Supabase (table absente). Plutôt que corriger un
-- cas à la fois à chaque nouvel échec, chaque suppression ci-dessous est
-- maintenant encadrée : une table absente ou une colonne au nom différent
-- est signalée (raise notice) et SAUTÉE, sans jamais faire échouer tout le
-- bloc — les autres tables continuent d'être nettoyées normalement.

do $$
declare
  target_email text := 'REMPLACER_PAR_EMAIL@exemple.com';
  target_user_id uuid;
  -- (table, colonne portant l'id utilisateur) — user_status est la seule
  -- exception connue : sa clé primaire EST directement l'id auth.users
  -- (voir .eq('id', user.id) dans account_screen.dart/main.dart).
  targets text[][] := array[
    ['food_entries', 'user_id'],
    ['weight_log', 'user_id'],
    ['water_intake', 'user_id'],
    ['sun_vitamin_d', 'user_id'],
    ['holistic_log', 'user_id'],
    ['pause_periods', 'user_id'],
    ['score_history', 'user_id'],
    ['goal_snapshots', 'user_id'],
    ['favorite_foods', 'user_id'],
    ['custom_meals', 'user_id'],
    ['custom_foods', 'user_id'],
    ['recipes', 'user_id'],
    ['barcode_scan_misses', 'user_id'],
    ['play_purchases', 'user_id'],
    ['user_status', 'id'],
    ['account_deletion_requests', 'user_id'],
    ['user_profile', 'user_id']
  ];
  t text;
  c text;
  n int;
begin
  select id into target_user_id from auth.users where email = target_email;

  if target_user_id is null then
    raise notice 'Aucun compte auth.users trouvé pour %', target_email;
    return;
  end if;

  for i in 1 .. array_length(targets, 1) loop
    t := targets[i][1];
    c := targets[i][2];
    if to_regclass('public.' || t) is null then
      raise notice '  [ignoré] table public.% absente (migration jamais appliquée sur ce projet)', t;
      continue;
    end if;
    begin
      execute format('delete from public.%I where %I = $1', t, c) using target_user_id;
      get diagnostics n = row_count;
      raise notice '  [ok] public.% : % ligne(s) supprimée(s)', t, n;
    exception
      when undefined_column then
        raise notice '  [ignoré] public.% : colonne "%" introuvable (vérifier le vrai nom de colonne)', t, c;
      when undefined_table then
        raise notice '  [ignoré] public.% : table introuvable au moment de la suppression', t;
    end;
  end loop;

  raise notice 'Terminé pour % (user_id=%). Étape suivante : Authentication -> Users -> supprimer ce compte.', target_email, target_user_id;
end $$;
