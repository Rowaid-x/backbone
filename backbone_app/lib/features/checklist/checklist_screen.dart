import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/checklist_models.dart';
import 'checklist_provider.dart';
import 'params_editor_screen.dart';

const _kGreen = Color(0xFF91FBE3);

// ─── Outer shell: sheet tabs ───────────────────────────────────────────────────

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A14),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A14),
          elevation: 0,
          title: const Text('Checklist',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          bottom: const TabBar(
            indicatorColor: _kGreen,
            indicatorWeight: 2,
            labelColor: _kGreen,
            unselectedLabelColor: Colors.white38,
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Flight'),
              Tab(text: 'Legacy'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SheetChecklist(sheet: 'daily'),
            _SheetChecklist(sheet: 'flight'),
            _LegacyChecklist(),
          ],
        ),
      ),
    );
  }
}

// ─── Generic sheet checklist ───────────────────────────────────────────────────

class _SheetChecklist extends ConsumerStatefulWidget {
  final String sheet;
  const _SheetChecklist({required this.sheet});

  @override
  ConsumerState<_SheetChecklist> createState() => _SheetChecklistState();
}

class _SheetChecklistState extends ConsumerState<_SheetChecklist> {
  int _sectionIndex = 0;
  // Session-local param overrides: itemId -> value
  final Map<int, String> _paramOverrides = {};

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterChecklistProvider(widget.sheet));
    final checked = ref.watch(checklistSessionProvider);

    return masterAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _kGreen)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.white38))),
      data: (items) {
        final sections = _buildSections(items);
        if (sections.isEmpty) {
          return const Center(
              child: Text('No items', style: TextStyle(color: Colors.white38)));
        }
        if (_sectionIndex >= sections.length) _sectionIndex = 0;

        // Count only checkable items (non-configurable)
        final allCheckable = items.where((i) => !i.isConfigurable).toList();
        final doneCount =
            allCheckable.where((i) => checked.contains(i.id)).length;

        return Column(
          children: [
            // Top bar: progress + Params button (flight only) + Reset
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child:
                        _ProgressBar(done: doneCount, total: allCheckable.length),
                  ),
                  if (widget.sheet == 'flight')
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ParamsEditorScreen()),
                      ),
                      icon: const Icon(Icons.tune_rounded,
                          size: 15, color: _kGreen),
                      label: const Text('Params',
                          style: TextStyle(color: _kGreen, fontSize: 12)),
                      style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8)),
                    ),
                  if (checked.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.restart_alt,
                          color: Colors.red, size: 20),
                      tooltip: 'Reset',
                      onPressed: () =>
                          ref.read(checklistSessionProvider.notifier).reset(),
                    ),
                ],
              ),
            ),

            // Section pills
            _SectionPills(
              sections: sections.map((s) => s.name).toList(),
              selected: _sectionIndex,
              onTap: (i) => setState(() => _sectionIndex = i),
            ),

            // Section content
            Expanded(
              child: _SectionView(
                section: sections[_sectionIndex],
                checked: checked,
                paramOverrides: _paramOverrides,
                onToggle: (id) =>
                    ref.read(checklistSessionProvider.notifier).toggle(id),
                onParamEdit: (id, val) =>
                    setState(() => _paramOverrides[id] = val),
              ),
            ),

            // Prev / Next nav
            _PageNav(
              current: _sectionIndex,
              total: sections.length,
              onPrev: () => setState(() => _sectionIndex--),
              onNext: () => setState(() => _sectionIndex++),
            ),
          ],
        );
      },
    );
  }

  List<_Section> _buildSections(List<MasterItem> items) {
    final result = <_Section>[];
    _Section? cur;
    for (final item in items) {
      if (cur == null || item.section != cur.name) {
        cur = _Section(name: item.section);
        result.add(cur);
      }
      cur.items.add(item); // includes configurable items inline
    }
    return result;
  }
}

class _Section {
  final String name;
  final List<MasterItem> items = [];
  _Section({required this.name});
}

// ─── Legacy Checklist tab ──────────────────────────────────────────────────────

class _LegacyChecklist extends StatefulWidget {
  const _LegacyChecklist();

  @override
  State<_LegacyChecklist> createState() => _LegacyChecklistState();
}

class _LegacyChecklistState extends State<_LegacyChecklist> {
  bool _sharing = false;

