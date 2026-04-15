import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/checklist_models.dart';
import '../../core/theme/app_theme.dart';
import 'checklist_provider.dart';
import 'save_version_dialog.dart';

// Ordered sheet definitions — emergency is separate/red
const _sheets = [
  ('flight', 'Flight'),
  ('setup', 'Setup'),
  ('post_show', 'Post-Show'),
  ('multi_show', 'Multi-Show'),
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
    final overrides = ref.watch(checklistOverridesProvider);
    final isEmergency = _selectedSheet == 'emergency';

    return Scaffold(
      backgroundColor: AppTheme.dark.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_sheetLabel(_selectedSheet)),
        actions: [
          // Emergency button — always visible, red accent
          IconButton(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: isEmergency ? Colors.red : Colors.red.shade300,
            ),
            tooltip: 'Emergency procedures',
            onPressed: () {
              setState(() => _selectedSheet = 'emergency');
            },
          ),
          // Switch checklist
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch checklist',
            onPressed: () => _showSheetPicker(context),
          ),
          // Versions
          versionsAsync.maybeWhen(
            data: (versions) => versions.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.folder_open_rounded),
                    tooltip: 'Saved versions',
                    onPressed: () => _showVersionsPicker(context, versions),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save as version',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => SaveVersionDialog(sheet: _selectedSheet),
            ),
          ),
        ],
      ),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
        data: (items) {
          final checkableItems = items.where((i) => !i.isConfigurable).toList();
          final checkedCount = checkableItems.where((i) => checked.contains(i.id)).length;
          final total = checkableItems.length;

          return Column(
            children: [
              // Progress bar
              if (total > 0 && !isEmergency)
                _ProgressHeader(checked: checkedCount, total: total),

              // Emergency warning banner
              if (isEmergency)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade900.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'EMERGENCY PROCEDURES — Reference only. Follow your Emergency Response Plan.',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _ChecklistBody(
                  items: items,
                  checked: checked,
                  overrides: overrides,
                  isEmergency: isEmergency,
                  onToggle: (id) => ref.read(checklistSessionProvider.notifier).toggle(id),
                  onOverride: (id, val) => ref.read(checklistOverridesProvider.notifier).set(id, val),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: checked.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                ref.read(checklistSessionProvider.notifier).reset();
                ref.read(checklistOverridesProvider.notifier).clear();
              },
              label: const Text('Reset'),
              icon: const Icon(Icons.restart_alt),
              backgroundColor: Colors.red.shade800,
            )
          : null,
    );
  }

  String _sheetLabel(String sheet) {
    switch (sheet) {
      case 'flight':    return 'Flight Checklist';
      case 'setup':     return 'Setup Checklist';
      case 'post_show': return 'Post-Show Checklist';
      case 'multi_show': return 'Multi-Show Checklist';
      case 'emergency': return 'Emergency Procedures';
      default: return 'Checklist';
    }
  }

  void _showSheetPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Select Checklist', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ),
            ..._sheets.map((s) {
              final selected = _selectedSheet == s.$1;
              return ListTile(
                leading: Icon(
                  _sheetIcon(s.$1),
                  color: selected ? AppTheme.colorShow : Colors.white38,
                  size: 20,
                ),
                title: Text(
                  s.$2,
                  style: TextStyle(
                    color: selected ? AppTheme.colorShow : Colors.white,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() => _selectedSheet = s.$1);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _sheetIcon(String sheet) {
    switch (sheet) {
      case 'flight':    return Icons.flight_rounded;
      case 'setup':     return Icons.build_rounded;
      case 'post_show': return Icons.flag_rounded;
      case 'multi_show': return Icons.repeat_rounded;
      default: return Icons.list_rounded;
    }
  }

  void _showVersionsPicker(BuildContext context, List<ChecklistVersion> versions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Saved Versions', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ),
            ...versions.map((v) => ListTile(
              leading: const Icon(Icons.bookmark_rounded, color: Colors.white38, size: 20),
              title: Text(v.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text('by ${v.createdByName}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                context.push('/checklist/version/${v.id}');
              },
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Progress header ──────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int checked;
  final int total;
  const _ProgressHeader({required this.checked, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? checked / total : 0.0;
    final allDone = checked == total;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                allDone ? 'All checks complete' : '$checked / $total checked',
                style: TextStyle(
                  color: allDone ? Colors.greenAccent : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (allDone) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(
                allDone ? Colors.greenAccent : AppTheme.colorShow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Checklist body ───────────────────────────────────────────────────────────

class _ChecklistBody extends StatelessWidget {
  final List<MasterItem> items;
  final Set<int> checked;
  final Map<int, String> overrides;
  final bool isEmergency;
  final void Function(int) onToggle;
  final void Function(int, String) onOverride;

  const _ChecklistBody({
    required this.items,
    required this.checked,
    required this.overrides,
    required this.isEmergency,
    required this.onToggle,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    String? currentSection;
    final widgets = <Widget>[];

    for (final item in items) {
      if (item.section != currentSection) {
        currentSection = item.section;
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 4));
        }
        widgets.add(_SectionHeader(label: item.section, isEmergency: isEmergency));
      }

      if (item.isConfigurable) {
        widgets.add(_ConfigurableItem(
          item: item,
          overrideValue: overrides[item.id],
          onSave: (val) => onOverride(item.id, val),
        ));
      } else {
        widgets.add(_CheckItem(
          item: item,
          isChecked: checked.contains(item.id),
          isEmergency: isEmergency,
          onToggle: onToggle,
        ));
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96, top: 4),
      children: widgets,
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isEmergency;
  const _SectionHeader({required this.label, required this.isEmergency});

  @override
  Widget build(BuildContext context) {
    final color = isEmergency ? Colors.red.shade300 : AppTheme.colorShow;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
        color: color.withOpacity(0.06),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Checkable item ───────────────────────────────────────────────────────────

class _CheckItem extends StatelessWidget {
  final MasterItem item;
  final bool isChecked;
  final bool isEmergency;
  final void Function(int) onToggle;

  const _CheckItem({
    required this.item,
    required this.isChecked,
    required this.isEmergency,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isEmergency ? Colors.red.shade300 : AppTheme.colorShow;
    return InkWell(
      onTap: () => onToggle(item.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isChecked ? activeColor : Colors.transparent,
                border: Border.all(
                  color: isChecked ? activeColor : Colors.white30,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isChecked ? Colors.white30 : Colors.white,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white30,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.defaultValue.isNotEmpty && item.defaultValue != 'completed' && item.defaultValue != 'checked')
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.defaultValue,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Configurable item (editable value) ──────────────────────────────────────

class _ConfigurableItem extends StatelessWidget {
  final MasterItem item;
  final String? overrideValue;
  final void Function(String) onSave;

  const _ConfigurableItem({required this.item, this.overrideValue, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final displayValue = overrideValue ?? item.defaultValue;
    final isOverridden = overrideValue != null && overrideValue != item.defaultValue;

    return InkWell(
      onTap: () => _edit(context, displayValue),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            const SizedBox(width: 34), // align with checkboxes
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOverridden
                    ? AppTheme.colorShow.withOpacity(0.15)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isOverridden ? AppTheme.colorShow.withOpacity(0.4) : Colors.white12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayValue,
                    style: TextStyle(
                      color: isOverridden ? AppTheme.colorShow : Colors.white60,
                      fontSize: 13,
                      fontWeight: isOverridden ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_rounded,
                    size: 11,
                    color: isOverridden ? AppTheme.colorShow : Colors.white30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: item.defaultValue,
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.colorShow)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(context);
            },
            child: Text('Save', style: TextStyle(color: AppTheme.colorShow)),
          ),
        ],
      ),
    );
  }
}
