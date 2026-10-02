import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_create/glazes_create_page_controller.dart';
import 'package:ceramic_app/ui/widgets/v2/ui_library.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class GlazesCreatePage extends StatefulWidget {
  const GlazesCreatePage({super.key, this.glaze});
  final GlazeDto? glaze;
  @override
  State<GlazesCreatePage> createState() => _GlazesCreatePageState();
}

class _GlazesCreatePageState extends State<GlazesCreatePage> {
  final _controller = GlazesCreatePageController();
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  bool _saving = false, _leaving = false, _dirty = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.glaze?.title ?? '');
    _title.addListener(() {
      final changed = _title.text != (widget.glaze?.title ?? '');
      if (_dirty != changed) setState(() => _dirty = changed);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_saving) return;
    if (!_dirty || await confirmEntryDiscard(context)) {
      if (!mounted) return;
      setState(() => _leaving = true);
      Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    _controller.setTitle(_title.text);
    try {
      await _controller.save(widget.glaze?.id);
      if (!mounted) return;
      setState(() {
        _leaving = true;
        _dirty = false;
        _saving = false;
      });
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.l10n.notebookFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _leaving || (!_dirty && !_saving),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: Form(
      key: _form,
      child: EntryPage(
        title: widget.glaze == null
            ? context.l10n.createGlaze
            : context.l10n.editGlaze,
        onSave: _save,
        busy: _saving,
        error: _error,
        children: [
          EntrySection(
            title: context.l10n.information,
            children: [
              TextFieldWidget(
                controller: _title,
                label: context.l10n.title,
                maxLength: 255,
                validator: (value, _) =>
                    value == null || value.trim().isEmpty || value.length > 255
                    ? context.l10n.titleValidation
                    : null,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
