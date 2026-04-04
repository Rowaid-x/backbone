import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/show_model.dart';
import '../../core/models/notification_model.dart';
import '../../shared/widgets/status_badge.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final upcomingAsync = ref.watch(upcomingShowsProvider);
    final notifAsync = ref.watch(recentNotificationsProvider);
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                if (user != null)
                  Text(user.fullName,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Text(today, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Row
            Row(
              children: [
                _KpiCard(
                  label: 'My Milestones',
                  value: '—',
                  icon: Icons.flag_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _KpiCard(
                  label: 'My Actions',
                  value: '—',
                  icon: Icons.check_circle_outline,
                  color: AppColors.info,
                  onTap: () => context.go('/actions/my'),
                ),
                const SizedBox(width: 12),
                notifAsync.when(
                  data: (notifs) => _KpiCard(
                    label: 'Notifications',
                    value: notifs.where((n) => n.isUnread).length.toString(),
                    icon: Icons.notifications_outlined,
                    color: AppColors.warning,
                    onTap: () => context.go('/account/notifications'),
                  ),
                  loading: () => const _KpiCard(label: 'Notifications', value: '…', icon: Icons.notifications_outlined, color: AppColors.warning),
                  error: (_, __) => const _KpiCard(label: 'Notifications', value: '—', icon: Icons.notifications_outlined, color: AppColors.warning),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Main grid
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 700;
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _NotificationsPanel(notifAsync: notifAsync)),
                        const SizedBox(width: 16),
                        Expanded(child: _UpcomingShowsPanel(upcomingAsync: upcomingAsync)),
                      ],
                    )
                  : Column(
                      children: [
                        _NotificationsPanel(notifAsync: notifAsync),
                        const SizedBox(height: 16),
                        _UpcomingShowsPanel(upcomingAsync: upcomingAsync),
                      ],
                    );
            }),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsPanel extends StatelessWidget {
  final AsyncValue<List<NotificationModel>> notifAsync;
  const _NotificationsPanel({required this.notifAsync});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Notifications',
      child: notifAsync.when(
        loading: () => const _LoadingRows(),
        error: (e, _) => const _ErrorMsg(),
        data: (notifs) => notifs.isEmpty
            ? const _EmptyMsg(msg: 'No notifications.')
            : Column(
                children: notifs
                    .take(8)
                    .map((n) => _NotifTile(notif: n))
                    .toList(),
              ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  const _NotifTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notif.isUnread)
            Container(
              margin: const EdgeInsets.only(top: 5, right: 8),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
            )
          else
            const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: notif.isUnread ? FontWeight.w600 : FontWeight.normal,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(notif.body,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingShowsPanel extends StatelessWidget {
  final AsyncValue<List<ShowModel>> upcomingAsync;
  const _UpcomingShowsPanel({required this.upcomingAsync});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Upcoming Shows',
      child: upcomingAsync.when(
        loading: () => const _LoadingRows(),
        error: (e, _) => const _ErrorMsg(),
        data: (shows) => shows.isEmpty
            ? const _EmptyMsg(msg: 'No upcoming shows.')
            : Column(
                children: shows.map((s) => _ShowTile(show: s)).toList(),
              ),
      ),
    );
  }
}

class _ShowTile extends StatelessWidget {
  final ShowModel show;
  const _ShowTile({required this.show});

  @override
  Widget build(BuildContext context) {
    final start = show.startDate != null
        ? DateFormat('yyyy-MM-dd').format(show.startDate!)
        : '—';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$start · ${show.category} · ${show.location}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(show.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: show.status),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _EmptyMsg extends StatelessWidget {
  final String msg;
  const _EmptyMsg({required this.msg});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(msg,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
}

class _ErrorMsg extends StatelessWidget {
  const _ErrorMsg();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Failed to load.',
            style: TextStyle(color: AppColors.error, fontSize: 13)),
      );
}
