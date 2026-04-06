import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/schedule_entry.dart';

// All upcoming entries for the logged-in user
final scheduleProvider = FutureProvider<List<ScheduleEntry>>((ref) async {
  final res = await ref.watch(dioProvider).get('/schedule/');
  final list = res.data as List;
  return list.map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>)).toList();
});

// Entries for a specific month
final monthScheduleProvider =
    FutureProvider.family<List<ScheduleEntry>, ({int year, int month})>(
  (ref, args) async {
    final res = await ref.watch(dioProvider).get('/schedule/${args.year}/${args.month}/');
    final list = res.data as List;
    return list.map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>)).toList();
  },
);

// Next upcoming show
final nextShowProvider = FutureProvider<ScheduleEntry?>((ref) async {
  final res = await ref.watch(dioProvider).get('/schedule/next-show/');
  if (res.data == null) return null;
  return ScheduleEntry.fromJson(res.data as Map<String, dynamic>);
});
