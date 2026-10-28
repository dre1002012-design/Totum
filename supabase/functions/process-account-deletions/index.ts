// supabase/functions/process-account-deletions/index.ts
// ─────────────────────────────────────────────────────────────────────
// Audit 27/10/2026 (constat E4) — traitement EFFECTIF des demandes de
// suppression de compte enregistrées par l'app dans
// `account_deletion_requests` (Compte → Supprimer mon compte). Jusqu'ici
// aucune automatisation n'existait : la demande attendait un traitement
// manuel, alors que l'app et la politique de confidentialité promettent
// une suppression (RGPD art. 17 : 1 mois maximum — l'app annonce 30 jours).
//
// Pour chaque demande : suppression des données de chaque table
// utilisateur (même liste que supabase/scripts/wipe_test_account.sql —
// à tenir à jour ensemble), puis du compte d'authentification
// (auth.admin.deleteUser, qui nettoie aussi sessions/identités). Une table
// absente est ignorée ; toute autre erreur laisse la demande en file pour
// le passage suivant (jamais un compte supprimé à moitié puis oublié).
//
// Appel (manuel ou planifié, ex. pg_cron + pg_net 1×/jour) :
//   POST /functions/v1/process-account-deletions
//   Header  x-deletion-secret: <ACCOUNT_DELETION_SECRET>
//   Corps   { "dryRun": true }   ← simulation : liste sans rien supprimer
//
// Déploiement : supabase functions deploy process-account-deletions --no-verify-jwt
// Secret requis : ACCOUNT_DELETION_SECRET (longue chaîne aléatoire)
// ─────────────────────────────────────────────────────────────────────

import { createClient } from 'npm:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);

const SECRET = Deno.env.get('ACCOUNT_DELETION_SECRET') ?? '';

/** (table, colonne portant l'id utilisateur). account_deletion_requests
 *  en dernier : la demande ne disparaît qu'une fois tout le reste effacé. */
const TARGETS: [string, string][] = [
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
  ['user_profile', 'user_id'],
  ['user_status', 'id'],
];

/** Codes « table/colonne inexistante » (PostgreSQL et PostgREST). */
function isMissingRelation(code: string | undefined): boolean {
  return code === '42P01' || code === 'PGRST205' || code === '42703' || code === 'PGRST204';
}

/** Comparaison à temps constant du secret. */
function safeEqual(a: string, b: string): boolean {
  if (!a || a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

async function deleteUser(userId: string): Promise<string[]> {
  const log: string[] = [];
  for (const [table, column] of TARGETS) {
    const { error, count } = await supabase
      .from(table)
      .delete({ count: 'exact' })
      .eq(column, userId);
    if (error) {
      if (isMissingRelation(error.code)) {
        log.push(`${table}: ignorée (${error.code})`);
        continue;
      }
      throw new Error(`${table}: ${error.code} ${error.message}`);
    }
    log.push(`${table}: ${count ?? 0}`);
  }
  const { error: authError } = await supabase.auth.admin.deleteUser(userId);
  // Compte déjà absent (supprimé à la main entre-temps) : on considère fait.
  if (authError && authError.status !== 404) throw authError;
  log.push('auth.users: supprimé');
  await supabase.from('account_deletion_requests').delete().eq('user_id', userId);
  return log;
}

Deno.serve(async (req) => {
  if (!SECRET || !safeEqual(req.headers.get('x-deletion-secret') ?? '', SECRET)) {
    return new Response('Forbidden', { status: 403 });
  }
  const body = await req.json().catch(() => ({}));
  const dryRun = body?.dryRun === true;

  const { data: requests, error } = await supabase
    .from('account_deletion_requests')
    .select('user_id, requested_at')
    .order('requested_at', { ascending: true })
    .limit(100);
  if (error) {
    return new Response(JSON.stringify({ ok: false, error: error.message }), { status: 500 });
  }

  const results: unknown[] = [];
  for (const r of requests ?? []) {
    if (dryRun) {
      results.push({ user_id: r.user_id, requested_at: r.requested_at, dryRun: true });
      continue;
    }
    try {
      results.push({ user_id: r.user_id, ok: true, log: await deleteUser(r.user_id) });
    } catch (e) {
      console.error('process-account-deletions:', r.user_id, e);
      results.push({ user_id: r.user_id, ok: false, error: String(e) });
    }
  }
  return new Response(JSON.stringify({ ok: true, dryRun, processed: results }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
