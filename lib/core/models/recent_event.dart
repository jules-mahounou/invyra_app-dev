class RecentEvent {
  final String id;
  final String title;
  final DateTime? eventDate;
  final String place;
  final String status;
  final String? logoUrl;

  const RecentEvent({
    required this.id,
    required this.title,
    this.eventDate,
    required this.place,
    required this.status,
    this.logoUrl,
  });

  factory RecentEvent.fromJson(Map<String, dynamic> json) {
    return RecentEvent(
      id: json['id'] as String,
      title: json['name'] as String? ?? 'Événement',
      eventDate: json['event_date'] != null ? DateTime.tryParse(json['event_date'] as String) : null,
      place: json['place'] as String? ?? 'Lieu à définir',
      status: json['status'] as String? ?? 'a_venir',
      logoUrl: json['logo_url'] as String?,
    );
  }
}
