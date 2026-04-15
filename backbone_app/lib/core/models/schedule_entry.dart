enum EntryType { show, travel, blackedOut, free }

EntryType _parseEntryType(String? s) {
  switch (s) {
    case 'show': return EntryType.show;
    case 'travel': return EntryType.travel;
    case 'blacked_out': return EntryType.blackedOut;
    default: return EntryType.free;
  }
}

class ScheduleEntry {
  final int id;
  final DateTime date;
  final EntryType entryType;
  final String label;

  const ScheduleEntry({
    required this.id,
    required this.date,
    required this.entryType,
    this.label = '',
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
        id: json['id'] as int,
        date: DateTime.parse(json['date'] as String),
        entryType: _parseEntryType(json['entry_type'] as String?),
        label: (json['label'] as String?) ?? '',
      );
}
