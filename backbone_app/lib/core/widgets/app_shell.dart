import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

class _NavSection {
  final String? title;
  final List<_NavItem> items;
  const _NavSection({this.title, required this.items});
}

final _sections = [
  _NavSection(items: [
    _NavItem('Dashboard', Icons.dashboard_outlined, '/dashboard'),
    _NavItem('My Profile', Icons.person_outlined, '/profile'),
  ]),
  _NavSection(title: 'SHOWS', items: [
    _NavItem('At a Glance', Icons.timeline_outlined, '/shows/glance'),
    _NavItem('Show Cards', Icons.grid_view_outlined, '/shows/cards'),
    _NavItem('Table of Shows', Icons.table_rows_outlined, '/shows/table'),
  ]),
  _NavSection(title: 'PLANNING', items: [
    _NavItem('Drone Planning', Icons.bar_chart_outlined, '/planning/overview'),
    _NavItem('Drone Reservations', Icons.book_outlined, '/planning/reservations'),
    _NavItem('Drone Calendar', Icons.calendar_month_outlined, '/planning/calendar'),
  ]),
  _NavSection(title: 'TASKS & MORE', items: [
    _NavItem('All Actions', Icons.checklist_outlined, '/actions/all'),
    _NavItem('My Actions', Icons.check_circle_outline, '/actions/my'),
  ]),
  _NavSection(title: 'SCHEDULING', items: [
    _NavItem('Crew Calendar', Icons.calendar_today_outlined, '/shifts/crew-calendar'),
    _NavItem('Shifts', Icons.schedule_outlined, '/shifts/shifts'),
    _NavItem('Work Approvals', Icons.approval_outlined, '/shifts/work-approvals'),
  ]),
  _NavSection(title: 'TRAVEL', items: [
    _NavItem('All Travel', Icons.flight_outlined, '/travel/all'),
    _NavItem('My Travel', Icons.luggage_outlined, '/travel/my'),
  ]),
  _NavSection(title: 'PEOPLE', items: [
    _NavItem('Users', Icons.group_outlined, '/users'),
  ]),
  _NavSection(title: 'ACCOUNT', items: [
    _NavItem('Appearance', Icons.palette_outlined, '/account/appearance'),
    _NavItem('App Settings', Icons.settings_outlined, '/account/settings'),
    _NavItem('Notifications', Icons.notifications_outlined, '/account/notifications'),
  ]),
];

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final location = GoRouterState.of(context).matchedLocation;
    final isWide = MediaQuery.sizeOf(context).width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isWide
          ? null
          : AppBar(
              backgroundColor: AppColors.surface,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.rocket_launch, size: 13, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  const Text('NOVA',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 2)),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isWide) _Sidebar(currentLocation: location, user: user, ref: ref),
          Expanded(child: child),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: AppColors.surface,
              child: _SidebarContent(currentLocation: location, user: user, ref: ref),
            ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String currentLocation;
  final dynamic user;
  final WidgetRef ref;
  const _Sidebar({required this.currentLocation, required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: _SidebarContent(currentLocation: currentLocation, user: user, ref: ref),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final String currentLocation;
  final dynamic user;
  final WidgetRef ref;
  const _SidebarContent({required this.currentLocation, required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.rocket_launch, size: 18, color: Colors.black),
                ),
                const SizedBox(width: 10),
                const Text(
                  'NOVA',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final section in _sections) ...[
                  if (section.title != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        section.title!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  for (final item in section.items)
                    _NavTile(item: item, isActive: currentLocation.startsWith(item.route)),
                ],
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          // User footer
          if (user != null)
            InkWell(
              onTap: () => ref.read(authProvider.notifier).logout(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis),
                          Text(user.role,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.logout, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  const _NavTile({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Only pop if a drawer is actually open (mobile), not on web/desktop
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold != null && scaffold.isDrawerOpen) {
          Navigator.of(context).pop();
        }
        context.go(item.route);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
