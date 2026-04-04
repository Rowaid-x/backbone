class ActionModel {
  final String id;
  final String? showId;
  final String? showName;
  final String? assignedToId;
  final String? assignedToName;
  final String title;
  final String description;
  final String type;
  final String status;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;

  const ActionModel({
    required this.id,
    this.showId,
    this.showName,
    this.assignedToId,
    this.assignedToName,
    required this.title,
    this.description = '',
    required this.type,
    required this.status,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
  });

  factory ActionModel.fromJson(Map<String, dynamic> json) => ActionModel(
        id: json['id'] as String,
        showId: json['show'] as String?,
        showName: json['show_name'] as String?,
        assignedToId: json['assigned_to'] as String?,
        assignedToName: json['assigned_to_name'] as String?,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        type: json['type'] as String? ?? 'general',
        status: json['status'] as String? ?? 'open',
        dueDate: json['due_date'] != null
            ? DateTime.tryParse(json['due_date'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != 'completed';
}
