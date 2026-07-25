import 'package:ceramic_app/objects/ceramic_firing_dto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/utils/measurement.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

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
    final units = AppSettingsController.instance.measurementSystem;
    _status = existing?.status ?? 'PLANNED';
    _type = existing?.type ?? 'BISQUE';
    _date = existing?.firingDate;
    _targetCone = TextEditingController(text: existing?.targetCone ?? '');
    _targetTemperature = TextEditingController(
      text: existing?.targetTemperatureC == null
          ? ''
          : Measurement.format(
              Measurement.temperatureFromCelsius(
                existing!.targetTemperatureC!,
                units,
              ),
            ),
    );
    _observedCone = TextEditingController(text: existing?.observedCone ?? '');
    _peakTemperature = TextEditingController(
      text: existing?.peakTemperatureC == null
          ? ''
          : Measurement.format(
              Measurement.temperatureFromCelsius(
                existing!.peakTemperatureC!,
                units,
              ),
            ),
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
    final saveFailed = context.l10n.firingSaveFailed;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _saveError = null;
    });

    final units = AppSettingsController.instance.measurementSystem;
    final targetDisplay = double.tryParse(_targetTemperature.text);
    final peakDisplay = double.tryParse(_peakTemperature.text);
    final saved = await widget.onSave(
      CeramicFiringDto(
        id: widget.existing?.id ?? 0,
        ceramicId: widget.ceramicId,
        status: _status,
        type: _type,
        firingDate: _date,
        targetCone: _targetCone.text,
        targetTemperatureC: targetDisplay == null
            ? null
            : Measurement.temperatureToCelsius(targetDisplay, units),
        observedCone: _status == 'COMPLETED' ? _observedCone.text : '',
        peakTemperatureC: _status == 'COMPLETED' && peakDisplay != null
            ? Measurement.temperatureToCelsius(peakDisplay, units)
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
      _saveError = saveFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final units = AppSettingsController.instance.measurementSystem;
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(
          widget.existing == null
              ? context.l10n.addFiring
              : context.l10n.editFiring,
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: context.l10n.status,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'PLANNED',
                      child: Text(context.l10n.planned),
                    ),
                    DropdownMenuItem(
                      value: 'COMPLETED',
                      child: Text(context.l10n.completed),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _status = value!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: InputDecoration(
                    labelText: context.l10n.firingType,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'BISQUE',
                      child: Text(context.l10n.firingBisque),
                    ),
                    DropdownMenuItem(
                      value: 'GLAZE',
                      child: Text(context.l10n.firingGlaze),
                    ),
                    DropdownMenuItem(
                      value: 'SINGLE',
                      child: Text(context.l10n.firingSingle),
                    ),
                    DropdownMenuItem(
                      value: 'OVERGLAZE',
                      child: Text(context.l10n.firingOverglaze),
                    ),
                    DropdownMenuItem(
                      value: 'OTHER',
                      child: Text(context.l10n.other),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _type = value!),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: !_saving,
                  title: Text(context.l10n.firingDate),
                  subtitle: Text(
                    _date == null
                        ? context.l10n.notSet
                        : DateFormat.yMMMd(
                            Localizations.localeOf(context).toLanguageTag(),
                          ).format(_date!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _saving ? null : _pickDate,
                ),
                _field(_targetCone, context.l10n.targetCone),
                _field(
                  _targetTemperature,
                  context.l10n.targetTemperature,
                  suffix: units.temperatureSymbol,
                  numeric: true,
                ),
                if (_status == 'COMPLETED') ...[
                  _field(_observedCone, context.l10n.observedCone),
                  _field(
                    _peakTemperature,
                    context.l10n.peakTemperature,
                    suffix: units.temperatureSymbol,
                    numeric: true,
                  ),
                ],
                _field(_kiln, context.l10n.kiln),
                _field(_program, context.l10n.program, maxLines: 3),
                _field(_note, context.l10n.firingNote, maxLines: 3),
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
