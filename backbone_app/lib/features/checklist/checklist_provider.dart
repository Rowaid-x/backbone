import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/checklist_models.dart';

final masterChecklistProvider =
    FutureProvider.family<List<MasterItem>, String>((ref, sheet) async {
  final res = await ref.watch(dioProvider).get('/checklist/master/', queryParameters: {'sheet': sheet});
  final list = res.data as List;
  return list.map((e) => MasterItem.fromJson(e as Map<String, dynamic>)).toList();
});

final checklistVersionsProvider =
    FutureProvider.family<List<ChecklistVersion>, String>((ref, sheet) async {
  final res = await ref.watch(dioProvider).get('/checklist/versions/', queryParameters: {'sheet': sheet});
  final list = res.data as List;
  return list.map((e) => ChecklistVersion.fromJson(e as Map<String, dynamic>)).toList();
});

final checklistVersionDetailProvider =
    FutureProvider.family<ChecklistVersion, int>((ref, id) async {
  final res = await ref.watch(dioProvider).get('/checklist/versions/$id/');
  return ChecklistVersion.fromJson(res.data as Map<String, dynamic>);
});

// Mutable local state for the active checklist session (checked items)
class ChecklistSessionNotifier extends StateNotifier<Set<int>> {
  ChecklistSessionNotifier() : super({});

  void toggle(int itemId) {
    if (state.contains(itemId)) {
      state = {...state}..remove(itemId);
    } else {
      state = {...state, itemId};
    }
  }

  void reset() => state = {};
}

final checklistSessionProvider =
    StateNotifierProvider<ChecklistSessionNotifier, Set<int>>(
  (_) => ChecklistSessionNotifier(),
);
