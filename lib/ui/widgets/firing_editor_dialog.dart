import 'package:ceramic_app/objects/ceramic_firing_dto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FiringEditorDialog extends StatefulWidget {
  const FiringEditorDialog({
    super.key,
    required this.ceramicId,
    required this.onSave,
    this.existing,
  });

  final int ceramicId;
  final CeramicFiringDto? existing;
  final Future<bool> Function(CeramicFiringDto firing) onSave;

  @override
  State<FiringEditorDialog> createState() => _FiringEditorDialogState();
}

class _FiringEditorDialogState extends State<FiringEditorDialog> {
  late String _status;
  late String _type;
  late DateTime? _date;
  late final TextEditingController _targetCone;
  late final TextEditingController _targetTemperature;
  late final TextEditingController _observedCone;
  late final TextEditingController _peakTemperature;
  late final TextEditingController _kiln;
  late final TextEditingController _program;
  late final TextEditingController _note;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _status = existing?.status ?? 'PLANNED';
    _type = existing?.type ?? 'BISQUE';
    _date = existing?.firingDate;
    _targetCone = TextEditingController(text: existing?.targetCone ?? '');
    _targetTemperature = TextEditingController(
      text: existing?.targetTemperatureC?.toString() ?? '',
    );
    _observedCone = TextEditingController(text: existing?.observedCone ?? '');
    _peakTemperature = TextEditingController(
      text: existing?.peakTemperatureC?.toString() ?? '',
    );
    _kiln = TextEditingController(text: existing?.kiln ?? '');
    _program = TextEditingController(text: existing?.program ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _targetCone,
      _targetTemperature,
      _observedCone,
      _peakTemperature,
      _kiln,
      _program,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _date ?? DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _saveError = null;
    });

    final saved = await widget.onSave(
      CeramicFiringDto(
        id: widget.existing?.id ?? 0,
        ceramicId: widget.ceramicId,
        status: _status,
        type: _type,
        firingDate: _date,
        targetCone: _targetCone.text,
        targetTemperatureC: double.tryParse(_targetTemperature.text),
        observedCone: _status == 'COMPLETED' ? _observedCone.text : '',
        peakTemperatureC: _status == 'COMPLETED'
            ? double.tryParse(_peakTemperature.text)
            : null,
        kiln: _kiln.text,
        program: _program.text,
        note: _note.text,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _saveError = 'The firing could not be saved. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(widget.existing == null ? 'Add firing' : 'Edit firing'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'PLANNED', child: Text('Planned')),
                    DropdownMenuItem(
                      value: 'COMPLETED',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _status = value!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Firing type'),
                  items: const [
                    DropdownMenuItem(value: 'BISQUE', child: Text('Bisque')),
                    DropdownMenuItem(value: 'GLAZE', child: Text('Glaze')),
                    DropdownMenuItem(value: 'SINGLE', child: Text('Single')),
                    DropdownMenuItem(
                      value: 'OVERGLAZE',
                      child: Text('Overglaze / luster'),
                    ),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _type = value!),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: !_saving,
                  title: const Text('Firing date'),
                  subtitle: Text(
                    _date == null
                        ? 'Not set'
                        : DateFormat.yMMMd().format(_date!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _saving ? null : _pickDate,
                ),
                _field(_targetCone, 'Target cone'),
                _field(
                  _targetTemperature,
                  'Target temperature',
                  suffix: '°C',
                  numeric: true,
                ),
                if (_status == 'COMPLETED') ...[
                  _field(_observedCone, 'Observed cone'),
                  _field(
                    _peakTemperature,
                    'Peak temperature',
                    suffix: '°C',
                    numeric: true,
                  ),
                ],
                _field(_kiln, 'Kiln'),
                _field(_program, 'Program', maxLines: 3),
                _field(_note, 'Firing note', maxLines: 3),
                if (_saveError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _saveError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? suffix,
    bool numeric = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: controller,
        enabled: !_saving,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, suffixText: suffix),
      ),
    );
  }
}
