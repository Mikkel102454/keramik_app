import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/project_template_dto.dart';
import 'package:ceramic_app/repositories/project_template_repository.dart';
import 'package:flutter/material.dart';

class TemplateBatchCreatePage extends StatefulWidget {
  const TemplateBatchCreatePage({super.key, required this.template});
  final ProjectTemplateDto template;

  @override
  State<TemplateBatchCreatePage> createState() =>
      _TemplateBatchCreatePageState();
}

class _TemplateBatchCreatePageState extends State<TemplateBatchCreatePage> {
  int _quantity = 1;
  int _start = 1;
  TemplateBatchPreviewDto? _preview;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshPreview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.createFromTemplate)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.template.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(context.l10n.batchQuantity(_quantity)),
          Slider(
            value: _quantity.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            label: '$_quantity',
            onChanged: _loading
                ? null
                : (value) => setState(() => _quantity = value.round()),
            onChangeEnd: (_) => _refreshPreview(),
          ),
          TextFormField(
            initialValue: '1',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.l10n.startNumber,
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            onChanged: (value) =>
                _start = int.tryParse(value)?.clamp(1, 9999) ?? 1,
            onFieldSubmitted: (_) => _refreshPreview(),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.titlePreview,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Column(
              children: [
                Text(_error!),
                FilledButton(
                  onPressed: _refreshPreview,
                  child: Text(context.l10n.retry),
                ),
              ],
            )
          else
            ...?_preview?.titles.map(
              (title) => ListTile(
                dense: true,
                leading: const Icon(Icons.circle, size: 8),
                title: Text(title),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading || _preview == null ? null : _create,
            icon: const Icon(Icons.library_add),
            label: Text(
              _quantity == 1
                  ? context.l10n.createOneCeramic
                  : context.l10n.createCeramicBatch(_quantity),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await ProjectTemplateRepository.preview(
        templateId: widget.template.id,
        quantity: _quantity,
        startNumber: _start,
      );
      if (mounted) setState(() => _preview = value);
    } catch (value) {
      if (mounted) setState(() => _error = value.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final preview = _preview!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.confirmBatchCreation),
        content: Text(context.l10n.confirmBatchCreationBody(_quantity)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.create),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loading = true);
    try {
      final titles = await ProjectTemplateRepository.createCeramics(
        templateId: widget.template.id,
        quantity: _quantity,
        startNumber: _start,
        expectedVersion: preview.templateVersion,
      );
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.batchCreated),
            content: Text(context.l10n.batchCreatedBody(titles.length)),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.l10n.ok),
              ),
            ],
          ),
        );
        if (mounted) Navigator.pop(context, true);
      }
    } catch (value) {
      if (mounted) setState(() => _error = value.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
