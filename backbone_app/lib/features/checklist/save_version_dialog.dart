import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/models/checklist_models.dart';
import 'checklist_provider.dart';

class SaveVersionDialog extends ConsumerStatefulWidget {
  final String sheet;
  const SaveVersionDialog({super.key, required this.sheet});

  @override
  ConsumerState<SaveVersionDialog> createState() => _SaveVersionDialogState();
}

class _SaveVersionDialogState extends ConsumerState<SaveVersionDialog> {
  final _nameController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      // Build items from master (only configurable ones, with their defaults)
      final master = ref.read(masterChecklistProvider(widget.sheet)).valueOrNull ?? [];
      final items = master.where((i) => i.isConfigurable).map((i) => {
        'master_item_id': i.id,
        'label': i.label,
        'value': i.defaultValue,
      }).toList();

      final res = await ref.read(dioProvider).post('/checklist/versions/', data: {
        'name': name,
        'sheet': widget.sheet,
        'items': items,
      });

      ref.invalidate(checklistVersionsProvider(widget.sheet));
      if (mounted) {
        context.pop();
        final id = res.data['id'] as int;
        context.push('/checklist/version/$id');
      }
    } catch (e) {
      setState(() { _saving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save as version'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. Fever Melbourne',
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
