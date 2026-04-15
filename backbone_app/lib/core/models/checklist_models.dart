class MasterItem {
  final int id;
  final String sheet;
  final String section;
  final int order;
  final String label;
  final String defaultValue;
  final bool isConfigurable;

  const MasterItem({
    required this.id,
    required this.sheet,
    required this.section,
    required this.order,
    required this.label,
    this.defaultValue = '',
    this.isConfigurable = false,
  });

  factory MasterItem.fromJson(Map<String, dynamic> json) => MasterItem(
        id: json['id'] as int,
        sheet: (json['sheet'] as String?) ?? '',
        section: (json['section'] as String?) ?? '',
        order: json['order'] as int,
        label: json['label'] as String,
        defaultValue: (json['default_value'] as String?) ?? '',
        isConfigurable: (json['is_configurable'] as bool?) ?? false,
      );
}

class VersionItem {
  final int id;
  final int masterItemId;
  final String label;
  final String value;

  const VersionItem({
    required this.id,
    required this.masterItemId,
    required this.label,
    this.value = '',
  });

  factory VersionItem.fromJson(Map<String, dynamic> json) => VersionItem(
        id: json['id'] as int,
        masterItemId: json['master_item_id'] as int,
        label: json['label'] as String,
        value: (json['value'] as String?) ?? '',
      );
}

class ChecklistVersion {
  final int id;
  final String name;
  final String sheet;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<VersionItem> items;

  const ChecklistVersion({
    required this.id,
    required this.name,
    required this.sheet,
    this.createdByName = '',
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory ChecklistVersion.fromJson(Map<String, dynamic> json) => ChecklistVersion(
        id: json['id'] as int,
        name: json['name'] as String,
        sheet: (json['sheet'] as String?) ?? '',
        createdByName: (json['created_by_name'] as String?) ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => VersionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AppNotification {
  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        read: (json['read'] as bool?) ?? false,
      );
}
