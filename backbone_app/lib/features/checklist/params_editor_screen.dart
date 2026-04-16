import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/checklist_models.dart';
import 'checklist_provider.dart';

const _kGreen = Color(0xFF91FBE3);

class ParamsEditorScreen extends ConsumerStatefulWidget {
  const ParamsEditorScreen({super.key});

  @override
  ConsumerState<ParamsEditorScreen> createState() =>
      _ParamsEditorScreenState();
}

class _ParamsEditorScreenState extends ConsumerState<ParamsEditorScreen> {
  // Local edits for this session: itemId -> value string
  final Map<int, String> _edits = {};
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterChecklistProvider('flight'));
    final bool dirty = _edits.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        elevation: 0,
        title: const Text('Edit Parameters',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        actions: [
          if (dirty)
            TextButton(
              onPressed: _saving ? null : () => _promptSave(context, masterAsync.valueOrNull ?? []),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kGreen))
                  : const Text('Save as…',
                      style: TextStyle(color: _kGreen, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: masterAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kGreen)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.white38))),
        data: (items) {
          final params =
              items.where((i) => i.isConfigurable).toList();

          // Filter by search
          final filtered = _query.isEmpty
              ? params
              : params
                  .where((p) =>
                      p.label
                          .toLowerCase()
                          .contains(_query.toLowerCase()) ||
                      p.section
                          .toLowerCase()
                          .contains(_query.toLowerCase()))
                  .toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search parameters…',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white38, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white38, size: 18),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1A1A2E),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              if (dirty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _kGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: _kGreen, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        '${_edits.length} parameter${_edits.length == 1 ? '' : 's'} edited — tap "Save as…" to name this version',
                        style: const TextStyle(
                            color: _kGreen, fontSize: 12),
                      ),
                    ],
                  ),
                ),

              // Params list grouped by section
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No parameters found',
                            style: TextStyle(color: Colors.white38)))
                    : _ParamList(
                        params: filtered,
                        edits: _edits,
                        onEdit: (id, val) =>
                            setState(() => _edits[id] = val),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _promptSave(BuildContext context, List<MasterItem> allItems) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Save as version',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Give this parameter set a name so you can load it later.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g. Fever Melbourne',
                hintStyle: TextStyle(color: Colors.white24),
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
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              _saveVersion(name, allItems);
            },
            child: const Text('Save',
                style: TextStyle(
                    color: _kGreen, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveVersion(String name, List<MasterItem> allItems) async {
    setState(() => _saving = true);
    try {
      // Build the items payload — configurable ones with edited values,
      // non-configurable ones with their default value
      final configItems = allItems.where((i) => i.isConfigurable).toList();
      final payload = configItems.map((item) => {
        'master_item_id': item.id,
        'label': item.label,
        'value': _edits[item.id] ?? item.defaultValue,
      }).toList();

      await ref.read(dioProvider).post('/checklist/versions/', data: {
        'name': name,
        'sheet': 'flight',
        'items': payload,
      });

      ref.invalidate(checklistVersionsProvider('flight'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved as "$name"'),
            backgroundColor: const Color(0xFF1A2A1A),
          ),
        );
        setState(() { _edits.clear(); _saving = false; });
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade900),
        );
      }
    }
  }
}

// ─── Params list grouped by section ──────────────────────────────────────────

class _ParamList extends StatelessWidget {
  final List<MasterItem> params;
  final Map<int, String> edits;
  final void Function(int, String) onEdit;

  const _ParamList(
      {required this.params, required this.edits, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    // Group by section
    final sections = <String, List<MasterItem>>{};
    for (final p in params) {
      sections.putIfAbsent(p.section, () => []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        for (final entry in sections.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: Text(
              entry.key,
              style: const TextStyle(
                color: _kGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...entry.value.map((item) => _ParamRow(
                item: item,
                currentValue: edits[item.id] ?? item.defaultValue,
                isEdited: edits.containsKey(item.id) &&
                    edits[item.id] != item.defaultValue,
                onEdit: (val) => onEdit(item.id, val),
              )),
        ],
      ],
    );
  }
}

class _ParamRow extends StatefulWidget {
  final MasterItem item;
  final String currentValue;
  final bool isEdited;
  final void Function(String) onEdit;

  const _ParamRow({
    required this.item,
    required this.currentValue,
    required this.isEdited,
    required this.onEdit,
  });

  @override
  State<_ParamRow> createState() => _ParamRowState();
}

class _ParamRowState extends State<_ParamRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentValue);
  }

  @override
  void didUpdateWidget(_ParamRow old) {
    super.didUpdateWidget(old);
    // Keep controller text in sync when parent updates the value
    if (old.currentValue != widget.currentValue) {
      _ctrl.text = widget.currentValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdited = widget.isEdited;
    return InkWell(
      onTap: () => _edit(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isEdited
              ? _kGreen.withOpacity(0.07)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEdited
                ? _kGreen.withOpacity(0.35)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(widget.item.label,
                  style: TextStyle(
                      color: isEdited ? Colors.white : Colors.white70,
                      fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isEdited
                    ? _kGreen.withOpacity(0.15)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.currentValue,
                style: TextStyle(
                  color: isEdited ? _kGreen : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit_rounded,
                size: 14,
                color: isEdited ? _kGreen : Colors.white24),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context) {
    _ctrl.text = widget.currentValue;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(widget.item.label,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default: ${widget.item.defaultValue}',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              final val = _ctrl.text.trim();
              widget.onEdit(val.isEmpty ? widget.item.defaultValue : val);
              Navigator.pop(dialogContext);
            },
            child: const Text('Set',
                style: TextStyle(
                    color: _kGreen, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
