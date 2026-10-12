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

  // --- Créer en UNE requête groupée les invitations manquantes, au lieu d'une
  // requête par invité (qui ne tient pas la charge sur une liste de centaines
  // d'invités : chaque await séquentiel ajoute de la latence réseau, avec un
  // risque de dépasser le temps d'exécution max de l'Edge Function). ---
  const guestsNeedingInvitation = guestIds.filter((id) => !existingByGuestId.has(id));

  let newInvitations: Array<{ id: string; guest_id: string; public_token: string }> = [];
  if (guestsNeedingInvitation.length > 0) {
    const rows = guestsNeedingInvitation.map((guestId) => ({
      event_id: eventId,
      guest_id: guestId,
      public_token: randomHex(16),
      channel,
      status: 'brouillon',
    }));

    const { data, error } = await supabaseAdmin
      .from('invitations')
      .insert(rows)
      .select('id, guest_id, public_token');

    if (error) {
      return jsonResponse(500, { error: error.message });
    }
    newInvitations = data ?? [];
  }

  type InvitationInfo = { invitationId: string; publicToken: string; qrCode: string | null };
  const infoByGuestId = new Map<string, InvitationInfo>();

  for (const [guestId, entry] of existingByGuestId) {
    const qrEntry = Array.isArray(entry.qr_codes) ? entry.qr_codes[0] : entry.qr_codes;
    infoByGuestId.set(guestId, {
      invitationId: entry.id,
      publicToken: entry.public_token,
      qrCode: qrEntry?.code ?? null,
    });
  }
  for (const inv of newInvitations) {
    infoByGuestId.set(inv.guest_id, {
      invitationId: inv.id,
      publicToken: inv.public_token,
      qrCode: null,
    });
  }

  // --- Même logique groupée pour les QR codes manquants ---
  const invitationsNeedingQr = Array.from(infoByGuestId.values()).filter((info) => !info.qrCode);

  if (invitationsNeedingQr.length > 0) {
    const qrRows = invitationsNeedingQr.map((info) => ({
      code: randomHex(32),
      invitation_id: info.invitationId,
      is_used: false,
    }));

    // ignoreDuplicates : si une requête concurrente a déjà créé le QR code
    // entre-temps, on ne l'écrase surtout pas (il pourrait déjà être partagé).
    const { error: qrInsertError } = await supabaseAdmin
      .from('qr_codes')
      .upsert(qrRows, { onConflict: 'invitation_id', ignoreDuplicates: true });

    if (qrInsertError) {
      return jsonResponse(500, { error: qrInsertError.message });
    }

    const invitationIds = invitationsNeedingQr.map((info) => info.invitationId);
    const { data: qrRows2, error: qrReadError } = await supabaseAdmin
      .from('qr_codes')
      .select('invitation_id, code')
      .in('invitation_id', invitationIds);

    if (qrReadError) {
      return jsonResponse(500, { error: qrReadError.message });
    }

    const codeByInvitationId = new Map((qrRows2 ?? []).map((r) => [r.invitation_id, r.code]));
    for (const info of invitationsNeedingQr) {
      info.qrCode = codeByInvitationId.get(info.invitationId) ?? info.qrCode;
    }
  }

  const results = guestIds.map((guestId) => {
    const info = infoByGuestId.get(guestId)!;
    return {
      guest_id: guestId,
      invitation_id: info.invitationId,
      qr_code: info.qrCode,
      invitation_url: `https://invyra-web.vercel.app/i/${info.publicToken}`,
      public_token: info.publicToken,
    };
  });

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
