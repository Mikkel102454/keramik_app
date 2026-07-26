import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/project_template_dto.dart';
import 'package:ceramic_app/ui/pages/home/templates/project_template_editor_page.dart';
import 'package:ceramic_app/ui/pages/home/templates/project_templates_controller.dart';
import 'package:ceramic_app/ui/pages/home/templates/template_batch_create_page.dart';
import 'package:flutter/material.dart';

class ProjectTemplatesPage extends StatefulWidget {
  const ProjectTemplatesPage({super.key, this.pickForCreation = false});
  final bool pickForCreation;

  @override
  State<ProjectTemplatesPage> createState() => _ProjectTemplatesPageState();
}

class _ProjectTemplatesPageState extends State<ProjectTemplatesPage> {
  final ProjectTemplatesController _controller = ProjectTemplatesController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.projectTemplates),
        actions: [
          IconButton(
            tooltip: context.l10n.createTemplate,
            onPressed: _controller.loading ? null : _create,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.loading && _controller.templates.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.error != null && _controller.templates.isEmpty) {
            return _Retry(onRetry: _controller.load);
          }
          if (_controller.templates.isEmpty) {
            return _Empty(onCreate: _create);
          }
          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              itemCount:
                  _controller.templates.length +
                  (_controller.nextCursor == null ? 0 : 1),
              itemBuilder: (context, index) {
                if (index == _controller.templates.length) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton(
                      onPressed: _controller.loadingMore
                          ? null
                          : _controller.loadMore,
                      child: _controller.loadingMore
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.loadMore),
                    ),
                  );
                }
                return _templateCard(_controller.templates[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _templateCard(ProjectTemplateDto template) {
    final unavailable =
        !template.clayAvailable ||
        template.glazes.any((value) => !value.available);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _createFrom(template),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _action(action, template),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(context.l10n.edit),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text(context.l10n.duplicate),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(context.l10n.delete),
                      ),
                    ],
                  ),
                ],
              ),
              Text(template.titlePattern),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (template.clayTitle != null)
                    Chip(
                      avatar: const Icon(Icons.landscape_outlined, size: 16),
                      label: Text(template.clayTitle!),
                    ),
                  Chip(
                    label: Text(
                      context.l10n.templateGlazeCount(template.glazes.length),
                    ),
                  ),
                  Chip(
                    label: Text(
                      context.l10n.templateFiringCount(template.firings.length),
                    ),
                  ),
                ],
              ),
              if (unavailable) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(context.l10n.templateMaterialMissing)),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: unavailable ? null : () => _createFrom(template),
                icon: const Icon(Icons.library_add),
                label: Text(context.l10n.useTemplate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    final result = await Navigator.push<ProjectTemplateDto>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectTemplateEditorPage(
          clays: _controller.clays,
          glazes: _controller.glazes,
        ),
      ),
    );
    if (result != null) _controller.replace(result);
  }

  Future<void> _createFrom(ProjectTemplateDto template) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateBatchCreatePage(template: template),
      ),
    );
    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _action(String action, ProjectTemplateDto template) async {
    if (action == 'edit') {
      final result = await Navigator.push<ProjectTemplateDto>(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectTemplateEditorPage(
            clays: _controller.clays,
            glazes: _controller.glazes,
            template: template,
          ),
        ),
      );
      if (result != null) _controller.replace(result);
      return;
    }
    if (action == 'duplicate') {
      final name = await _askName(
        context.l10n.duplicateTemplate,
        context.l10n.copyOfTemplate(template.name),
      );
      if (name != null) {
        try {
          await _controller.duplicate(template, name);
        } catch (value) {
          _showError(value);
        }
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteTemplate),
        content: Text(context.l10n.deleteTemplateBody(template.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _controller.delete(template);
      } catch (value) {
        _showError(value);
      }
    }
  }

  Future<String?> _askName(String title, String initial) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLength: 100,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.templateName,
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) Navigator.pop(dialogContext, name);
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    return value;
  }

  void _showError(Object value) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(value.toString())));
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.content_copy_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              context.l10n.noProjectTemplates,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.noProjectTemplatesBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: Text(context.l10n.createTemplate),
            ),
          ],
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.templatesLoadFailed),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
