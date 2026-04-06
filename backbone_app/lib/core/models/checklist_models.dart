import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_models.freezed.dart';
part 'checklist_models.g.dart';

@freezed
class MasterItem with _$MasterItem {
  const factory MasterItem({
    required int id,
    required String sheet,
    required String section,
    required int order,
    required String label,
    @Default('') String defaultValue,
    @Default(false) bool isConfigurable,
  }) = _MasterItem;

  factory MasterItem.fromJson(Map<String, dynamic> json) =>
      _$MasterItemFromJson(json);
}

@freezed
class VersionItem with _$VersionItem {
  const factory VersionItem({
    required int id,
    required int masterItemId,
    required String label,
    @Default('') String value,
  }) = _VersionItem;

  factory VersionItem.fromJson(Map<String, dynamic> json) =>
      _$VersionItemFromJson(json);
}

@freezed
class ChecklistVersion with _$ChecklistVersion {
  const factory ChecklistVersion({
    required int id,
    required String name,
    required String sheet,
    @Default('') String createdByName,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<VersionItem> items,
  }) = _ChecklistVersion;

  factory ChecklistVersion.fromJson(Map<String, dynamic> json) =>
      _$ChecklistVersionFromJson(json);
}

@freezed
class Notification with _$Notification {
  const factory Notification({
    required int id,
    required String title,
    required String body,
    required DateTime createdAt,
    @Default(false) bool read,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);
}
