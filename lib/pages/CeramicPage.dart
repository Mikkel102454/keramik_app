import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kemik_app/classes/cemaric_glaze_note_dto.dart';
import 'package:kemik_app/classes/ceramic_dto.dart';
import 'package:kemik_app/classes/stage_dto.dart';
import 'package:kemik_app/features/ceramics/logic/CeramicController.dart';
import 'package:kemik_app/pages/todo/settings_page.dart';
import 'package:kemik_app/ui/inputs/GlazeListWidget.dart';
import 'package:kemik_app/ui/inputs/InlineTagsWidget.dart';
import 'package:kemik_app/ui/inputs/NumberInputWidget.dart';
import 'package:kemik_app/ui/inputs/TextAreaWidget.dart';
import 'package:kemik_app/ui/inputs/TextInputWidget.dart';
import 'package:kemik_app/ui/widgets/ProgressStepperWidget.dart';
import 'package:kemik_app/ui/widgets/RatingWidget.dart';
import 'package:kemik_app/ui/widgets/TitleWidget.dart';

import '../network/ceramic.dart';
import '../classes/ceramic_tag_dto.dart';
import '../classes/category_dto.dart';
import '../ui/layouts/GridLayout.dart';
import '../ui/widgets/SquareWidgetIcon.dart';

class CeramicPage extends StatefulWidget {
  final CeramicDto ceramic;

  const CeramicPage({
    super.key,
    required this.ceramic,
  });

  @override
  State<CeramicPage> createState() => _CeramicPageState();
}

class _CeramicPageState extends State<CeramicPage> {
  late final CeramicController _controller;

  // ===================== INIT =====================

  @override
  void initState() {
    super.initState();
    _controller = CeramicController(widget.ceramic);
  }

  // ===================== DELETE =====================

  //TODO optimise ui
  void _deleteProject() {
    final parentContext = context;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Delete Project?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  await _controller.delete();

                  Navigator.pop(parentContext, true);
                } catch (e) {
                  debugPrint('$e');
                }
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStage(StageDto stage) async {
    try {
      await _controller.updateStage(stage);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateTitle(String title) async {
    try {
      await _controller.updateTitle(title);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateType(String type) async {
    try {
      await _controller.updateType(type);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateWeight(double weight) async {
    try {
      await _controller.updateWeight(weight);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateGlazes(List<String> glazes) async {
    try {
      await _controller.updateGlazes(glazes);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateTags(List<String> tags) async {
    try {
      await _controller.updateTags(tags);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateRating(int rating) async {
    try {
      await _controller.updateRating(rating);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateNotes(String notes) async {
    try {
      await _controller.updateNotes(notes);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (_controller.error != null) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Text(
                  _controller.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Text(
                _controller.title.isEmpty ? 'Ceramic' : _controller.title,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  offset: const Offset(0, kToolbarHeight),
                  color: Colors.grey[900],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteProject();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _controller.load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageRow(),
                    const SizedBox(height: 25),
                    TitleWidget(title: 'PROGRESS'),
                    ProgressStepperWidget(
                      stages: _controller.stages,
                      currentStep: _controller.stage,
                      onChanged: (stage) async {
                        await _updateStage(stage);
                      },
                    ),
                    const SizedBox(height: 30),
                    TitleWidget(title: 'INFORMATION'),
                    TextInputWidget(
                      label: 'Title',
                      initialValue: _controller.title,
                      delayedCallback: (value) async {
                        await _updateTitle(value);
                      },
                    ),
                    TextInputWidget(
                      label: 'Clay Type',
                      initialValue: _controller.clayType,
                      delayedCallback: (value) async {
                        await _updateType(value);
                      },
                    ),
                    NumberInputWidget(
                      key: ValueKey(_controller.weight),
                      label: 'Weight',
                      initialValue: _controller.weight.toString(),
                      suffix: 'kg',
                      delayedCallback: (value) async {
                        await _updateWeight(double.tryParse(value) ?? 0.0);
                      },
                    ),
                    const SizedBox(height: 20),
                    TitleWidget(title: 'GLAZES'),
                    GlazeListWidget(
                      initialGlazes: _controller.glazes.map((e) => e.note).toList(),
                      onChanged: (updatedGlazes) async {
                        await _updateGlazes(updatedGlazes);
                      },
                      delayedCallback: (updatedGlazes) async {
                        await _updateGlazes(updatedGlazes);
                      },
                    ),
                    const SizedBox(height: 25),
                    RatingWidget(
                      rating: _controller.rating,
                      onChanged: (newRating) async {
                        await _updateRating(newRating);
                      },
                    ),
                    const SizedBox(height: 25),
                    TitleWidget(title: 'TAGS'),
                    InlineTagsWidget(
                      initialTags: _controller.tags.map((e) => e.tag).toList(),
                      onChanged: (updatedTags) async {
                        await _updateTags(updatedTags);
                      },
                    ),
                    const SizedBox(height: 30),
                    TitleWidget(title: 'NOTES'),
                    TextAreaWidget(
                      hint: 'Write notes...',
                      initialValue: _controller.notes,
                      minLines: 4,
                      delayedCallback: (value) async {
                        await _updateNotes(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  // ===================== IMAGE =====================

  Widget _buildImageRow() {
    List<Widget> children = [];

    for (int i = 0; i < 10; i++) {
      children.add(SquareWidgetIcon(icon: i == 0 ? Icons.camera_alt : Icons.image));
    }
    return SizedBox(
      height: 100,
      child: GridLayout(
        crossAxisCount: 1,
        scrollDirection: Axis.horizontal,
        children: children,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
