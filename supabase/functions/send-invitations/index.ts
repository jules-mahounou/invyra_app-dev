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

function randomHex(bytes: number) {
  const array = new Uint8Array(bytes);
  crypto.getRandomValues(array);
  return Array.from(array, (value) => value.toString(16).padStart(2, '0')).join('');
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

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse(500, { error: 'Missing Supabase environment variables' });
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

  let body: { event_id?: string; guest_ids?: string[]; channel?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body' });
  }

  const eventId = body.event_id?.trim();
  const guestIds = Array.isArray(body.guest_ids) ? body.guest_ids.filter(Boolean) : [];
  const channel = body.channel?.trim() || 'whatsapp';

  if (!eventId || guestIds.length === 0) {
    return jsonResponse(400, { error: 'event_id and guest_ids are required' });
  }

  const { data: eventRow, error: eventError } = await supabaseAdmin
    .from('events')
    .select('id, user_id')
    .eq('id', eventId)
    .single();

  if (eventError || !eventRow) {
    return jsonResponse(404, { error: 'Event not found' });
  }

  if (eventRow.user_id !== user.id) {
    return jsonResponse(403, { error: 'Forbidden: event does not belong to this user' });
  }

  const { data: existingInvitations, error: existingError } = await supabaseAdmin
    .from('invitations')
    .select('id, guest_id, public_token, qr_codes(code)')
    .eq('event_id', eventId)
    .in('guest_id', guestIds);

  if (existingError) {
    return jsonResponse(500, { error: existingError.message });
  }

  const existingByGuestId = new Map(
    (existingInvitations ?? []).map((entry) => [entry.guest_id, entry]),
  );

  const results = [] as Array<{
    guest_id: string;
    invitation_id: string;
    qr_code: string | null;
    invitation_url: string;
    public_token: string;
  }>;

  for (const guestId of guestIds) {
    const existing = existingByGuestId.get(guestId);

    if (existing) {
      // qr_codes est un tableau côté PostgREST — prendre le premier élément
      const qrEntry = Array.isArray(existing.qr_codes)
        ? existing.qr_codes[0]
        : existing.qr_codes;
      const qrCode = qrEntry?.code ?? null;

      // Si l'invitation existe mais n'a pas encore de QR code, on le crée
      if (!qrCode) {
        const qrUpsert = await supabaseAdmin
          .from('qr_codes')
          .upsert({
            code: randomHex(32),
            invitation_id: existing.id,
            is_used: false,
          }, { onConflict: 'invitation_id' })
          .select('code')
          .single();

        const finalQrCode = qrUpsert.data?.code ?? null;
        results.push({
          guest_id: guestId,
          invitation_id: existing.id,
          qr_code: finalQrCode,
          invitation_url: `https://invyra-web.vercel.app/i/${existing.public_token}`,
          public_token: existing.public_token,
        });
      } else {
        results.push({
          guest_id: guestId,
          invitation_id: existing.id,
          qr_code: qrCode,
          invitation_url: `https://invyra-web.vercel.app/i/${existing.public_token}`,
          public_token: existing.public_token,
        });
      }
      continue;
    }

    const invitationInsert = await supabaseAdmin
      .from('invitations')
      .insert({
        event_id: eventId,
        guest_id: guestId,
        public_token: randomHex(16),
        channel,
        status: 'brouillon',
      })
      .select('id, public_token')
      .single();

    if (invitationInsert.error || !invitationInsert.data) {
      return jsonResponse(500, { error: invitationInsert.error?.message ?? 'Unable to create invitation' });
    }

    const newInvitationId = invitationInsert.data.id;
    const newPublicToken = invitationInsert.data.public_token;

    // Tenter d'insérer le QR code — ignorer si déjà existant (doublon sur invitation_id)
    await supabaseAdmin
      .from('qr_codes')
      .insert({
        code: randomHex(32),
        invitation_id: newInvitationId,
        is_used: false,
      })
      .select('code')
      .single();

    // Relire le QR code réel en base (qu'il vienne d'être créé ou existait déjà)
    const qrRead = await supabaseAdmin
      .from('qr_codes')
      .select('code')
      .eq('invitation_id', newInvitationId)
      .single();

    const finalCode = qrRead.data?.code ?? null;

    results.push({
      guest_id: guestId,
      invitation_id: newInvitationId,
      qr_code: finalCode,
      invitation_url: `https://invyra-web.vercel.app/i/${newPublicToken}`,
      public_token: newPublicToken,
    });
  }

  const { count, error: countError } = await supabaseAdmin
    .from('invitations')
    .select('id', { count: 'exact', head: true })
    .eq('event_id', eventId);

  if (countError) {
    return jsonResponse(500, { error: countError.message });
  }

  const { error: updateEventError } = await supabaseAdmin
    .from('events')
    .update({ invitations_sent: count ?? 0 })
    .eq('id', eventId);

  if (updateEventError) {
    return jsonResponse(500, { error: updateEventError.message });
  }

  return jsonResponse(200, { results });
});
