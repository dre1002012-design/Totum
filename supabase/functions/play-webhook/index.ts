// supabase/functions/play-webhook/index.ts
// ─────────────────────────────────────────────────────────────────────
// Webhook Google Play RTDN (Real-time Developer Notifications) pour TOTUM.
//
// Trajet : Google Play → Pub/Sub → cette fonction. Google envoie un
// purchaseToken (pas l'état). La fonction interroge l'API Google Play
// Developer pour connaître l'état réel de l'abonnement, puis met à jour
// premium_until dans user_status (via la table de liaison play_purchases).
//
// Secrets requis (Edge Functions → Secrets) :
//   GOOGLE_SERVICE_ACCOUNT  = contenu JSON complet de la clé du compte de service
//   GOOGLE_PACKAGE_NAME     = com.totumapp.totum
//   (SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY sont injectés automatiquement)
//
// À déployer avec --no-verify-jwt (Pub/Sub appelle sans JWT Supabase).
// ─────────────────────────────────────────────────────────────────────

import { createClient } from 'npm:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);

const PACKAGE = Deno.env.get('GOOGLE_PACKAGE_NAME') ?? '';

/** Marge de grâce (jours) ajoutée à la date d'expiration Google. */
const GRACE_DAYS = 3;

// ── Récupère un access_token OAuth2 à partir de la clé du compte de service ──
async function getAccessToken(): Promise<string> {
  const saRaw = Deno.env.get('GOOGLE_SERVICE_ACCOUNT') ?? '';
  const sa = JSON.parse(saRaw);

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const enc = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

  const unsigned = `${enc(header)}.${enc(claim)}`;

  // Importer la clé privée PEM du compte de service
  const pem = sa.private_key as string;
  const der = pemToDer(pem);
  const key = await crypto.subtle.importKey(
    'pkcs8',
    der,
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

  const jwt = `${unsigned}.${sig}`;

  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const data = await resp.json();
  if (!data.access_token) {
    throw new Error('OAuth token error: ' + JSON.stringify(data));
  }
  return data.access_token;
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const bin = atob(b64);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}

// ── Interroge l'API Play pour l'état réel de l'abonnement ──────────────
async function getSubscriptionExpiry(
  token: string,
  subscriptionId: string,
  purchaseToken: string,
): Promise<number | null> {
  // API v2 : subscriptionsv2.get renvoie lineItems[].expiryTime
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${PACKAGE}/purchases/subscriptionsv2/tokens/${purchaseToken}`;
  const resp = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!resp.ok) {
    console.error('Play API error', resp.status, await resp.text());
    return null;
  }
  const data = await resp.json();
  // état : SUBSCRIPTION_STATE_ACTIVE, _CANCELED, _EXPIRED, _IN_GRACE_PERIOD…
  const state = data.subscriptionState ?? '';
  const items = data.lineItems ?? [];
  let latest: number | null = null;
  for (const it of items) {
    if (it.expiryTime) {
      const t = Date.parse(it.expiryTime);
      if (latest === null || t > latest) latest = t;
    }
  }
  // Actif ou en grâce → on garde l'expiry ; sinon on considère expiré
  const okStates = [
    'SUBSCRIPTION_STATE_ACTIVE',
    'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
    'SUBSCRIPTION_STATE_CANCELED', // annulé mais actif jusqu'à expiry
  ];
  if (!okStates.includes(state)) return null;
  return latest;
}

Deno.serve(async (req) => {
  try {
    const body = await req.json();
    // Message Pub/Sub : { message: { data: base64 }, subscription: ... }
    const dataB64 = body?.message?.data;
    if (!dataB64) {
      return new Response(JSON.stringify({ ok: true, skip: 'no data' }), {
        status: 200,
      });
    }
    const decoded = JSON.parse(atob(dataB64));
    // decoded.subscriptionNotification = { purchaseToken, subscriptionId, notificationType }
    const notif = decoded.subscriptionNotification;
    if (!notif) {
      // Autres types (test, voided…) → OK silencieux
      return new Response(JSON.stringify({ ok: true, skip: 'not a sub' }), {
        status: 200,
      });
    }

    const purchaseToken = notif.purchaseToken as string;
    const subscriptionId = notif.subscriptionId as string;

    // Retrouver l'utilisateur lié à ce token
    const { data: link } = await supabase
      .from('play_purchases')
      .select('user_id')
      .eq('purchase_token', purchaseToken)
      .maybeSingle();

    if (!link?.user_id) {
      // Achat pas encore enregistré côté app → on ignore proprement
      console.warn('play-webhook: token inconnu', purchaseToken);
      return new Response(JSON.stringify({ ok: true, skip: 'unknown token' }), {
        status: 200,
      });
    }

    // Interroger Google pour l'expiry réel
    const accessToken = await getAccessToken();
    const expiryMs = await getSubscriptionExpiry(
      accessToken,
      subscriptionId,
      purchaseToken,
    );

    if (expiryMs === null) {
      // Abonnement expiré/révoqué → on laisse premium_until tel quel
      // (il expirera naturellement). On pourrait aussi le forcer à maintenant.
      console.log('play-webhook: sub inactive pour', link.user_id);
      return new Response(JSON.stringify({ ok: true, inactive: true }), {
        status: 200,
      });
    }

    const until = new Date(expiryMs + GRACE_DAYS * 86400 * 1000);
    await supabase
      .from('user_status')
      .update({ premium_until: until.toISOString() })
      .eq('id', link.user_id);

    // Trace
    await supabase
      .from('play_purchases')
      .update({ subscription_id: subscriptionId, updated_at: new Date().toISOString() })
      .eq('purchase_token', purchaseToken);

    return new Response(JSON.stringify({ ok: true, until: until.toISOString() }), {
      status: 200,
    });
  } catch (e) {
    console.error('play-webhook error:', e);
    // 200 pour éviter les retries en boucle de Pub/Sub
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 200,
    });
  }
});