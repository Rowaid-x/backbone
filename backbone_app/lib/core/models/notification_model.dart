class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? relatedShowId;
  final String? relatedShowName;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.relatedShowId,
    this.relatedShowName,
    this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String? ?? 'general',
        relatedShowId: json['related_show'] as String?,
        relatedShowName: json['related_show_name'] as String?,
        readAt: json['read_at'] != null
            ? DateTime.tryParse(json['read_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
