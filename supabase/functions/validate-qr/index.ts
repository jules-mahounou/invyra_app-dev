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

  let body: { qr_code?: string; event_id?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { error: 'Invalid JSON body' });
  }

  const qrCode = body.qr_code?.trim();
  const eventId = body.event_id?.trim();

  if (!qrCode || !eventId) {
    return jsonResponse(400, { error: 'qr_code and event_id are required' });
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

  const { data: qrRecord, error: qrError } = await supabaseAdmin
    .from('qr_codes')
    .select('id, code, is_used, used_at, invitation_id, invitations(id, event_id, guest_id, status, guests(full_name, phone, email))')
    .eq('code', qrCode)
    .maybeSingle();

  if (qrError) {
    return jsonResponse(500, { error: qrError.message });
  }

  if (!qrRecord) {
    return jsonResponse(200, {
      result: 'invalide',
      guest: null,
    });
  }

  const invitation = qrRecord.invitations;
  if (!invitation || invitation.event_id !== eventId) {
    return jsonResponse(200, {
      result: 'invalide',
      guest: null,
    });
  }

  const guest = invitation.guests;
  const now = new Date().toISOString();

  if (qrRecord.is_used) {
    await supabaseAdmin.from('event_scans').insert({
      event_id: eventId,
      guest_id: invitation.guest_id,
      result: 'deja_utilise',
      scanned_by: user.id,
      scanned_at: now,
    });

    return jsonResponse(200, {
      result: 'deja_utilise',
      guest: guest
        ? {
            full_name: guest.full_name,
            phone: guest.phone,
            email: guest.email,
          }
        : null,
    });
  }

  await supabaseAdmin
    .from('qr_codes')
    .update({ is_used: true, used_at: now })
    .eq('id', qrRecord.id);

  await supabaseAdmin
    .from('invitations')
    .update({ status: 'confirme', confirmed_at: now })
    .eq('id', invitation.id);

  const { data: currentEvent } = await supabaseAdmin
    .from('events')
    .select('guests_confirmed')
    .eq('id', eventId)
    .single();

  await supabaseAdmin
    .from('events')
    .update({ guests_confirmed: (currentEvent?.guests_confirmed ?? 0) + 1 })
    .eq('id', eventId);

  await supabaseAdmin.from('event_scans').insert({
    event_id: eventId,
    guest_id: invitation.guest_id,
    result: 'valide',
    scanned_by: user.id,
    scanned_at: now,
  });

  return jsonResponse(200, {
    result: 'valide',
    guest: guest
      ? {
          full_name: guest.full_name,
          phone: guest.phone,
          email: guest.email,
        }
      : null,
  });
});
