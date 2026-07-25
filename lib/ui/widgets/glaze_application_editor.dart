import 'package:ceramic_app/objects/ceramic_glaze_entry_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:collection/collection.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';

class GlazeApplicationEditor extends StatelessWidget {
  const GlazeApplicationEditor({
    super.key,
    required this.entries,
    required this.glazes,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
  });

  final List<CeramicGlazeEntryDto> entries;
  final List<GlazeDto> glazes;
  final Future<bool> Function(int glazeId) onAdd;
  final Future<bool> Function(int entryId, String note, int coatCount) onEdit;
  final Future<bool> Function(int entryId) onDelete;
  final Future<bool> Function(int entryId, int direction) onMove;

  @override
  Widget build(BuildContext context) {
    final ordered = [...entries]
      ..sort((a, b) {
        final order = a.layerOrder.compareTo(b.layerOrder);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
    return Column(
      children: [
        if (ordered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.noGlazeApplications,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        for (var index = 0; index < ordered.length; index++)
          Card(
            margin: const EdgeInsets.only(bottom: 9),
            child: ListTile(
              leading: CircleAvatar(radius: 15, child: Text('${index + 1}')),
              title: Text(_glazeName(context, ordered[index].glazeId)),
              subtitle: Text(
                _summary(context, ordered[index]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _edit(context, ordered[index]),
              trailing: Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    tooltip: context.l10n.moveUp,
                    onPressed: index == 0
                        ? null
                        : () => onMove(ordered[index].id, -1),
                    icon: const Icon(Icons.arrow_upward, size: 19),
                  ),
                  IconButton(
                    tooltip: context.l10n.moveDown,
                    onPressed: index == ordered.length - 1
                        ? null
                        : () => onMove(ordered[index].id, 1),
                    icon: const Icon(Icons.arrow_downward, size: 19),
                  ),
                  IconButton(
                    tooltip: context.l10n.removeApplication,
                    onPressed: () => onDelete(ordered[index].id),
                    icon: const Icon(Icons.close, size: 19),
                  ),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: PopupMenuButton<int>(
            enabled: glazes.isNotEmpty,
            onSelected: onAdd,
            itemBuilder: (_) => glazes
                .map(
                  (glaze) =>
                      PopupMenuItem(value: glaze.id, child: Text(glaze.title)),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 18),
                  const SizedBox(width: 8),
                  Text(context.l10n.addGlazeApplication),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _glazeName(BuildContext context, int glazeId) =>
      glazes
          .where((glaze) => glaze.id == glazeId)
          .map((glaze) => glaze.title)
          .firstOrNull ??
      context.l10n.unknownGlaze;

  String _summary(BuildContext context, CeramicGlazeEntryDto entry) {
    final coats = context.l10n.coatCount(entry.coatCount);
    return entry.note.isEmpty ? coats : '$coats · ${entry.note}';
  }

  Future<void> _edit(BuildContext context, CeramicGlazeEntryDto entry) async {
    await showDialog<void>(
      context: context,
      builder: (_) => GlazeApplicationEditDialog(
        title: _glazeName(context, entry.glazeId),
        initialNote: entry.note,
        initialCoatCount: entry.coatCount,
        onSave: (note, coatCount) => onEdit(entry.id, note, coatCount),
      ),
    );
  }
}

class GlazeApplicationEditDialog extends StatefulWidget {
  const GlazeApplicationEditDialog({
    super.key,
    required this.title,
    required this.initialNote,
    required this.initialCoatCount,
    required this.onSave,
  });

  final String title;
  final String initialNote;
  final int initialCoatCount;
  final Future<bool> Function(String note, int coatCount) onSave;

  @override
  State<GlazeApplicationEditDialog> createState() =>
      _GlazeApplicationEditDialogState();
}

class _GlazeApplicationEditDialogState
    extends State<GlazeApplicationEditDialog> {
  late final TextEditingController _note;
  late final TextEditingController _coats;
  String? _coatError;
  String? _saveError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.initialNote);
    _coats = TextEditingController(text: '${widget.initialCoatCount}');
  }

  @override
  void dispose() {
    _note.dispose();
    _coats.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final coatCount = int.tryParse(_coats.text.trim());
    if (coatCount == null || coatCount < 1) {
      setState(() {
        _coatError = context.l10n.coatMinimum;
        _saveError = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _coatError = null;
      _saveError = null;
    });
    final saveFailed = context.l10n.glazeApplicationSaveFailed;
    final saved = await widget.onSave(_note.text, coatCount);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _saveError = saveFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _coats,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.coatCountLabel,
                  errorText: _coatError,
                ),
              ),
              TextField(
                controller: _note,
                enabled: !_saving,
                maxLength: 255,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.applicationNote,
                ),
              ),
              if (_saveError != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.save),
          ),
        ],
      ),
    );
  }
}
