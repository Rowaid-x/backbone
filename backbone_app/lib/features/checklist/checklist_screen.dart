import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/checklist_models.dart';
import '../../core/theme/app_theme.dart';
import 'checklist_provider.dart';

// Section color — mint green matching the xlsx header rows
const _kSectionGreen = Color(0xFF91FBE3);
const _kSectionGreenDark = Color(0xFF0D2B24); // dark bg tint of mint

// Sheet tabs shown at top
const _kSheets = [
  ('flight', 'Flight'),
  ('setup', 'Setup'),
  ('post_show', 'Post-Show'),
  ('multi_show', 'Multi-Show'),
  ('emergency', 'Emergency'),
];

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedSheet = 'flight';
  int _sectionPage = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _kSheets.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {
          _selectedSheet = _kSheets[_tabCtrl.index].$1;
          _sectionPage = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterChecklistProvider(_selectedSheet));
    final checked = ref.watch(checklistSessionProvider);
    final overrides = ref.watch(checklistOverridesProvider);
    final isEmergency = _selectedSheet == 'emergency';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        elevation: 0,
        title: const Text('Checklist', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          if (checked.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ref.read(checklistSessionProvider.notifier).reset();
                ref.read(checklistOverridesProvider.notifier).clear();
              },
              icon: const Icon(Icons.restart_alt, size: 16, color: Colors.red),
              label: const Text('Reset', style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: _kSectionGreen,
            indicatorWeight: 2,
            labelColor: _kSectionGreen,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: _kSheets.map((s) {
              final isEmg = s.$1 == 'emergency';
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isEmg) ...[
                      const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.red),
                      const SizedBox(width: 4),
                    ],
                    Text(s.$2, style: isEmg ? const TextStyle(color: Colors.red) : null),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kSectionGreen)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white38))),
        data: (items) {
          // Group items into sections preserving order
          final sections = _groupSections(items);
          if (sections.isEmpty) {
            return const Center(child: Text('No items', style: TextStyle(color: Colors.white38)));
          }

          // Clamp page
          final pageCount = sections.length;
          if (_sectionPage >= pageCount) _sectionPage = pageCount - 1;

          final checkableItems = items.where((i) => !i.isConfigurable).toList();
          final checkedCount = checkableItems.where((i) => checked.contains(i.id)).length;

          return Column(
            children: [
              // Progress + section nav
              _SectionNav(
                sections: sections.map((s) => s.name).toList(),
                currentPage: _sectionPage,
                checkedCount: checkedCount,
                totalCount: checkableItems.length,
                isEmergency: isEmergency,
                onPageTap: (i) => setState(() => _sectionPage = i),
              ),

              // Section content — each section is a "page"
              Expanded(
                child: _SectionPage(
                  section: sections[_sectionPage],
                  checked: checked,
                  overrides: overrides,
                  isEmergency: isEmergency,
                  onToggle: (id) => ref.read(checklistSessionProvider.notifier).toggle(id),
                  onOverride: (id, val) => ref.read(checklistOverridesProvider.notifier).set(id, val),
                ),
              ),

              // Prev / Next nav
              _PageNav(
                current: _sectionPage,
                total: pageCount,
                onPrev: () => setState(() => _sectionPage--),
                onNext: () => setState(() => _sectionPage++),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_Section> _groupSections(List<MasterItem> items) {
    final sections = <_Section>[];
    _Section? current;
    for (final item in items) {
      if (current == null || item.section != current.name) {
        current = _Section(name: item.section);
        sections.add(current);
      }
      current.items.add(item);
    }
    return sections;
  }
}

class _Section {
  final String name;
  final List<MasterItem> items = [];
  _Section({required this.name});
}

// ─── Section nav pills ────────────────────────────────────────────────────────

class _SectionNav extends StatelessWidget {
  final List<String> sections;
  final int currentPage;
  final int checkedCount;
  final int totalCount;
  final bool isEmergency;
  final void Function(int) onPageTap;

  const _SectionNav({
    required this.sections,
    required this.currentPage,
    required this.checkedCount,
    required this.totalCount,
    required this.isEmergency,
    required this.onPageTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;
    final allDone = checkedCount == totalCount && totalCount > 0;
    final accentColor = isEmergency ? Colors.red : _kSectionGreen;

    return Column(
      children: [
        // Progress bar
        if (!isEmergency)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(
                        allDone ? Colors.greenAccent : _kSectionGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  allDone ? 'Done!' : '$checkedCount/$totalCount',
                  style: TextStyle(
                    color: allDone ? Colors.greenAccent : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Section pills
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: sections.length,
            itemBuilder: (_, i) {
              final selected = i == currentPage;
              return GestureDetector(
                onTap: () => onPageTap(i),
                child: Container(
                  margin: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: selected ? accentColor.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected ? accentColor.withOpacity(0.6) : Colors.white12,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _shortLabel(sections[i]),
                      style: TextStyle(
                        color: selected ? accentColor : Colors.white38,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _shortLabel(String section) {
    // Strip leading number+dot for brevity
    final match = RegExp(r'^\d+\.\s+(.+)').firstMatch(section);
    final label = match != null ? match.group(1)! : section;
    // Shorten long labels
    if (label.length > 16) return '${label.substring(0, 14)}…';
    return label;
  }
}

// ─── Section page — two-column layout matching xlsx ──────────────────────────

class _SectionPage extends StatelessWidget {
  final _Section section;
  final Set<int> checked;
  final Map<int, String> overrides;
  final bool isEmergency;
  final void Function(int) onToggle;
  final void Function(int, String) onOverride;

  const _SectionPage({
    required this.section,
    required this.checked,
    required this.overrides,
    required this.isEmergency,
    required this.onToggle,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isEmergency ? Colors.red : _kSectionGreen;
    final headerBg = isEmergency
        ? Colors.red.withOpacity(0.12)
        : _kSectionGreen.withOpacity(0.08);

    // Separate configurable params from checklist items
    final params = section.items.where((i) => i.isConfigurable).toList();
    final checkItems = section.items.where((i) => !i.isConfigurable).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        // Section header — green bar matching xlsx
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: headerBg,
            border: Border(
              left: BorderSide(color: accentColor, width: 4),
              bottom: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  section.name,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // Show timing if in name
              if (_timing(section.name).isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _timing(section.name),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Parameters block (white bg in xlsx) — shown as a card at top of section
        if (params.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Text(
                    'PARAMETERS',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                // Two-column params grid matching xlsx layout
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: _ParamsGrid(
                    params: params,
                    overrides: overrides,
                    onOverride: onOverride,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Checklist items — two-column matching xlsx side-by-side layout
        if (checkItems.isNotEmpty) ...[
          const SizedBox(height: 6),
          _TwoColumnChecklist(
            items: checkItems,
            checked: checked,
            isEmergency: isEmergency,
            onToggle: onToggle,
          ),
        ],
      ],
    );
  }

  String _timing(String section) {
    final m = RegExp(r'T[-\s]?(\d+:\d+)').firstMatch(section);
    return m != null ? 'T-${m.group(1)}' : '';
  }
}

// ─── Params grid — 2 columns, white card cells ───────────────────────────────

class _ParamsGrid extends StatelessWidget {
  final List<MasterItem> params;
  final Map<int, String> overrides;
  final void Function(int, String) onOverride;

  const _ParamsGrid({required this.params, required this.overrides, required this.onOverride});

  @override
  Widget build(BuildContext context) {
    // Lay out params in rows of 2
    final rows = <List<MasterItem>>[];
    for (var i = 0; i < params.length; i += 2) {
      rows.add(params.sublist(i, i + 2 <= params.length ? i + 2 : params.length));
    }

    return Column(
      children: rows.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            for (var i = 0; i < row.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _ParamCell(item: row[i], overrides: overrides, onOverride: onOverride)),
            ],
            if (row.length == 1) const Expanded(child: SizedBox()),
          ],
        ),
      )).toList(),
    );
  }
}

class _ParamCell extends StatelessWidget {
  final MasterItem item;
  final Map<int, String> overrides;
  final void Function(int, String) onOverride;

  const _ParamCell({required this.item, required this.overrides, required this.onOverride});

  @override
  Widget build(BuildContext context) {
    final displayValue = overrides[item.id] ?? item.defaultValue;
    final isOverridden = overrides[item.id] != null && overrides[item.id] != item.defaultValue;

    return GestureDetector(
      onTap: () => _edit(context, displayValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          // White cell from xlsx — dark version in our dark theme
          color: isOverridden ? _kSectionGreen.withOpacity(0.1) : const Color(0xFF252525),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isOverridden ? _kSectionGreen.withOpacity(0.5) : Colors.white15,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayValue,
                  style: TextStyle(
                    // Bold value — matches xlsx bold value cells
                    color: isOverridden ? _kSectionGreen : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.edit_rounded,
                  size: 10,
                  color: isOverridden ? _kSectionGreen : Colors.white24,
                ),
              ],
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
        title: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: item.defaultValue,
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _kSectionGreen)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              onOverride(item.id, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: _kSectionGreen)),
          ),
        ],
      ),
    );
  }
}

// ─── Two-column checklist matching xlsx side-by-side layout ──────────────────

class _TwoColumnChecklist extends StatelessWidget {
  final List<MasterItem> items;
  final Set<int> checked;
  final bool isEmergency;
  final void Function(int) onToggle;

  const _TwoColumnChecklist({
    required this.items,
    required this.checked,
    required this.isEmergency,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Split into two columns — left half then right half
    final mid = (items.length / 2).ceil();
    final leftCol = items.sublist(0, mid);
    final rightCol = items.sublist(mid);

    // If only a few items (≤ 6), show single column
    if (items.length <= 5) {
      return Column(
        children: items.map((item) => _CheckRow(
          item: item,
          isChecked: checked.contains(item.id),
          isEmergency: isEmergency,
          onToggle: onToggle,
        )).toList(),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column
          Expanded(
            child: Column(
              children: leftCol.map((item) => _CheckRow(
                item: item,
                isChecked: checked.contains(item.id),
                isEmergency: isEmergency,
                onToggle: onToggle,
              )).toList(),
            ),
          ),
          // Divider
          Container(width: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 4)),
          // Right column
          Expanded(
            child: Column(
              children: rightCol.map((item) => _CheckRow(
                item: item,
                isChecked: checked.contains(item.id),
                isEmergency: isEmergency,
                onToggle: onToggle,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final MasterItem item;
  final bool isChecked;
  final bool isEmergency;
  final void Function(int) onToggle;

  const _CheckRow({
    required this.item,
    required this.isChecked,
    required this.isEmergency,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isEmergency ? Colors.red : _kSectionGreen;
    // Detect bold items (ALL CAPS = critical step in xlsx)
    final isCritical = item.label == item.label.toUpperCase() && item.label.length > 3;

    return InkWell(
      onTap: () => onToggle(item.id),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isChecked ? accentColor : Colors.transparent,
                  border: Border.all(
                    color: isChecked ? accentColor : Colors.white30,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: isChecked
                    ? Icon(Icons.check, size: 12, color: isEmergency ? Colors.white : Colors.black)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            // Label + value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isChecked
                          ? Colors.white24
                          : (isCritical ? Colors.white : Colors.white70),
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white24,
                      fontSize: 13,
                      fontWeight: isCritical ? FontWeight.w700 : FontWeight.normal,
                      letterSpacing: isCritical ? 0.3 : 0,
                    ),
                  ),
                  if (item.defaultValue.isNotEmpty &&
                      item.defaultValue != 'checked' &&
                      item.defaultValue != 'completed' &&
                      item.defaultValue != 'verified' &&
                      item.defaultValue != 'transmitted')
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.defaultValue,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
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

// ─── Prev / Next page nav ─────────────────────────────────────────────────────

class _PageNav extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _PageNav({
    required this.current,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: current > 0 ? onPrev : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Prev'),
            style: TextButton.styleFrom(
              foregroundColor: _kSectionGreen,
              disabledForegroundColor: Colors.white12,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${current + 1} / $total',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: current < total - 1 ? onNext : null,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Next'),
            style: TextButton.styleFrom(
              foregroundColor: _kSectionGreen,
              disabledForegroundColor: Colors.white12,
            ),
          ),
        ],
      ),
    );
  }
}
