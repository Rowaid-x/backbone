import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/checklist_models.dart';
import '../../core/theme/app_theme.dart';
import 'checklist_provider.dart';
import 'save_version_dialog.dart';

const _sheets = [
  ('flight', 'Flight'),
  ('setup', 'Setup'),
  ('post_show', 'Post-Show'),
  ('multi_show', 'Multi-Show'),
  ('one_page', 'One-Page'),
  ('emergency', 'Emergency'),
];

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  String _selectedSheet = 'flight';

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterChecklistProvider(_selectedSheet));
    final versionsAsync = ref.watch(checklistVersionsProvider(_selectedSheet));
    final checked = ref.watch(checklistSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Save as version',
            onPressed: () => _saveVersion(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(masterChecklistProvider(_selectedSheet));
              ref.invalidate(checklistVersionsProvider(_selectedSheet));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Sheet selector
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _sheets.length,
              itemBuilder: (_, i) {
                final (key, label) = _sheets[i];
                final selected = _selectedSheet == key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedSheet = key),
                    selectedColor: AppTheme.colorShow.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: selected ? AppTheme.colorShow : Colors.white54,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Named versions row
          versionsAsync.whenData((versions) {
            if (versions.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: versions.length,
                itemBuilder: (_, i) {
                  final v = versions[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(v.name, style: const TextStyle(fontSize: 12)),
                      onPressed: () => context.push('/checklist/version/${v.id}'),
                      backgroundColor: const Color(0xFF1A1A2E),
                      side: const BorderSide(color: Colors.white12),
                    ),
                  );
                },
              ),
            );
          }).value ?? const SizedBox.shrink(),

          const Divider(height: 1),

          // Master checklist
          Expanded(
            child: masterAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) => _MasterList(
                items: items,
                checked: checked,
                onToggle: (id) => ref.read(checklistSessionProvider.notifier).toggle(id),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: checked.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => ref.read(checklistSessionProvider.notifier).reset(),
              label: const Text('Reset'),
              icon: const Icon(Icons.restart_alt),
              backgroundColor: Colors.red.shade800,
            )
          : null,
    );
  }

  void _saveVersion(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SaveVersionDialog(sheet: _selectedSheet),
    );
  }
}

class _MasterList extends StatelessWidget {
  final List<MasterItem> items;
  final Set<int> checked;
  final void Function(int) onToggle;

  const _MasterList({required this.items, required this.checked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    String? currentSection;
    final widgets = <Widget>[];

    for (final item in items) {
      if (item.section != currentSection) {
        currentSection = item.section;
        if (item.section.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                item.section,
                style: const TextStyle(
                  color: AppTheme.colorShow,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }
      }
      widgets.add(_ItemTile(item: item, isChecked: checked.contains(item.id), onToggle: onToggle));
    }

    return ListView(padding: const EdgeInsets.only(bottom: 80), children: widgets);
  }
}

class _ItemTile extends StatelessWidget {
  final MasterItem item;
  final bool isChecked;
  final void Function(int) onToggle;

  const _ItemTile({required this.item, required this.isChecked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: GestureDetector(
        onTap: () => onToggle(item.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isChecked ? AppTheme.colorShow : Colors.transparent,
            border: Border.all(
              color: isChecked ? AppTheme.colorShow : Colors.white30,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: isChecked
              ? const Icon(Icons.check, size: 14, color: Colors.black)
              : null,
        ),
      ),
      title: Text(
        item.label,
        style: TextStyle(
          color: isChecked ? Colors.white38 : Colors.white,
          decoration: isChecked ? TextDecoration.lineThrough : null,
          fontSize: 14,
        ),
      ),
      subtitle: item.defaultValue.isNotEmpty
          ? Text(item.defaultValue, style: const TextStyle(color: Colors.white38, fontSize: 12))
          : null,
      onTap: () => onToggle(item.id),
    );
  }
}
