-- Effacer proprement un compte de test à partir de son email (19/09/2026).
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

do $$
declare
  target_email text := 'REMPLACER_PAR_EMAIL@exemple.com';
  target_user_id uuid;
begin
  select id into target_user_id from auth.users where email = target_email;

  if target_user_id is null then
    raise notice 'Aucun compte auth.users trouvé pour %', target_email;
    return;
  end if;

  delete from public.food_entries          where user_id = target_user_id;
  delete from public.weight_log            where user_id = target_user_id;
  delete from public.water_intake          where user_id = target_user_id;
  delete from public.sun_vitamin_d         where user_id = target_user_id;
  delete from public.holistic_log          where user_id = target_user_id;
  delete from public.pause_periods         where user_id = target_user_id;
  delete from public.score_history         where user_id = target_user_id;
  delete from public.goal_snapshots        where user_id = target_user_id;
  delete from public.favorite_foods        where user_id = target_user_id;
  delete from public.custom_meals          where user_id = target_user_id;
  delete from public.custom_foods          where user_id = target_user_id;
  delete from public.recipes               where user_id = target_user_id;
  delete from public.barcode_scan_misses   where user_id = target_user_id;
  delete from public.play_purchases        where user_id = target_user_id;
  -- user_status est la seule exception : sa clé primaire EST directement
  -- l'id auth.users (voir .eq('id', user.id) dans account_screen.dart/
  -- main.dart), pas une colonne user_id séparée.
  delete from public.user_status           where id = target_user_id;
  delete from public.account_deletion_requests where user_id = target_user_id;
  delete from public.user_profile          where user_id = target_user_id;

  raise notice 'Données applicatives effacées pour % (user_id=%). Étape suivante : Authentication -> Users -> supprimer ce compte.', target_email, target_user_id;
end $$;
