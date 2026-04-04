import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/action_model.dart';

final myActionsProvider = FutureProvider<List<ActionModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  final resp = await client.dio.get('/actions/', queryParameters: {
    'assigned_to': 'me',
    'page_size': '100',
    'ordering': 'due_date',
  });
  final results = resp.data['results'] as List<dynamic>;
  return results.map((e) => ActionModel.fromJson(e as Map<String, dynamic>)).toList();
});

class ActionStatusNotifier extends AsyncNotifier<List<ActionModel>> {
  @override
  Future<List<ActionModel>> build() async {
    final client = ref.read(apiClientProvider);
    final resp = await client.dio.get('/actions/', queryParameters: {
      'assigned_to': 'me',
      'page_size': '100',
      'ordering': 'due_date',
    });
    final results = resp.data['results'] as List<dynamic>;
    return results.map((e) => ActionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markComplete(String actionId) async {
    final client = ref.read(apiClientProvider);
    await client.dio.patch('/actions/$actionId/', data: {'status': 'completed'});
    ref.invalidateSelf();
  }
}

final actionsNotifierProvider =
    AsyncNotifierProvider<ActionStatusNotifier, List<ActionModel>>(
  ActionStatusNotifier.new,
);
