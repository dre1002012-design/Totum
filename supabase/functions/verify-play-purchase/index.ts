// supabase/functions/verify-play-purchase/index.ts
// ─────────────────────────────────────────────────────────────────────
// Audit 27/10/2026 (constat C1) — vérification SERVEUR d'un abonnement
// Google Play avant d'accorder l'accès Premium.
//
// Jusqu'ici l'app écrivait elle-même `premium_until` dans `user_status`
// (account_screen.dart, _activateSubscription) : n'importe quel compte
// connecté pouvait donc se donner l'accès par un simple appel REST. Cette
// fonction est désormais appelée par l'app à chaque achat/restauration :
//   1. identifie l'utilisateur par son JWT Supabase (jamais par le corps) ;
//   2. interroge l'API Google Play Developer (compte de service) ;
//   3. si l'abonnement est réellement actif, écrit `premium_until` et le lien
//      `play_purchases` avec la clé de service.
//
// Réponses (contrat attendu par l'app, voir _verifyOnServer) :
//   200 { ok: true, active: true,  premium_until }  → accès accordé
//   200 { ok: true, active: false, reason }         → Google dit inactif
//   4xx/5xx { ok: false, error }                    → l'app garde son repli
//
// Déploiement (AVEC vérification JWT, contrairement à play-webhook) :
//   supabase functions deploy verify-play-purchase
// Secrets requis (déjà présents pour play-webhook) :
//   GOOGLE_SERVICE_ACCOUNT, GOOGLE_PACKAGE_NAME
//   (SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY injectés automatiquement)
// ─────────────────────────────────────────────────────────────────────

import { createClient } from 'npm:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);

const PACKAGE = Deno.env.get('GOOGLE_PACKAGE_NAME') ?? '';

/** Même marge de grâce que play-webhook. */
const GRACE_DAYS = 3;

/** Seul produit vendu (voir _kSubProductId dans account_screen.dart). */
const ALLOWED_SUBSCRIPTIONS = ['totum_premium_annual'];

const ACTIVE_STATES = [
  'SUBSCRIPTION_STATE_ACTIVE',
  'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
  'SUBSCRIPTION_STATE_CANCELED', // résilié mais payé jusqu'à expiryTime
];

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

// ── access_token OAuth2 du compte de service (même code que play-webhook) ──
async function getAccessToken(): Promise<string> {
  const sa = JSON.parse(Deno.env.get('GOOGLE_SERVICE_ACCOUNT') ?? '');
  const now = Math.floor(Date.now() / 1000);
  const enc = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const unsigned = `${enc({ alg: 'RS256', typ: 'JWT' })}.${enc({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })}`;

  const b64 = (sa.private_key as string)
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const bin = atob(b64);
  const der = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) der[i] = bin.charCodeAt(i);

  const key = await crypto.subtle.importKey(
    'pkcs8',
    der.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sigBuf = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBuf)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${unsigned}.${sig}`,
  });
  const data = await resp.json();
  if (!data.access_token) throw new Error('OAuth token error');
  return data.access_token;
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') return json(405, { ok: false, error: 'method' });

    // 1) Utilisateur = celui du JWT, jamais un identifiant fourni par le client.
    const jwt = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
    const { data: auth, error: authError } = await supabase.auth.getUser(jwt);
    const userId = auth?.user?.id;
    if (authError || !userId) return json(401, { ok: false, error: 'auth' });

    const body = await req.json().catch(() => ({}));
    const purchaseToken = typeof body?.purchaseToken === 'string' ? body.purchaseToken : '';
    const subscriptionId = typeof body?.subscriptionId === 'string' ? body.subscriptionId : '';
    if (!purchaseToken || purchaseToken.length > 4096 ||
        !ALLOWED_SUBSCRIPTIONS.includes(subscriptionId)) {
      return json(400, { ok: false, error: 'bad_request' });
    }

    // 2) Un abonnement = un seul compte Totum.
    const { data: link } = await supabase
      .from('play_purchases')
      .select('user_id')
      .eq('purchase_token', purchaseToken)
      .maybeSingle();
    if (link?.user_id && link.user_id !== userId) {
      return json(200, { ok: true, active: false, reason: 'linked_to_other_account' });
    }

    // 3) État réel chez Google.
    const accessToken = await getAccessToken();
    const resp = await fetch(
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
        `${PACKAGE}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`,
      { headers: { Authorization: `Bearer ${accessToken}` } },
    );
    if (resp.status === 404 || resp.status === 410) {
      return json(200, { ok: true, active: false, reason: 'unknown_token' });
    }
    if (!resp.ok) {
      console.error('Play API error', resp.status, await resp.text());
      return json(502, { ok: false, error: 'play_api' });
    }
    const sub = await resp.json();
    const state = sub.subscriptionState ?? '';
    let expiry: number | null = null;
    let productMatches = false;
    for (const it of sub.lineItems ?? []) {
      if (it.productId === subscriptionId) productMatches = true;
      if (it.expiryTime) {
        const t = Date.parse(it.expiryTime);
        if (expiry === null || t > expiry) expiry = t;
      }
    }
    if (!productMatches || !ACTIVE_STATES.includes(state) ||
        expiry === null || expiry <= Date.now()) {
      return json(200, { ok: true, active: false, reason: state || 'inactive' });
    }

    // 4) Écritures avec la clé de service.
    const until = new Date(expiry + GRACE_DAYS * 86400 * 1000).toISOString();
    const { error: linkError } = await supabase.from('play_purchases').upsert(
      {
        purchase_token: purchaseToken,
        user_id: userId,
        subscription_id: subscriptionId,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'purchase_token' },
    );
    if (linkError) throw linkError;
    const { error: statusError } = await supabase
      .from('user_status')
      .upsert({ id: userId, premium_until: until }, { onConflict: 'id' });
    if (statusError) throw statusError;

    return json(200, { ok: true, active: true, premium_until: until });
  } catch (e) {
    console.error('verify-play-purchase error:', e);
    return json(500, { ok: false, error: 'internal' });
  }
});
