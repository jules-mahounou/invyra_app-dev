// @ts-nocheck
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(status: number, payload: unknown) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
    },
  });
}

function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildEmailHtml(guestName: string, eventName: string, invitationUrl: string): string {
  const safeName = escapeHtml(guestName);
  const safeEvent = escapeHtml(eventName);
  return `
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
      <h2>Bonjour ${safeName} !</h2>
      <p>Vous êtes invité(e) à <strong>${safeEvent}</strong>.</p>
      <p>Voici votre billet d'accès personnel, à présenter à l'entrée :</p>
      <p style="text-align: center; margin: 24px 0;">
        <a href="${invitationUrl}" style="background:#5B21B6;color:#fff;padding:12px 24px;border-radius:999px;text-decoration:none;font-weight:bold;">
          Voir mon invitation
        </a>
      </p>
      <p style="color:#888;font-size:12px;">Créé avec Invyra</p>
    </div>
  `;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed' });
  }

  const authHeader = req.headers.get('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return jsonResponse(401, { error: 'Unauthorized' });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const resendApiKey = Deno.env.get('RESEND_API_KEY');
  const fromEmail = Deno.env.get('RESEND_FROM_EMAIL') || 'Invyra <onboarding@resend.dev>';

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse(500, { error: 'Missing Supabase environment variables' });
  }
  if (!resendApiKey) {
    return jsonResponse(500, { error: 'Missing RESEND_API_KEY environment variable' });
  }

  const jwt = authHeader.replace('Bearer ', '');
  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: userData, error: userError } = await supabaseAdmin.auth.getUser(jwt);
  if (userError || !userData.user) {
    return jsonResponse(401, { error: 'Invalid or expired session' });
  }
  const user = userData.user;

  let body: { event_id?: string; guest_ids?: string[] };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body' });
  }

  const eventId = body.event_id?.trim();
  if (!eventId) {
    return jsonResponse(400, { error: 'event_id is required' });
  }
  const guestIdsFilter = Array.isArray(body.guest_ids) ? body.guest_ids.filter(Boolean) : null;

  const { data: eventRow, error: eventError } = await supabaseAdmin
    .from('events')
    .select('id, name, user_id')
    .eq('id', eventId)
    .single();

  if (eventError || !eventRow) {
    return jsonResponse(404, { error: 'Event not found' });
  }
  if (eventRow.user_id !== user.id) {
    return jsonResponse(403, { error: 'Forbidden: event does not belong to this user' });
  }

  // Invitations déjà générées (billet + token) pour cet événement, avec l'email du invité.
  let query = supabaseAdmin
    .from('invitations')
    .select('id, public_token, status, guests(id, full_name, email)')
    .eq('event_id', eventId);
  if (guestIdsFilter && guestIdsFilter.length > 0) {
    query = query.in('guest_id', guestIdsFilter);
  }

  const { data: invitations, error: invitationsError } = await query;
  if (invitationsError) {
    return jsonResponse(500, { error: invitationsError.message });
  }

  const withEmail = (invitations ?? []).filter((inv) => {
    const guest = Array.isArray(inv.guests) ? inv.guests[0] : inv.guests;
    return !!guest?.email;
  });

  // Filet de sécurité côté serveur : même si l'app mobile valide déjà le
  // format à la saisie, on ne doit jamais envoyer une adresse mal formée à
  // l'API d'envoi (qui rejetterait alors tout le lot, y compris les emails
  // valides qu'il contient).
  const eligible = withEmail.filter((inv) => {
    const guest = Array.isArray(inv.guests) ? inv.guests[0] : inv.guests;
    return isValidEmail(guest.email);
  });
  const skippedInvalid = withEmail.length - eligible.length;

  if (eligible.length === 0) {
    return jsonResponse(200, { sent: 0, failed: 0, skippedInvalid });
  }

  const baseUrl = 'https://invyra-web.vercel.app/i/';
  const batchSize = 100; // limite de l'API batch de Resend

  let sentCount = 0;
  const sentInvitationIds: string[] = [];
  let lastFailureReason: string | null = null;

  for (let i = 0; i < eligible.length; i += batchSize) {
    const batchInvitations = eligible.slice(i, i + batchSize);
    const batchEmails = batchInvitations.map((inv) => {
      const guest = Array.isArray(inv.guests) ? inv.guests[0] : inv.guests;
      const invitationUrl = `${baseUrl}${inv.public_token}`;
      return {
        from: fromEmail,
        to: [guest.email],
        subject: `Votre invitation — ${eventRow.name}`,
        html: buildEmailHtml(guest.full_name ?? 'Invité', eventRow.name, invitationUrl),
      };
    });

    const response = await fetch('https://api.resend.com/emails/batch', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(batchEmails),
    });

    if (response.ok) {
      sentCount += batchInvitations.length;
      sentInvitationIds.push(...batchInvitations.map((inv) => inv.id));
    } else {
      // Détail technique gardé uniquement dans les logs serveur — jamais
      // renvoyé tel quel à l'utilisateur final.
      lastFailureReason = await response.text();
      console.error('Resend batch send failed:', lastFailureReason);
    }
  }

  if (sentInvitationIds.length > 0) {
    await supabaseAdmin
      .from('invitations')
      .update({ status: 'envoye', sent_at: new Date().toISOString() })
      .in('id', sentInvitationIds)
      .eq('status', 'brouillon');
  }

  if (sentCount === 0 && lastFailureReason) {
    return jsonResponse(502, {
      error: "Le service d'envoi d'email a rencontré un problème. Réessayez plus tard.",
    });
  }

  return jsonResponse(200, {
    sent: sentCount,
    failed: eligible.length - sentCount,
    skippedInvalid,
  });
});
