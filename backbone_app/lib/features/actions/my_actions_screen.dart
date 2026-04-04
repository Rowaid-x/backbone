import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/backbone_app_bar.dart';
import '../../core/models/action_model.dart';
import 'actions_providers.dart';

class MyActionsScreen extends ConsumerWidget {
  const MyActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(actionsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackboneAppBar(title: 'My Actions'),
      body: actionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (actions) {
          // Summary row
          final open = actions.where((a) => a.status == 'open').length;
          final inProgress = actions.where((a) => a.status == 'in_progress').length;
          final overdue = actions.where((a) => a.isOverdue).length;
          final completed = actions.where((a) => a.status == 'completed').length;

          return Column(
            children: [
              // KPI bar
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Row(
                  children: [
                    _KpiPill('Total', actions.length.toString(), AppColors.textSecondary),
                    _KpiPill('Overdue', overdue.toString(), AppColors.error),
                    _KpiPill('In Progress', inProgress.toString(), AppColors.info),
                    _KpiPill('Completed', completed.toString(), AppColors.success),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              // List
              Expanded(
                child: actions.isEmpty
                    ? const Center(
                        child: Text('No actions assigned to you.',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: actions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => ActionTile(action: actions[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KpiPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class ActionTile extends ConsumerWidget {
  final ActionModel action;
  const ActionTile({super.key, required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = action.status == 'completed';
    final fmt = DateFormat('MMM d');
    final due = action.dueDate != null ? fmt.format(action.dueDate!) : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: action.isOverdue
              ? AppColors.error.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: isCompleted
                ? null
                : () => ref.read(actionsNotifierProvider.notifier).markComplete(action.id),
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCompleted ? AppColors.primary : AppColors.border,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (action.showName != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    action.showName!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TypeChip(action.type),
              if (due != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Due $due',
                  style: TextStyle(
                    fontSize: 10,
                    color: action.isOverdue
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip(this.type);

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
        type,
        style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
      ),
    );
  }
}
