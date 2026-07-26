import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/ceramic_batch_edit_dto.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/project_template_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/repositories/ceramic_batch_repository.dart';
import 'package:ceramic_app/repositories/project_template_repository.dart';
import 'package:flutter/material.dart';

class CeramicBatchEditPage extends StatefulWidget {
  const CeramicBatchEditPage({
    super.key,
    required this.ceramicIds,
    required this.stages,
    required this.clays,
    this.templateLoader,
  });

  final List<int> ceramicIds;
  final List<StageDto> stages;
  final List<ClayDto> clays;
  final Future<ProjectTemplatePageDto> Function()? templateLoader;

  @override
  State<CeramicBatchEditPage> createState() => _CeramicBatchEditPageState();
}

class _CeramicBatchEditPageState extends State<CeramicBatchEditPage> {
  final _addTags = TextEditingController();
  final _removeTags = TextEditingController();
  final _height = TextEditingController();
  final _width = TextEditingController();
  final _depth = TextEditingController();
  final _diameter = TextEditingController();
  int? _stageId;
  String _clayMode = 'KEEP';
  int? _clayId;
  List<ProjectTemplateDto> _templates = const [];
  int? _templateId;
  bool _applyGlazes = false;
  bool _applyFirings = false;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    for (final controller in [
      _addTags,
      _removeTags,
      _height,
      _width,
      _depth,
      _diameter,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.batchEdit)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _BatchEditSection(
                  icon: Icons.info_outline,
                  title: context.l10n.selectedCeramics(
                    widget.ceramicIds.length,
                  ),
                  description: context.l10n.batchEditSafetyNote,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(_error!),
                      trailing: IconButton(
                        tooltip: context.l10n.ok,
                        onPressed: () => setState(() => _error = null),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _BatchEditSection(
                  icon: Icons.tune,
                  title: context.l10n.batchBasics,
                  children: [
                    DropdownButtonFormField<int?>(
                      isExpanded: true,
                      initialValue: _stageId,
                      decoration: InputDecoration(
                        labelText: context.l10n.changeStage,
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(context.l10n.keepCurrent),
                        ),
                        ...widget.stages.map(
                          (stage) => DropdownMenuItem<int?>(
                            value: stage.id,
                            child: Text(
                              localizedStageName(context.l10n, stage.title),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _stageId = value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _clayMode,
                      decoration: InputDecoration(
                        labelText: context.l10n.changeClay,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'KEEP',
                          child: Text(context.l10n.keepCurrent),
                        ),
                        DropdownMenuItem(
                          value: 'CLEAR',
                          child: Text(context.l10n.clearClay),
                        ),
                        DropdownMenuItem(
                          value: 'SET',
                          child: Text(context.l10n.setClay),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _clayMode = value ?? 'KEEP'),
                    ),
                    if (_clayMode == 'SET') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: _clayId,
                        decoration: InputDecoration(
                          labelText: context.l10n.clay,
                        ),
                        items: widget.clays
                            .map(
                              (clay) => DropdownMenuItem(
                                value: clay.id,
                                child: Text(clay.title),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _clayId = value),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _BatchEditSection(
                  icon: Icons.sell_outlined,
                  title: context.l10n.batchTagChanges,
                  description: context.l10n.commaSeparatedTags,
                  children: [
                    TextField(
                      controller: _addTags,
                      decoration: InputDecoration(
                        labelText: context.l10n.addTags,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _removeTags,
                      decoration: InputDecoration(
                        labelText: context.l10n.removeTags,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _BatchEditSection(
                  icon: Icons.straighten,
                  title: context.l10n.applyDimensions,
                  description: context.l10n.batchDimensionsHelp,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 480;
                        final width = twoColumns
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 16,
                          children: [
                            _dimension(_height, context.l10n.height, width),
                            _dimension(_width, context.l10n.width, width),
                            _dimension(_depth, context.l10n.depth, width),
                            _dimension(
                              _diameter,
                              context.l10n.diameter,
                              width,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _BatchEditSection(
                  icon: Icons.event_note_outlined,
                  title: context.l10n.applyPlanningTemplate,
                  description: context.l10n.batchPlanningHelp,
                  children: [
                    DropdownButtonFormField<int?>(
                      isExpanded: true,
                      initialValue: _templateId,
                      decoration: InputDecoration(
                        labelText: context.l10n.projectTemplate,
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(context.l10n.none),
                        ),
                        ..._templates.map(
                          (template) => DropdownMenuItem<int?>(
                            value: template.id,
                            child: Text(template.name),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        _templateId = value;
                        if (value == null) {
                          _applyGlazes = false;
                          _applyFirings = false;
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _applyGlazes,
                      onChanged: _templateId == null
                          ? null
                          : (value) =>
                                setState(() => _applyGlazes = value ?? false),
                      title: Text(context.l10n.applyGlazesOnlyWhenEmpty),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: _applyFirings,
                      onChanged: _templateId == null
                          ? null
                          : (value) =>
                                setState(() => _applyFirings = value ?? false),
                      title: Text(context.l10n.applySafeFiringPlans),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _preview,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fact_check_outlined),
                    label: Text(context.l10n.reviewBatchEdit),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _dimension(
    TextEditingController controller,
    String label,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: '$label (cm)'),
      ),
    );
  }

  Future<void> _loadTemplates() async {
    try {
      final page = await (widget.templateLoader?.call() ??
          ProjectTemplateRepository.list());
      if (mounted) setState(() => _templates = page.items);
    } catch (value) {
      if (mounted) setState(() => _error = value.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  CeramicBatchEditSpec _spec() => CeramicBatchEditSpec(
    stageId: _stageId,
    clayMode: _clayMode,
    clayId: _clayId,
    addTags: _tags(_addTags.text),
    removeTags: _tags(_removeTags.text),
    heightCm: _number(_height.text),
    widthCm: _number(_width.text),
    depthCm: _number(_depth.text),
    diameterCm: _number(_diameter.text),
    planningTemplateId: _templateId,
    applyGlazes: _applyGlazes,
    applyFirings: _applyFirings,
  );

  Future<void> _preview() async {
    if (_clayMode == 'SET' && _clayId == null) {
      setState(() => _error = context.l10n.chooseClay);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final spec = _spec();
    try {
      final preview = await CeramicBatchRepository.preview(
        ceramicIds: widget.ceramicIds,
        edit: spec,
      );
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.confirmBatchEdit),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.batchEditTargetCount(preview.selectedCount),
                  ),
                  const SizedBox(height: 12),
                  ...preview.changes.map(
                    (change) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.check, size: 18),
                      title: Text(change),
                    ),
                  ),
                  if (preview.targets.any((value) => value.warnings.isNotEmpty))
                    Text(
                      context.l10n.protectedItemsWillBeSkipped,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  for (final target in preview.targets)
                    for (final warning in target.warnings)
                      Text('• ${target.title}: $warning'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.apply),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final result = await CeramicBatchRepository.apply(
        preview: preview,
        edit: spec,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            result.skippedCount == 0
                ? context.l10n.batchEditComplete
                : context.l10n.batchEditPartiallyComplete,
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.batchEditResult(
                      result.updatedCount,
                      result.skippedCount,
                    ),
                  ),
                  for (final target in result.targets)
                    if (!target.updated || target.warnings.isNotEmpty)
                      ListTile(
                        dense: true,
                        title: Text(target.title),
                        subtitle: Text(
                          [target.status, ...target.warnings].join('\n'),
                        ),
                      ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.ok),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, result.updatedCount > 0);
    } catch (value) {
      if (mounted) setState(() => _error = value.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static List<String> _tags(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();

  static double? _number(String value) =>
      value.trim().isEmpty ? null : double.tryParse(value.trim());
}

class _BatchEditSection extends StatelessWidget {
  const _BatchEditSection({
    required this.icon,
    required this.title,
    this.description,
    this.children = const [],
  });

  final IconData icon;
  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 10),
            Text(
              description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (children.isNotEmpty) ...[
            const SizedBox(height: 18),
            ...children,
          ],
        ],
      ),
    ),
  );
}
