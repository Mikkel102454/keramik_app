import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/objects/project_template_dto.dart';
import 'package:ceramic_app/repositories/clay_repository.dart';
import 'package:ceramic_app/repositories/glaze_repository.dart';
import 'package:ceramic_app/repositories/project_template_repository.dart';
import 'package:flutter/foundation.dart';

typedef TemplatePageLoader =
    Future<ProjectTemplatePageDto> Function({String? cursor});
typedef TemplateClayLoader = Future<List<ClayDto>> Function();
typedef TemplateGlazeLoader = Future<List<GlazeDto>> Function();

class ProjectTemplatesController extends ChangeNotifier {
  ProjectTemplatesController({
    TemplatePageLoader? loader,
    TemplateClayLoader? clayLoader,
    TemplateGlazeLoader? glazeLoader,
  }) : _loader = loader ?? ProjectTemplateRepository.list,
       _clayLoader = clayLoader ?? ClayRepository.getClayTypes,
       _glazeLoader = glazeLoader ?? GlazeRepository.getGlazes;

  final TemplatePageLoader _loader;
  final TemplateClayLoader _clayLoader;
  final TemplateGlazeLoader _glazeLoader;
  final List<ProjectTemplateDto> templates = [];
  List<ClayDto> clays = const [];
  List<GlazeDto> glazes = const [];
  String? nextCursor;
  bool loading = false;
  bool loadingMore = false;
  Object? error;
  bool _disposed = false;

  Future<void> load() async {
    if (_disposed || loading) return;
    loading = true;
    error = null;
    _notify();
    try {
      final values = await Future.wait<dynamic>([
        _loader(),
        _clayLoader(),
        _glazeLoader(),
      ]);
      if (_disposed) return;
      final page = values[0] as ProjectTemplatePageDto;
      templates
        ..clear()
        ..addAll(page.items);
      nextCursor = page.nextCursor;
      clays = values[1] as List<ClayDto>;
      glazes = values[2] as List<GlazeDto>;
    } catch (value) {
      error = value;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> loadMore() async {
    final cursor = nextCursor;
    if (_disposed || cursor == null || loadingMore) return;
    loadingMore = true;
    _notify();
    try {
      final page = await _loader(cursor: cursor);
      templates.addAll(page.items);
      nextCursor = page.nextCursor;
    } catch (value) {
      error = value;
    } finally {
      loadingMore = false;
      _notify();
    }
  }

  Future<void> delete(ProjectTemplateDto template) async {
    await ProjectTemplateRepository.delete(template.id);
    templates.removeWhere((value) => value.id == template.id);
    _notify();
  }

  Future<void> duplicate(ProjectTemplateDto template, String name) async {
    final created = await ProjectTemplateRepository.duplicate(
      template.id,
      name,
    );
    templates.insert(0, created);
    _notify();
  }

  void replace(ProjectTemplateDto template) {
    final index = templates.indexWhere((value) => value.id == template.id);
    if (index < 0) {
      templates.insert(0, template);
    } else {
      templates[index] = template;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