  Future<void> _shareXlsx() async {
    setState(() => _sharing = true);
    try {
      final data = await rootBundle.load('assets/files/checklist_sr6.4.xlsx');
      final bytes = data.buffer.asUint8List();
      final tmp = await getTemporaryDirectory();
      final file = File(
          '${tmp.path}/Nova_Sky_Stories_Checklist_SR6.4.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: 'Nova Sky Stories Checklist SR6.4',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red.shade900),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.file_present_rounded, color: _kGreen, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Nova Sky Stories\nChecklist SR6.4',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Original Excel checklist — unchanged',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _sharing ? null : _shareXlsx,
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.share_rounded),
              label: const Text('Open / Share XLSX'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.black,
                disabledBackgroundColor: _kGreen.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? done / total : 0.0;
    final allDone = done == total && total > 0;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 3,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(
                  allDone ? Colors.greenAccent : _kGreen),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          allDone ? 'Done!' : '$done/$total',
          style: TextStyle(
            color: allDone ? Colors.greenAccent : Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Section pills ─────────────────────────────────────────────────────────────

class _SectionPills extends StatelessWidget {
  final List<String> sections;
  final int selected;
  final void Function(int) onTap;

  const _SectionPills(
      {required this.sections, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sections.length,
        itemBuilder: (_, i) {
          final sel = i == selected;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              margin: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: sel ? _kGreen.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: sel
                      ? _kGreen.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Center(
                child: Text(
                  _short(sections[i]),
                  style: TextStyle(
                    color: sel ? _kGreen : Colors.white38,
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _short(String s) {
    final m = RegExp(r'^\d+\.\s+(.+)').firstMatch(s);
    final label = m != null ? m.group(1)! : s;
    return label.length > 14 ? '${label.substring(0, 12)}…' : label;
  }
}

// ─── Section view ──────────────────────────────────────────────────────────────

class _SectionView extends StatelessWidget {
  final _Section section;
  final Set<int> checked;
  final Map<int, String> paramOverrides;
  final void Function(int) onToggle;
  final void Function(int, String) onParamEdit;

  const _SectionView({
    required this.section,
    required this.checked,
    required this.paramOverrides,
    required this.onToggle,
    required this.onParamEdit,
  });

  bool get _isEmergency {
    final n = section.name.toLowerCase();
    return n.contains('loss') ||
        n.contains('aircraft') ||
        n.contains('weather') ||
        n.contains('geofence') ||
        n.contains('gps');
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isEmergency ? Colors.red : _kGreen;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      children: [
        // Section header
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            border: Border(left: BorderSide(color: accent, width: 4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  section.name,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (_timing(section.name).isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _timing(section.name),
                    style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                  ),
                ),
            ],
          ),
        ),

        if (_isEmergency)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'EMERGENCY — Follow Emergency Response Plan',
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),

        // Items inline — params rendered as distinct boxes, checkboxes as rows
        ...section.items.map((item) {
          if (item.isConfigurable) {
            return _ParamBox(
              item: item,
              currentValue: paramOverrides[item.id] ?? item.defaultValue,
              onEdit: (val) => onParamEdit(item.id, val),
            );
          } else {
            return _ItemRow(
              item: item,
              isChecked: checked.contains(item.id),
              accent: accent,
              onToggle: onToggle,
            );
          }
        }),
      ],
    );
  }

  String _timing(String s) {
    final m = RegExp(r'T[-\s]?(\d+:\d+)').firstMatch(s);
    return m != null ? 'T-${m.group(1)}' : '';
  }
}

// ─── Param box (inline in checklist) ──────────────────────────────────────────

class _ParamBox extends StatelessWidget {
  final MasterItem item;
  final String currentValue;
  final void Function(String) onEdit;

  const _ParamBox({
    required this.item,
    required this.currentValue,
    required this.onEdit,
  });

  bool get _isEdited => currentValue != item.defaultValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _editDialog(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _isEdited
              ? _kGreen.withOpacity(0.07)
              : const Color(0xFF13131F),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: _isEdited
                ? _kGreen.withOpacity(0.35)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            // Small param indicator dot
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isEdited ? _kGreen : Colors.white24,
              ),
            ),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: _isEdited ? Colors.white : Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: _isEdited
                    ? _kGreen.withOpacity(0.15)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                currentValue,
                style: TextStyle(
                  color: _isEdited ? _kGreen : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_rounded,
                size: 12,
                color: _isEdited ? _kGreen : Colors.white24),
          ],
        ),
      ),
    );
  }

  void _editDialog(BuildContext context) {
    final ctrl = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(item.label,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default: ${item.defaultValue}',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kGreen)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              onEdit(ctrl.text.trim().isEmpty
                  ? item.defaultValue
                  : ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Set',
                style:
                    TextStyle(color: _kGreen, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Checklist item row ────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final MasterItem item;
  final bool isChecked;
  final Color accent;
  final void Function(int) onToggle;

  const _ItemRow({
    required this.item,
    required this.isChecked,
    required this.accent,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical =
        item.label == item.label.toUpperCase() && item.label.trim().length > 3;

    return InkWell(
      onTap: () => onToggle(item.id),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox — filled when checked, no strikethrough
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isChecked ? accent : Colors.transparent,
                border: Border.all(
                  color: isChecked ? accent : Colors.white30,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: isChecked
                  ? Icon(Icons.check,
                      size: 12,
                      color:
                          accent == Colors.red ? Colors.white : Colors.black)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  // Dimmed when checked — NO strikethrough
                  color: isChecked ? Colors.white30 : Colors.white70,
                  fontSize: 13,
                  fontWeight:
                      isCritical ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
            // Show expected value as faint hint on right
            if (item.defaultValue.isNotEmpty &&
                item.defaultValue != 'checked' &&
                item.defaultValue != 'completed')
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  item.defaultValue,
                  style: TextStyle(
                    color: isChecked
                        ? Colors.white12
                        : Colors.white.withOpacity(0.25),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Prev / Next nav ───────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: current > 0 ? onPrev : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Prev'),
            style: TextButton.styleFrom(
              foregroundColor: _kGreen,
              disabledForegroundColor: Colors.white12,
            ),
          ),
          Expanded(
            child: Center(
              child: Text('${current + 1} / $total',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12)),
            ),
          ),
          TextButton.icon(
            onPressed: current < total - 1 ? onNext : null,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Next'),
            style: TextButton.styleFrom(
              foregroundColor: _kGreen,
              disabledForegroundColor: Colors.white12,
            ),
          ),
        ],
      ),
    );
  }
}
