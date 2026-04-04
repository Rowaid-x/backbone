import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/show_model.dart';

final showsFilterProvider = StateProvider<Map<String, String>>((ref) => {});

final showsListProvider = FutureProvider.family<List<ShowModel>, Map<String, String>>(
    (ref, filters) async {
  final client = ref.read(apiClientProvider);
  final params = {
    'page_size': '100',
    'ordering': 'start_date',
    ...filters,
  };
  final resp = await client.dio.get('/shows/', queryParameters: params);
  final results = resp.data['results'] as List<dynamic>;
  return results
      .map((e) => ShowModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

final allShowsProvider = FutureProvider<List<ShowModel>>((ref) async {
  final filters = ref.watch(showsFilterProvider);
  return ref.watch(showsListProvider(filters).future);
});
