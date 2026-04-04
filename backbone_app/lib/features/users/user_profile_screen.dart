import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/backbone_app_bar.dart';
import '../../core/models/user_model.dart';
import '../../core/models/show_model.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/status_badge.dart';
import 'users_providers.dart';

class UserProfileScreen extends ConsumerWidget {
  final String? userId;
  final bool isSelf;
  const UserProfileScreen({super.key, this.userId, this.isSelf = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isSelf) {
      final authState = ref.watch(authProvider);
      return authState.when(
        loading: () => const _LoadingScaffold(),
        error: (e, _) => _ErrorScaffold(message: e.toString()),
        data: (user) {
          if (user == null) return const _ErrorScaffold(message: 'Not logged in');
          // Fetch full detail for self
          final detailAsync = ref.watch(userDetailProvider(user.id));
          return detailAsync.when(
            loading: () => const _LoadingScaffold(),
            error: (e, _) => _ProfileBody(user: user, detail: null),
            data: (detail) => _ProfileBody(user: user, detail: detail),
          );
        },
      );
    }

    final id = userId!;
    final detailAsync = ref.watch(userDetailProvider(id));
    return detailAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(message: e.toString()),
      data: (detail) {
        final user = UserModel.fromJson(detail);
        return _ProfileBody(user: user, detail: detail);
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic>? detail;
  const _ProfileBody({required this.user, required this.detail});

  @override
  Widget build(BuildContext context) {
    final upcoming = _parseShows(detail?['upcoming_shows']);
    final previous = _parseShows(detail?['previous_shows']);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackboneAppBar(title: user.fullName),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(
              children: [
                _StatTile('Shows', user.showsCount.toString()),
                _StatTile('Days Served', '—'),
                _StatTile('Avg Shows/Yr', '—'),
                _StatTile('Role', user.role.toUpperCase()),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth > 600;
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 260, child: _PersonalInfoCard(user: user)),
                        const SizedBox(width: 16),
                        Expanded(child: _ScheduleCard(upcoming: upcoming, previous: previous)),
                      ],
                    )
                  : Column(
                      children: [
                        _PersonalInfoCard(user: user),
                        const SizedBox(height: 16),
                        _ScheduleCard(upcoming: upcoming, previous: previous),
                      ],
                    );
            }),
          ],
        ),
      ),
    );
  }

  List<ShowModel> _parseShows(dynamic raw) {
    if (raw == null) return [];
    return (raw as List<dynamic>)
        .map((e) => ShowModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  final UserModel user;
  const _PersonalInfoCard({required this.user});

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
          const Text('Personal Information',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 16),
          _InfoRow('Name', user.fullName),
          _InfoRow('Email', user.email),
          if (user.crewRole.isNotEmpty) _InfoRow('Crew Role', user.crewRole),
          if (user.country.isNotEmpty)
            _InfoRow('Location', user.locationDisplay),
          const Divider(color: AppColors.border, height: 20),
          const Text('Qualifications',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          _InfoRow('FAA Level', user.faaLevel.isEmpty ? 'None' : user.faaLevel),
          _InfoRow('MMAC Level',
              user.mmacLevel.isEmpty ? 'None' : user.mmacLevel),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final List<ShowModel> upcoming;
  final List<ShowModel> previous;
  const _ScheduleCard({required this.upcoming, required this.previous});

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
          const Text('Schedule',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          if (upcoming.isNotEmpty) ...[
            const Text('Upcoming Shows',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...upcoming.map((s) => _ShowScheduleRow(show: s)),
          ],
          if (previous.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Previous Shows',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...previous.map((s) => _ShowScheduleRow(show: s)),
          ],
          if (upcoming.isEmpty && previous.isEmpty)
            const Text('No shows yet.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ShowScheduleRow extends StatelessWidget {
  final ShowModel show;
  const _ShowScheduleRow({required this.show});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final start = show.startDate != null ? fmt.format(show.startDate!) : '—';
    final end = show.endDate != null ? fmt.format(show.endDate!) : '—';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(show.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                Text('$start – $end · ${show.location}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusBadge(status: show.status),
        ],
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  const _ErrorScaffold({required this.message});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: Text(message,
                style: const TextStyle(color: AppColors.error))),
      );
}
