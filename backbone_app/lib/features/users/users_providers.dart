import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/user_model.dart';

final usersSearchProvider = StateProvider<String>((ref) => '');

final usersListProvider = FutureProvider<List<UserModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  final search = ref.watch(usersSearchProvider);
  final params = <String, String>{'page_size': '200'};
  if (search.isNotEmpty) params['search'] = search;
  final resp = await client.dio.get('/users/', queryParameters: params);
  final results = resp.data['results'] as List<dynamic>;
  return results.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
});

final userDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final client = ref.read(apiClientProvider);
  final resp = await client.dio.get('/users/$userId/');
  return resp.data as Map<String, dynamic>;
});
