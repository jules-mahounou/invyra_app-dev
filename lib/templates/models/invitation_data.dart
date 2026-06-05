class InvitationData {
  final String nomEvenement;
  final String eventType;
  final String date;
  final String lieu;
  final String? heure;
  final String? nomCouple;
  final String? message;
  final String? logoUrl;
  final String? qrCodeUrl;
  final String? customField1Label;
  final String? customField1Value;
  final String? customField2Label;
  final String? customField2Value;

  const InvitationData({
    required this.nomEvenement,
    required this.eventType,
    required this.date,
    required this.lieu,
    this.heure,
    this.nomCouple,
    this.message,
    this.logoUrl,
    this.qrCodeUrl,
    this.customField1Label,
    this.customField1Value,
    this.customField2Label,
    this.customField2Value,
  });

  factory InvitationData.fromEvent(Map event) {
    final rawDate = event['event_date'];
    final rawMetadata = event['metadata'];
    final metadata = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : <String, dynamic>{};
    String dateStr = 'Date non définie';
    String? heureStr;

    if (rawDate != null) {
      try {
        final dt = DateTime.parse(rawDate as String).toLocal();
        const months = [
          'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
        ];
        dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
        heureStr =
            '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return InvitationData(
      nomEvenement: event['name'] as String? ?? '',
      eventType: event['event_type'] as String? ?? 'autre',
      date: dateStr,
      heure: heureStr,
      lieu: event['place'] as String? ?? '',
      message: event['description'] as String?,
      logoUrl: event['logo_url'] as String?,
      customField1Label: (metadata['customField1Label'] ?? event['customField1Label']) as String?,
      customField1Value: (metadata['customField1Value'] ?? event['customField1Value']) as String?,
      customField2Label: (metadata['customField2Label'] ?? event['customField2Label']) as String?,
      customField2Value: (metadata['customField2Value'] ?? event['customField2Value']) as String?,
    );
  }
}
