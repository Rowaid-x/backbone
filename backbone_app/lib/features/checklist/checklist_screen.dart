import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/checklist_models.dart';
import 'checklist_provider.dart';
import 'params_editor_screen.dart';

const _kGreen = Color(0xFF91FBE3);

// ─── Outer shell: two tabs ─────────────────────────────────────────────────────

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
            labelStyle:
                TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Flight Checklist'),
              Tab(text: 'Legacy Checklist'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FlightChecklist(),
            _LegacyChecklist(),
          ],
        ),
      ),
    );
  }
}

// ─── Flight Checklist tab ──────────────────────────────────────────────────────

class _FlightChecklist extends ConsumerStatefulWidget {
  const _FlightChecklist();

  @override
  ConsumerState<_FlightChecklist> createState() => _FlightChecklistState();
}

class _FlightChecklistState extends ConsumerState<_FlightChecklist> {
  int _sectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterChecklistProvider('flight'));
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
              child:
                  Text('No items', style: TextStyle(color: Colors.white38)));
        }
        if (_sectionIndex >= sections.length) _sectionIndex = 0;

        final allCheckable = items.where((i) => !i.isConfigurable).toList();
        final doneCount =
            allCheckable.where((i) => checked.contains(i.id)).length;

        return Column(
          children: [
            // Top action row: progress + Params button + Reset
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _ProgressBar(
                        done: doneCount, total: allCheckable.length),
                  ),
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
                onToggle: (id) =>
                    ref.read(checklistSessionProvider.notifier).toggle(id),
              ),
            ),

            // Prev / Next
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
      if (item.isConfigurable) continue; // params hidden from checklist
      if (cur == null || item.section != cur.name) {
        cur = _Section(name: item.section);
        result.add(cur);
      }
      cur.items.add(item);
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

class _LegacyChecklist extends StatelessWidget {
  const _LegacyChecklist();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.file_download_outlined,
                color: _kGreen, size: 64),
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
              onPressed: () async {
                const url =
                    'http://76.13.213.26:8080/api/checklist/download/';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download XLSX'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.black,
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
                color:
                    sel ? _kGreen.withOpacity(0.12) : Colors.transparent,
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
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.normal,
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
  final void Function(int) onToggle;

  const _SectionView(
      {required this.section,
      required this.checked,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isEmergency = section.name.toLowerCase().contains('loss') ||
        section.name.toLowerCase().contains('aircraft') ||
        section.name.toLowerCase().contains('weather') ||
        section.name.toLowerCase().contains('geofence') ||
        section.name.toLowerCase().contains('gps');
    final accent = isEmergency ? Colors.red : _kGreen;
    final items = section.items;

    // Two columns for sections with many items (matching xlsx layout)
    final mid = (items.length / 2).ceil();
    final leftCol = items.sublist(0, mid);
    final rightCol =
        mid < items.length ? items.sublist(mid) : <MasterItem>[];
    final twoCol = items.length > 6 && rightCol.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      children: [
        // Section header — mint green left-border matching xlsx
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
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

        if (isEmergency)
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

        if (twoCol)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: leftCol
                      .map((item) => _ItemRow(
                            item: item,
                            isChecked: checked.contains(item.id),
                            accent: accent,
                            onToggle: onToggle,
                          ))
                      .toList(),
                ),
              ),
              Container(
                  width: 1,
                  color: Colors.white.withOpacity(0.07),
                  margin: const EdgeInsets.symmetric(horizontal: 4)),
              Expanded(
                child: Column(
                  children: rightCol
                      .map((item) => _ItemRow(
                            item: item,
                            isChecked: checked.contains(item.id),
                            accent: accent,
                            onToggle: onToggle,
                          ))
                      .toList(),
                ),
              ),
            ],
          )
        else
          ...items.map((item) => _ItemRow(
                item: item,
                isChecked: checked.contains(item.id),
                accent: accent,
                onToggle: onToggle,
              )),
      ],
    );
  }

  String _timing(String s) {
    final m = RegExp(r'T[-\s]?(\d+:\d+)').firstMatch(s);
    return m != null ? 'T-${m.group(1)}' : '';
  }
}

// ─── Item row ──────────────────────────────────────────────────────────────────

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
                  ? Icon(Icons.check, size: 12,
                      color: accent == Colors.red
                          ? Colors.white
                          : Colors.black)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: isChecked ? Colors.white24 : Colors.white70,
                  decoration:
                      isChecked ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white24,
                  fontSize: 13,
                  fontWeight:
                      isCritical ? FontWeight.w700 : FontWeight.normal,
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

  const _PageNav(
      {required this.current,
      required this.total,
      required this.onPrev,
      required this.onNext});

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
