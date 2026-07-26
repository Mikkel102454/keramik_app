import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/objects/project_template_dto.dart';
import 'package:ceramic_app/repositories/project_template_repository.dart';
import 'package:flutter/material.dart';

class ProjectTemplateEditorPage extends StatefulWidget {
  const ProjectTemplateEditorPage({
    super.key,
    required this.clays,
    required this.glazes,
    this.template,
  });

  final List<ClayDto> clays;
  final List<GlazeDto> glazes;
  final ProjectTemplateDto? template;

  @override
  State<ProjectTemplateEditorPage> createState() =>
      _ProjectTemplateEditorPageState();
}

class _ProjectTemplateEditorPageState extends State<ProjectTemplateEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _height;
  late final TextEditingController _width;
  late final TextEditingController _depth;
  late final TextEditingController _diameter;
  late final TextEditingController _tags;
  late int? _clayId;
  late List<TemplateGlazeDto> _glazes;
  late List<TemplateFiringDto> _firings;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final value = widget.template;
    _name = TextEditingController(text: value?.name ?? '');
    _title = TextEditingController(text: value?.titlePattern ?? '');
    _note = TextEditingController(text: value?.note ?? '');
    _height = TextEditingController(text: _number(value?.heightCm));
    _width = TextEditingController(text: _number(value?.widthCm));
    _depth = TextEditingController(text: _number(value?.depthCm));
    _diameter = TextEditingController(text: _number(value?.diameterCm));
    _tags = TextEditingController(text: value?.tags.join(', ') ?? '');
    _clayId = value?.clayId;
    _glazes = [
      for (final glaze in value?.glazes ?? const <TemplateGlazeDto>[])
        TemplateGlazeDto(
          glazeId: glaze.glazeId,
          glazeTitle: glaze.glazeTitle,
          note: glaze.note,
          layerOrder: glaze.layerOrder,
          coatCount: glaze.coatCount,
          available: glaze.available,
        ),
    ];
    _firings = [
      for (final firing in value?.firings ?? const <TemplateFiringDto>[])
        TemplateFiringDto(
          type: firing.type,
          firingOrder: firing.firingOrder,
          firingDate: firing.firingDate,
          targetCone: firing.targetCone,
          targetTemperatureC: firing.targetTemperatureC,
          kiln: firing.kiln,
          program: firing.program,
          note: firing.note,
        ),
    ];
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _title,
      _note,
      _height,
      _width,
      _depth,
      _diameter,
      _tags,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.template == null
              ? context.l10n.createTemplate
              : context.l10n.editTemplate,
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.save,
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              MaterialBanner(
                content: Text(_error!),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _error = null),
                    child: Text(context.l10n.ok),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _name,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: context.l10n.templateName,
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              validator: _required,
            ),
            TextFormField(
              controller: _title,
              maxLength: 220,
              decoration: InputDecoration(
                labelText: context.l10n.templateTitlePattern,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: Tooltip(
                  message: localizedTemplateTitlePatternHelp(context.l10n),
                  child: const Icon(Icons.info_outline),
                ),
              ),
              validator: _required,
            ),
            DropdownButtonFormField<int?>(
              initialValue: _clayId,
              decoration: InputDecoration(
                labelText: context.l10n.clay,
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(context.l10n.noClay),
                ),
                ...widget.clays.map(
                  (clay) => DropdownMenuItem<int?>(
                    value: clay.id,
                    child: Text(clay.title),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _clayId = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLength: 255,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.l10n.projectNotes,
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            TextFormField(
              controller: _tags,
              decoration: InputDecoration(
                labelText: context.l10n.tags,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: Tooltip(
                  message: context.l10n.commaSeparatedTags,
                  child: const Icon(Icons.info_outline),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.dimensions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _dimension(_height, context.l10n.height),
                _dimension(_width, context.l10n.width),
                _dimension(_depth, context.l10n.depth),
                _dimension(_diameter, context.l10n.diameter),
              ],
            ),
            const SizedBox(height: 24),
            _sectionHeader(
              context.l10n.glazeApplications,
              onAdd: widget.glazes.isEmpty ? null : _addGlaze,
            ),
            if (_glazes.isEmpty)
              Text(context.l10n.noTemplateGlazes)
            else
              for (var index = 0; index < _glazes.length; index++)
                _glazeTile(index),
            const SizedBox(height: 24),
            _sectionHeader(context.l10n.plannedFirings, onAdd: _addFiring),
            if (_firings.isEmpty)
              Text(context.l10n.noTemplateFirings)
            else
              for (var index = 0; index < _firings.length; index++)
                _firingTile(index),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _dimension(TextEditingController controller, String label) {
    return SizedBox(
      width: 150,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: '$label (cm)',
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        validator: _optionalNumber,
      ),
    );
  }

  Widget _sectionHeader(String label, {VoidCallback? onAdd}) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(
          tooltip: context.l10n.add,
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _glazeTile(int index) {
    final value = _glazes[index];
    return Card(
      child: ListTile(
        title: Text(value.glazeTitle),
        subtitle: Text(
          context.l10n.templateGlazeSummary(value.coatCount, value.note),
        ),
        leading: CircleAvatar(child: Text('${index + 1}')),
        trailing: Wrap(
          children: [
            IconButton(
              onPressed: index == 0 ? null : () => _moveGlaze(index, -1),
              icon: const Icon(Icons.arrow_upward),
            ),
            IconButton(
              onPressed: index == _glazes.length - 1
                  ? null
                  : () => _moveGlaze(index, 1),
              icon: const Icon(Icons.arrow_downward),
            ),
            IconButton(
              onPressed: () => setState(() => _glazes.removeAt(index)),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _firingTile(int index) {
    final value = _firings[index];
    final temperature = value.targetTemperatureC == null
        ? ''
        : ' · ${value.targetTemperatureC} °C';
    return Card(
      child: ListTile(
        title: Text(value.type),
        subtitle: Text('${value.targetCone}$temperature'),
        trailing: IconButton(
          onPressed: () => setState(() => _firings.removeAt(index)),
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }

  Future<void> _addGlaze() async {
    int selected = widget.glazes.first.id;
    final note = TextEditingController();
    final coats = TextEditingController(text: '1');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.l10n.addGlazeApplication),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selected,
                  decoration: InputDecoration(
                    labelText: context.l10n.glaze,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  items: widget.glazes
                      .map(
                        (value) => DropdownMenuItem(
                          value: value.id,
                          child: Text(value.title),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selected = value ?? selected),
                ),
                TextField(
                  controller: coats,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.l10n.coatCountLabel,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
                TextField(
                  controller: note,
                  decoration: InputDecoration(
                    labelText: context.l10n.applicationNote,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.add),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && mounted) {
      final material = widget.glazes.firstWhere(
        (value) => value.id == selected,
      );
      setState(() {
        _glazes.add(
          TemplateGlazeDto(
            glazeId: material.id,
            glazeTitle: material.title,
            note: note.text.trim(),
            layerOrder: _glazes.length + 1,
            coatCount: (int.tryParse(coats.text) ?? 1).clamp(1, 20),
          ),
        );
      });
    }
  }

  Future<void> _addFiring() async {
    String type = 'BISQUE';
    final cone = TextEditingController();
    final temperature = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.l10n.addPlannedFiring),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: InputDecoration(
                    labelText: context.l10n.firingType,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  items:
                      const ['BISQUE', 'GLAZE', 'SINGLE', 'OVERGLAZE', 'OTHER']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setDialogState(() => type = value ?? type),
                ),
                TextField(
                  controller: cone,
                  decoration: InputDecoration(
                    labelText: context.l10n.targetCone,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
                TextField(
                  controller: temperature,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '${context.l10n.targetTemperature} (°C)',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.add),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && mounted) {
      setState(() {
        _firings.add(
          TemplateFiringDto(
            type: type,
            firingOrder: _firings.length + 1,
            targetCone: cone.text.trim(),
            targetTemperatureC: double.tryParse(temperature.text),
          ),
        );
      });
    }
  }

  void _moveGlaze(int index, int direction) {
    setState(() {
      final value = _glazes.removeAt(index);
      _glazes.insert(index + direction, value);
      for (var i = 0; i < _glazes.length; i++) {
        _glazes[i].layerOrder = i + 1;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final tags = _tags.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (tags.length > 30) {
      setState(() => _error = context.l10n.tooManyTemplateTags);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final source = widget.template;
      final value = ProjectTemplateDto(
        id: source?.id ?? 0,
        version: source?.version ?? 0,
        name: _name.text.trim(),
        titlePattern: _title.text.trim(),
        clayId: _clayId,
        note: _note.text.trim(),
        tags: tags,
        glazes: _glazes,
        firings: [
          for (var index = 0; index < _firings.length; index++)
            TemplateFiringDto(
              type: _firings[index].type,
              firingOrder: index + 1,
              firingDate: _firings[index].firingDate,
              targetCone: _firings[index].targetCone,
              targetTemperatureC: _firings[index].targetTemperatureC,
              kiln: _firings[index].kiln,
              program: _firings[index].program,
              note: _firings[index].note,
            ),
        ],
        heightCm: double.tryParse(_height.text),
        widthCm: double.tryParse(_width.text),
        depthCm: double.tryParse(_depth.text),
        diameterCm: double.tryParse(_diameter.text),
      );
      final saved = source == null
          ? await ProjectTemplateRepository.create(value)
          : await ProjectTemplateRepository.update(value);
      if (mounted) Navigator.pop(context, saved);
    } catch (value) {
      if (mounted) setState(() => _error = value.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? context.l10n.requiredField : null;

  String? _optionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value);
    return parsed == null || parsed < 0 ? context.l10n.invalidNumber : null;
  }

  static String _number(double? value) => value?.toString() ?? '';
}
