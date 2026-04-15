import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/models/checklist_models.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final res = await ref.watch(dioProvider).get('/notifications/');
  final list = res.data as List;
  return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(notificationsProvider)),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No alerts', style: TextStyle(color: Colors.white38)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _NotificationTile(
              note: notes[i],
              onRead: () async {
                await ref.read(dioProvider).post('/notifications/${notes[i].id}/read/');
                ref.invalidate(notificationsProvider);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification note;
  final VoidCallback onRead;
  const _NotificationTile({required this.note, required this.onRead});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: note.read ? const Color(0xFF1A1A2E) : const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: note.read ? Colors.white10 : const Color(0xFF00C2FF).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_outlined, color: note.read ? Colors.white24 : const Color(0xFF00C2FF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, style: TextStyle(color: note.read ? Colors.white54 : Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(note.body, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 6),
                Text(DateFormat('MMM d, HH:mm').format(note.createdAt.toLocal()), style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
          if (!note.read)
            TextButton(
              onPressed: onRead,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: const Text('Mark read', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
