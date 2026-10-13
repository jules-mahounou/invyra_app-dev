import 'package:supabase_flutter/supabase_flutter.dart';

class InvitationResult {
  const InvitationResult({
    required this.guestId,
    required this.invitationId,
    required this.invitationUrl,
    required this.publicToken,
    this.qrCode,
  });

  final String guestId;
  final String invitationId;
  final String? qrCode;
  final String invitationUrl;
  final String publicToken;

  factory InvitationResult.fromJson(Map<String, dynamic> json) {
    return InvitationResult(
      guestId: json['guest_id']?.toString() ?? '',
      invitationId: json['invitation_id']?.toString() ?? '',
      qrCode: json['qr_code']?.toString(),
      invitationUrl: json['invitation_url']?.toString() ?? '',
      publicToken: json['public_token']?.toString() ?? '',
    );
  }
}

class GuestSummary {
  const GuestSummary({
    required this.fullName,
    this.phone,
    this.email,
  });

  final String fullName;
  final String? phone;
  final String? email;

  factory GuestSummary.fromJson(Map<String, dynamic> json) {
    return GuestSummary(
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class QrValidationResult {
  const QrValidationResult({
    required this.result,
    this.guest,
  });

  final String result;
  final GuestSummary? guest;

  factory QrValidationResult.fromJson(Map<String, dynamic> json) {
    final guestJson = json['guest'];
    return QrValidationResult(
      result: json['result']?.toString() ?? 'invalide',
      guest: guestJson is Map
          ? GuestSummary.fromJson(Map<String, dynamic>.from(guestJson))
          : null,
    );
  }
}

class EdgeFunctionService {
  const EdgeFunctionService();

  Future<List<InvitationResult>> sendInvitations({
    required String eventId,
    required List<String> guestIds,
    String channel = 'whatsapp',
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-invitations',
        body: {
          'event_id': eventId,
          'guest_ids': guestIds,
          'channel': channel,
        },
      );

      final payload = response.data;
      if (payload is! Map) {
        return const <InvitationResult>[];
      }

      // Conversion sécurisée de l'objet Map global
      final safePayload = Map<String, dynamic>.from(payload);
      final results = safePayload['results'];

      if (results is! List) {
        return const <InvitationResult>[];
      }

      // Conversion sécurisée de chaque élément de la liste
      return results.map((item) {
        if (item is Map) {
          return InvitationResult.fromJson(Map<String, dynamic>.from(item));
        }
        return null;
      })
      .whereType<InvitationResult>() // Élimine les éventuels éléments nulls
      .toList(growable: false);

    } on FunctionException catch (error) {
      throw Exception('Erreur Edge Function send-invitations : ${error.details?.toString() ?? error.toString()}');
    } catch (error) {
      throw Exception('Erreur lors de l’appel send-invitations : $error');
    }
  }

  /// Résultat de l'envoi groupé d'emails d'invitation.
  Future<({int sent, int failed, int skippedInvalid})> sendInvitationEmails({
    required String eventId,
    List<String>? guestIds,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-invitation-emails',
        body: {
          'event_id': eventId,
          'guest_ids': guestIds,
        },
      );

      final payload = response.data;
      if (payload is! Map) {
        return (sent: 0, failed: 0, skippedInvalid: 0);
      }
      final safePayload = Map<String, dynamic>.from(payload);
      return (
        sent: (safePayload['sent'] as num?)?.toInt() ?? 0,
        failed: (safePayload['failed'] as num?)?.toInt() ?? 0,
        skippedInvalid: (safePayload['skippedInvalid'] as num?)?.toInt() ?? 0,
      );
    } on FunctionException catch (error) {
      // L'Edge Function renvoie un message déjà compréhensible dans le corps
      // JSON ({error: "..."}) même sur un statut d'échec — on le récupère
      // plutôt que d'exposer la trace technique brute.
      final details = error.details;
      final friendlyMessage = details is Map ? details['error']?.toString() : null;
      throw Exception(
        friendlyMessage ?? "L'envoi des emails a échoué. Réessayez plus tard.",
      );
    } catch (error) {
      throw Exception("L'envoi des emails a échoué. Vérifiez votre connexion et réessayez.");
    }
  }

  Future<QrValidationResult> validateQr({
    required String qrCode,
    required String eventId,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'validate-qr',
        body: {
          'qr_code': qrCode,
          'event_id': eventId,
        },
      );

      final payload = response.data;
      if (payload is! Map) {
        return const QrValidationResult(result: 'invalide');
      }

      final safePayload = Map<String, dynamic>.from(payload);
      return QrValidationResult.fromJson(safePayload);
    } on FunctionException catch (error) {
      throw Exception('Erreur Edge Function validate-qr : ${error.details?.toString() ?? error.toString()}');
    } catch (error) {
      throw Exception('Erreur lors de l’appel validate-qr : $error');
    }
  }
}