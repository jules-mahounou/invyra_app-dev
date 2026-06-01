class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String category;
  final String title;
  final String body;
  final bool isRead;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.isRead,
    required this.metadata,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] as bool? ?? false,
      metadata: rawMetadata is Map<String, dynamic>
          ? rawMetadata
          : rawMetadata is Map
              ? Map<String, dynamic>.from(rawMetadata)
              : const {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      category: category,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      metadata: metadata,
      createdAt: createdAt,
    );
  }
}
