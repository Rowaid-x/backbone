import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/models/checklist_models.dart';
import '../../core/theme/app_theme.dart';
import 'checklist_provider.dart';

class ChecklistVersionScreen extends ConsumerStatefulWidget {
  final int versionId;
  const ChecklistVersionScreen({super.key, required this.versionId});

  @override
  ConsumerState<ChecklistVersionScreen> createState() => _ChecklistVersionScreenState();
}

class _ChecklistVersionScreenState extends ConsumerState<ChecklistVersionScreen> {
  // Local edits: itemId -> {label, value}
  final Map<int, Map<String, String>> _edits = {};
  final Set<int> _checked = {};
  bool _dirty = false;

  @override
  Widget build(BuildContext context) {
    final versionAsync = ref.watch(checklistVersionDetailProvider(widget.versionId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: versionAsync.whenData((v) => Text(v.name)).value ?? const Text('Version'),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: () => _saveEdits(versionAsync.valueOrNull),
              child: const Text('Save', style: TextStyle(color: AppTheme.colorShow)),
            ),
        ],
      ),
      body: versionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (version) => _buildList(version),
      ),
    );
  }

  Widget _buildList(ChecklistVersion version) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: version.items.length,
      itemBuilder: (_, i) {
        final item = version.items[i];
        final edit = _edits[item.id];
        final label = edit?['label'] ?? item.label;
        final value = edit?['value'] ?? item.value;
        final isChecked = _checked.contains(item.id);

        return ListTile(
          dense: true,
          leading: GestureDetector(
            onTap: () => setState(() {
              isChecked ? _checked.remove(item.id) : _checked.add(item.id);
            }),
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
              child: isChecked ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
            ),
          ),
          title: GestureDetector(
            onLongPress: () => _editLabel(item, label),
            child: Text(
              label,
              style: TextStyle(
                color: isChecked ? Colors.white38 : Colors.white,
                decoration: isChecked ? TextDecoration.lineThrough : null,
                fontSize: 14,
              ),
            ),
          ),
          subtitle: value.isNotEmpty
              ? GestureDetector(
                  onTap: () => _editValue(item, value),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.colorShow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
          trailing: const Icon(Icons.edit_outlined, size: 14, color: Colors.white24),
          onTap: () => setState(() {
            isChecked ? _checked.remove(item.id) : _checked.add(item.id);
          }),
        );
      },
    );
  }

  void _editLabel(VersionItem item, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename item'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) {
                setState(() {
                  _edits[item.id] = {...?_edits[item.id], 'label': v};
                  _dirty = true;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _editValue(VersionItem item, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit: ${item.label}'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _edits[item.id] = {...?_edits[item.id], 'value': ctrl.text.trim()};
                _dirty = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEdits(ChecklistVersion? version) async {
    if (version == null) return;

    final updatedItems = version.items.map((item) {
      final edit = _edits[item.id];
      return {
        'master_item_id': item.masterItemId,
        'label': edit?['label'] ?? item.label,
        'value': edit?['value'] ?? item.value,
      };
    }).toList();

    try {
      await ref.read(dioProvider).patch(
        '/checklist/versions/${widget.versionId}/',
        data: {'items': updatedItems},
      );
      ref.invalidate(checklistVersionDetailProvider(widget.versionId));
      ref.invalidate(checklistVersionsProvider(version.sheet));
      setState(() { _edits.clear(); _dirty = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
