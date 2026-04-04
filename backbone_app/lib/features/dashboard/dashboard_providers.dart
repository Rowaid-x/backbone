import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/show_model.dart';
import '../../core/models/notification_model.dart';

final upcomingShowsProvider = FutureProvider<List<ShowModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final resp = await client.dio.get('/shows/', queryParameters: {
    'start_after': today,
    'ordering': 'start_date',
    'page_size': 5,
  });
  final results = resp.data['results'] as List<dynamic>;
  return results.map((e) => ShowModel.fromJson(e as Map<String, dynamic>)).toList();
});

final recentNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  final resp = await client.dio.get('/notifications/', queryParameters: {'page_size': 10});
  final results = resp.data['results'] as List<dynamic>;
  return results.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
});

final unreadCountProvider = Provider<int>((ref) {
  return ref
          .watch(recentNotificationsProvider)
          .valueOrNull
          ?.where((n) => n.isUnread)
          .length ??
      0;
});
