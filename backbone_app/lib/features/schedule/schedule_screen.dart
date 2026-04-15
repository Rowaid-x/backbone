import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/models/schedule_entry.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import 'schedule_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final monthKey = (year: _focusedDay.year, month: _focusedDay.month);
    final monthAsync = ref.watch(monthScheduleProvider(monthKey));
    final nextShowAsync = ref.watch(nextShowProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.name.isNotEmpty == true ? user!.name : 'Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(monthScheduleProvider(monthKey));
              ref.invalidate(nextShowProvider);
            },
          ),
        ],
      ),
      body: monthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) => _buildBody(context, entries, nextShowAsync),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<ScheduleEntry> entries,
    AsyncValue<ScheduleEntry?> nextShowAsync,
  ) {
    final entryMap = <DateTime, List<ScheduleEntry>>{};
    for (final e in entries) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      entryMap.putIfAbsent(key, () => []).add(e);
    }

    final selected = _selectedDay != null
        ? (entryMap[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [])
        : <ScheduleEntry>[];

    return Column(
      children: [
        // Next show banner
        nextShowAsync.whenData((show) {
          if (show == null) return const SizedBox.shrink();
          return _NextShowBanner(entry: show);
        }).value ?? const SizedBox.shrink(),

        // Calendar
        TableCalendar<ScheduleEntry>(
          firstDay: DateTime(2026, 1, 1),
          lastDay: DateTime(2027, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
          eventLoader: (day) {
            final key = DateTime(day.year, day.month, day.day);
            return entryMap[key] ?? [];
          },
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          onPageChanged: (focused) {
            setState(() => _focusedDay = focused);
            ref.invalidate(monthScheduleProvider((year: focused.year, month: focused.month)));
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              return Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(3).map((e) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _entryColor(e.entryType),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            defaultBuilder: (context, day, focusedDay) {
              final key = DateTime(day.year, day.month, day.day);
              final dayEntries = entryMap[key] ?? [];
              final isBlackedOut = dayEntries.any((e) => e.entryType == EntryType.blackedOut);
              if (isBlackedOut) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.colorBlackedOut,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: AppTheme.colorShow.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppTheme.colorShow,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: const TextStyle(color: Colors.white70),
            weekendTextStyle: const TextStyle(color: Colors.white70),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white54),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white54),
          ),
        ),

        const Divider(height: 1),

        // Selected day detail
        if (selected.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: selected.length,
              itemBuilder: (_, i) => _EntryTile(entry: selected[i]),
            ),
          )
        else if (_selectedDay != null)
          const Expanded(
            child: Center(child: Text('No events', style: TextStyle(color: Colors.white38))),
          ),
      ],
    );
  }

  Color _entryColor(EntryType type) {
    switch (type) {
      case EntryType.show:        return AppTheme.colorShow;
      case EntryType.travel:      return AppTheme.colorTravel;
      case EntryType.blackedOut: return AppTheme.colorBlackedOut;
      case EntryType.free:        return Colors.transparent;
    }
  }
}

class _NextShowBanner extends StatelessWidget {
  final ScheduleEntry entry;
  const _NextShowBanner({required this.entry});

  @override
  Widget build(BuildContext context) {
    final days = entry.date.difference(DateTime.now()).inDays;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.colorShow.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colorShow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flight_takeoff_rounded, color: AppTheme.colorShow, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label.isNotEmpty ? entry.label : 'Show',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('EEE, MMM d').format(entry.date),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            days == 0 ? 'Today' : 'In $days day${days == 1 ? '' : 's'}',
            style: const TextStyle(color: AppTheme.colorShow, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final ScheduleEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = _color(entry.entryType);
    final label = _label(entry);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _label(ScheduleEntry e) {
    switch (e.entryType) {
      case EntryType.blackedOut: return 'Off / Blacked Out';
      case EntryType.travel:      return 'Travel';
      case EntryType.show:        return e.label;
      case EntryType.free:        return 'Free';
    }
  }

  Color _color(EntryType type) {
    switch (type) {
      case EntryType.show:        return AppTheme.colorShow;
      case EntryType.travel:      return AppTheme.colorTravel;
      case EntryType.blackedOut: return AppTheme.colorBlackedOut;
      case EntryType.free:        return Colors.white24;
    }
  }
}
