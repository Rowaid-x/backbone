import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_entry.freezed.dart';
part 'schedule_entry.g.dart';

enum EntryType { show, travel, blacked_out, free }

@freezed
class ScheduleEntry with _$ScheduleEntry {
  const factory ScheduleEntry({
    required int id,
    required DateTime date,
    required EntryType entryType,
    @Default('') String label,
  }) = _ScheduleEntry;

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) =>
      _$ScheduleEntryFromJson(json);
}
