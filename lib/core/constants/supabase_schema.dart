// Constantes et helpers alignés sur le schéma Postgres Supabase (projet invyra).
//
// Règle importante : ne jamais inclure une clé avec valeur `null` dans un insert/update
// PostgREST si la colonne a un DEFAULT ; Postgres n'applique pas le default.

// --- Enums Postgres (valeurs exactes) ---

const Set<String> kDbEventTypes = {
  'mariage',
  'anniversaire',
  'bapteme',
  'soiree_vip',
  'corporate',
  'autre',
};

const Set<String> kDbSendChannels = {'whatsapp', 'email', 'les_deux'};

const Set<String> kDbEventStatuses = {
  'a_venir',
  'en_cours',
  'termine',
  'cloture',
};

const Set<String> kDbAccountTypes = {'gratuit', 'essentiel', 'flex'};

const Set<String> kDbTemplateTiers = {'gratuit', 'premium'};

const Set<String> kDbInvitationStatuses = {
  'brouillon',
  'envoye',
  'echec',
  'vue',
  'confirme',
};

const String kDefaultSendChannel = 'whatsapp';
const String kDefaultEventStatus = 'a_venir';
const String kDefaultGuestImportSource = 'manual';

/// Libellés UI → clés `event_type`.
const Map<String, String> kEventTypeUiToDb = {
  'Mariage': 'mariage',
  'Anniversaire': 'anniversaire',
  'Baptême': 'bapteme',
  'Soirée VIP': 'soiree_vip',
  'Corporate': 'corporate',
  'Autre': 'autre',
};

/// Clés `event_type` → libellés UI.
const Map<String, String> kEventTypeDbToUi = {
  'mariage': 'Mariage',
  'anniversaire': 'Anniversaire',
  'bapteme': 'Baptême',
  'soiree_vip': 'Soirée VIP',
  'corporate': 'Corporate',
  'autre': 'Autre',
};

List<String> get kEventTypeDisplayValues => kEventTypeUiToDb.keys.toList();

String eventTypeDbKey(String displayLabel) {
  return kEventTypeUiToDb[displayLabel] ?? 'autre';
}

String eventTypeDisplayLabel(String? dbKey) {
  if (dbKey == null || dbKey.isEmpty) return 'Autre';
  return kEventTypeDbToUi[dbKey] ?? dbKey;
}

/// Payload insert/update sans clés null (évite d'écraser les DEFAULT Postgres).
Map<String, dynamic> supabaseRow(Map<String, dynamic> fields) {
  return Map<String, dynamic>.fromEntries(
    fields.entries.where((e) => e.value != null),
  );
}

/// Valide une valeur enum avant envoi à Supabase.
String requireDbEnum(String value, Set<String> allowed, String fieldLabel) {
  if (!allowed.contains(value)) {
    throw Exception(
      'Valeur invalide pour $fieldLabel : « $value ». '
      'Valeurs acceptées : ${allowed.join(', ')}.',
    );
  }
  return value;
}

String sendChannelOrDefault(String? value) {
  if (value == null || value.isEmpty) return kDefaultSendChannel;
  return requireDbEnum(value, kDbSendChannels, 'send_channel');
}

String eventTypeOrThrow(String value) =>
    requireDbEnum(value, kDbEventTypes, 'event_type');

/// Lit un champ texte en essayant plusieurs clés (anciens mocks / nouvelles colonnes).
String? readStringField(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = row[key];
    if (value != null && value.toString().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}

String readEventStatus(Map<String, dynamic> event) {
  final raw = readStringField(event, ['status', 'statut']);
  if (raw == null) return kDefaultEventStatus;
  return kDbEventStatuses.contains(raw) ? raw : kDefaultEventStatus;
}

String readEventType(Map<String, dynamic> event) {
  final raw = readStringField(event, ['event_type', 'type']);
  if (raw == null) return 'mariage';
  return kDbEventTypes.contains(raw) ? raw : 'autre';
}

String? normalizeOptionalText(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

final RegExp _simpleEmailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

bool isValidEmail(String value) => _simpleEmailPattern.hasMatch(value.trim());

/// Comme [normalizeOptionalText], mais rejette (retourne `null`) toute valeur
/// qui ne ressemble pas à un email — filet de sécurité pour que tout chemin
/// d'ajout d'invité (saisie manuelle, CSV, imports futurs) ne puisse jamais
/// enregistrer un email mal formé, qu'un service d'envoi externe refuserait.
String? normalizeOptionalEmail(String? value) {
  final normalized = normalizeOptionalText(value);
  if (normalized == null) return null;
  return isValidEmail(normalized) ? normalized : null;
}
