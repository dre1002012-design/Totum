// supabase/functions/stripe-webhook/index.ts
// ─────────────────────────────────────────────────────────────────────
// Webhook Stripe TOTUM — gère :
//  • l'ancien paiement unique (mode 'payment')      → is_premium = true (accès à vie)
//  • le nouvel abonnement annuel (mode 'subscription') → premium_until = fin de période + 3 j de grâce
//
// Identification de l'utilisateur :
//  1. client_reference_id (uid Supabase transmis par le paywall) — fiable
//  2. sinon email du payeur — secours
//  3. renouvellements : match par stripe_customer_id stocké au 1er paiement
//
// Secrets requis (Edge Functions → Secrets) :
//  STRIPE_SECRET_KEY      (sk_live_...)
//  STRIPE_WEBHOOK_SECRET  (whsec_... de l'endpoint)
//  SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY sont injectés automatiquement.
// ─────────────────────────────────────────────────────────────────────

import Stripe from 'npm:stripe@17';
import { createClient } from 'npm:@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2024-06-20',
});

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);

const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? '';

/** Marge de grâce après la fin de période payée (renouvellements tardifs). */
const GRACE_DAYS = 3;

/** Retrouve l'uid Supabase à partir d'un email (parcourt les utilisateurs). */
async function findUserIdByEmail(email: string): Promise<string | null> {
  if (!email) return null;
  let page = 1;
  while (page <= 20) {
    const { data, error } = await supabase.auth.admin.listUsers({
      page,
      perPage: 200,
    });
    if (error || !data?.users?.length) break;
    const u = data.users.find(
      (x) => (x.email ?? '').toLowerCase() === email.toLowerCase(),
    );
    if (u) return u.id;
    if (data.users.length < 200) break;
    page++;
  }
  return null;
}

/** Ancien produit : paiement unique → accès à vie. */
async function setLifetime(userId: string) {
  await supabase.from('user_status').upsert(
    { id: userId, is_premium: true },
    { onConflict: 'id' },
  );
}

/** Abonnement : fixe premium_until (fin de période + grâce). */
async function setSubscription(
  userId: string,
  periodEndSec: number | null,
  customerId: string | null,
) {
  const end = periodEndSec
    ? new Date((periodEndSec + GRACE_DAYS * 86400) * 1000)
    : new Date(Date.now() + (365 + GRACE_DAYS) * 86400 * 1000);

  await supabase.from('user_status').upsert(
    {
      id: userId,
      premium_until: end.toISOString(),
      ...(customerId ? { stripe_customer_id: customerId } : {}),
    },
    { onConflict: 'id' },
  );
}

Deno.serve(async (req) => {
  const signature = req.headers.get('stripe-signature');
  const body = await req.text();

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature ?? '',
      webhookSecret,
    );
  } catch (err) {
    console.error('Signature Stripe invalide:', err);
    return new Response('Bad signature', { status: 400 });
  }

  try {
    switch (event.type) {
      // ── Paiement initial (unique OU 1re année d'abonnement) ────────
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session;
        const email =
          session.customer_details?.email ?? session.customer_email ?? '';
        const customerId =
          typeof session.customer === 'string'
            ? session.customer
            : (session.customer as Stripe.Customer | null)?.id ?? null;

        const userId =
          session.client_reference_id || (await findUserIdByEmail(email));
        if (!userId) {
          console.error('checkout: utilisateur introuvable pour', email);
          break; // 200 quand même pour éviter les retries en boucle
        }

        if (session.mode === 'subscription') {
          // premium_until provisoire ; invoice.paid (qui suit) l'affine.
          await setSubscription(userId, null, customerId);
        } else {
          // Compatibilité ancien produit 2,99 € / 6,99 € : accès à vie.
          await setLifetime(userId);
        }
        break;
      }

      // ── Factures payées : 1er paiement ET renouvellements annuels ──
      case 'invoice.paid': {
        const invoice = event.data.object as Stripe.Invoice;
        const customerId =
          typeof invoice.customer === 'string'
            ? invoice.customer
            : (invoice.customer as Stripe.Customer | null)?.id ?? null;
        const periodEnd = invoice.lines?.data?.[0]?.period?.end ?? null;
        const email = invoice.customer_email ?? '';

        // 1) match fiable par stripe_customer_id
        let userId: string | null = null;
        if (customerId) {
          const { data } = await supabase
            .from('user_status')
            .select('id')
            .eq('stripe_customer_id', customerId)
            .maybeSingle();
          userId = (data?.id as string | undefined) ?? null;
        }
        // 2) secours par email
        if (!userId) userId = await findUserIdByEmail(email);

        if (!userId) {
          console.error(
            'invoice.paid: utilisateur introuvable',
            customerId,
            email,
          );
          break;
        }
        await setSubscription(userId, periodEnd, customerId);
        break;
      }

      default:
        // Événements non gérés → OK silencieux
        break;
    }
  } catch (err) {
    console.error('Erreur traitement webhook:', err);
    // On répond 200 pour éviter que Stripe ne réessaie en boucle.
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' },
    status: 200,
  });
});