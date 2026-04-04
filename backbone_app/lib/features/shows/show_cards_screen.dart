import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/backbone_app_bar.dart';
import '../../core/models/show_model.dart';
import '../../shared/widgets/status_badge.dart';
import 'shows_providers.dart';

class ShowCardsScreen extends ConsumerWidget {
  const ShowCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showsAsync = ref.watch(allShowsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackboneAppBar(
        title: 'Show Cards',
        actions: [
          _SearchBar(onSearch: (q) {
            ref.read(showsFilterProvider.notifier).state = q.isEmpty ? {} : {'search': q};
          }),
          const SizedBox(width: 8),
          _StatusFilter(),
          const SizedBox(width: 8),
        ],
      ),
      body: showsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (shows) {
          if (shows.isEmpty) {
            return const Center(
              child: Text('No shows found.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(builder: (context, constraints) {
              final columns = (constraints.maxWidth / 340).floor().clamp(1, 4);
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: shows.length,
                itemBuilder: (_, i) => ShowCard(show: shows[i]),
              );
            }),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  const _SearchBar({required this.onSearch});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _expanded = false;
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return IconButton(
        icon: const Icon(Icons.search, size: 20),
        onPressed: () => setState(() => _expanded = true),
      );
    }
    return SizedBox(
      width: 200,
      child: TextField(
        controller: _ctrl,
        autofocus: true,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search shows…',
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              _ctrl.clear();
              widget.onSearch('');
              setState(() => _expanded = false);
            },
          ),
        ),
        onChanged: widget.onSearch,
      ),
    );
  }
}

class _StatusFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const options = ['all', 'proposed', 'confirmed', 'in_progress', 'completed'];
    final current = ref.watch(showsFilterProvider)['status'] ?? 'all';

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: current,
        dropdownColor: AppColors.surfaceVariant,
        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        items: options
            .map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(o == 'all' ? 'All Status' : o.replaceAll('_', ' ').toUpperCase()),
                ))
            .toList(),
        onChanged: (v) {
          final current = ref.read(showsFilterProvider);
          final updated = Map<String, String>.from(current);
          if (v == null || v == 'all') {
            updated.remove('status');
          } else {
            updated['status'] = v;
          }
          ref.read(showsFilterProvider.notifier).state = updated;
        },
      ),
    );
  }
}

class ShowCard extends StatelessWidget {
  final ShowModel show;
  const ShowCard({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final start = show.startDate != null ? fmt.format(show.startDate!) : '—';
    final end = show.endDate != null ? fmt.format(show.endDate!) : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _CategoryChip(show.category),
              const Spacer(),
              StatusBadge(status: show.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            show.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (show.location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              show.location,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '$start – $end',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const Divider(color: AppColors.border, height: 16),
          // Health grid
          _HealthGrid(show: show),
          const SizedBox(height: 8),
          // Footer
          Row(
            children: [
              const Icon(Icons.rocket_launch_outlined,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${show.droneCount} drones',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const Spacer(),
              const Icon(Icons.group_outlined,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${show.crewCount} crew',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip(this.category);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        category,
        style: const TextStyle(
            fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HealthGrid extends StatelessWidget {
  final ShowModel show;
  const _HealthGrid({required this.show});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Health', show.health),
      ('Permit', show.permitStatus),
      ('Production', show.productionStatus),
      ('Design', show.designStatus),
      ('Scheduling', show.schedulingStatus),
      ('Routing', show.routingStatus),
    ];
    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(child: _HealthRow(items[i].$1, items[i].$2)),
                if (i + 1 < items.length)
                  Expanded(child: _HealthRow(items[i + 1].$1, items[i + 1].$2)),
              ],
            ),
          ),
      ],
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String status;
  const _HealthRow(this.label, this.status);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HealthDot(status: status),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
