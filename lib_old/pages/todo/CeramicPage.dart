import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kemik_app/classes/ceramic_glaze_note_dto.dart';
import 'package:kemik_app/classes/stage_dto.dart';
import 'package:kemik_app/pages/todo/settings_page.dart';

import '../../../network/ceramic.dart';
import '../../../classes/ceramic_tag_dto.dart';
import '../../../classes/category_dto.dart';

const int TITLETIMER = 300;
const int TYPETIMER = 300;
const int WEIGHTTIMER = 300;
const int GLAZETIMER = 300;
const int NOTETIMER = 300;


class CeramicPage extends StatefulWidget {
  final int ceramicId;

  const CeramicPage({
    super.key,
    required this.ceramicId,
  });

  @override
  State<CeramicPage> createState() => _CeramicPageState();
}

class _CeramicPageState extends State<CeramicPage> {
  bool loading = true;
  bool _changed = false;

  String localTitle = "";

  late StageDto currentStep;
  int rating = 0;

  // Controllers
  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController clayController =
  TextEditingController();

  final TextEditingController weightController =
  TextEditingController();

  final TextEditingController notesController =
  TextEditingController();

  final TextEditingController tagController =
  TextEditingController();

  final List<TextEditingController> glazeControllers = [];

  final List<String> tags = [];

  List<CeramicTagDto> tagsFromApi = [];
  List<CeramicGlazeNoteDto> glazesFromApi = [];
  List<CategoryDto> categoriesFromApi = [];

  final List<StageDto> stages = [];

  String selectedCategory = "";

  // ===================== TIMERS =====================

  Timer? _titleTimer;
  Timer? _typeTimer;
  Timer? _weightTimer;
  Timer? _noteTimer;

  final Map<int, Timer> _glazeTimers = {};

  // ===================== INIT =====================

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final ceramics = await getCeramics();
      final tagsData = await getTags(widget.ceramicId);
      final glazeData = await getGlazeNotes(widget.ceramicId);
      final stagesData = await getStages();

      final ceramic =
      ceramics.firstWhere((c) => c.id == widget.ceramicId);

      setState(() {
        rating = ceramic.rate.toInt();

        titleController.text = ceramic.title;
        localTitle = ceramic.title;

        clayController.text = ceramic.type;
        weightController.text = ceramic.weight.toString();
        notesController.text = ceramic.note;

        tagsFromApi = tagsData;

        tags
          ..clear()
          ..addAll(tagsData.map((e) => e.tag));

        stages
          ..clear()
          ..addAll(stagesData)
          ..sort((a, b) => a.id.compareTo(b.id));

        currentStep =
            stages.firstWhere((s) => s.id == ceramic.stage);

        glazesFromApi = glazeData;

        glazeControllers.clear();

        for (var g in glazeData) {
          glazeControllers.add(
            TextEditingController(text: g.note),
          );
        }

        loading = false;
      });
    } catch (e) {
      debugPrint("Load error: $e");
    }
  }

  // ===================== DELETE =====================

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
            "Delete Project?",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            "This action cannot be undone.",
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
              ),
            ),

            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  await deleteCeramic(widget.ceramicId);

                  Navigator.pop(parentContext, true);
                } catch (e) {
                  debugPrint("$e");
                }
              },

              child: const Text(
                "Delete",
              ),
            ),
          ],
        );
      },
    );
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },

      child: Scaffold(
        backgroundColor: Colors.black,

        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            localTitle.isEmpty ? "Ceramic" : localTitle,
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
          onRefresh: _loadData,

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageRow(),

                const SizedBox(height: 25),

                _buildProgress(),

                const SizedBox(height: 30),

                _section("INFORMATION"),

                _buildTitleField(),

                _buildLabeledInput(
                  label: "Clay Type",
                  controller: clayController,
                ),

                _buildLabeledInput(
                  label: "Weight",
                  controller: weightController,
                  suffix: "kg",
                  numberOnly: true,
                ),

                const SizedBox(height: 20),

                _section("GLAZES"),

                _buildGlazeList(),

                const SizedBox(height: 25),

                _buildRating(),

                const SizedBox(height: 25),

                _section("TAGS"),

                _buildInlineTags(),

                const SizedBox(height: 30),

                _section("NOTES"),

                _buildNotes(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== TITLE =====================

  Widget _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Title",
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),

          const SizedBox(height: 6),

          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),

            child: TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),

              onChanged: (value) {
                final previous = localTitle;

                setState(() {
                  localTitle = value;
                  _changed = true;
                });

                _titleTimer?.cancel();

                _titleTimer = Timer(
                  const Duration(milliseconds: TITLETIMER),
                      () async {
                    try {
                      await renameCeramic(
                        widget.ceramicId,
                        value.trim(),
                      );
                    } catch (e) {
                      setState(() {
                        localTitle = previous;
                        titleController.text = previous;
                      });
                    }
                  },
                );
              },

              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(14),
                hintText: "Project title",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== IMAGE =====================

  Widget _buildImageRow() {
    return SizedBox(
      height: 90,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,

        itemBuilder: (context, index) {
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 10),

            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),

            child: index == 0
                ? const Icon(Icons.camera_alt, color: Colors.white)
                : const Icon(Icons.image, color: Colors.grey),
          );
        },
      ),
    );
  }

  // ===================== PROGRESS =====================

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "PROGRESS",
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: List.generate(stages.length, (index) {
            final done = stages[index].id <= currentStep.id;

            return Expanded(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final old = currentStep;

                      setState(() {
                        currentStep = stages[index];
                        _changed = true;
                      });

                      try {
                        await setProgress(
                          widget.ceramicId,
                          stages[index].id,
                        );
                      } catch (e) {
                        setState(() {
                          currentStep = old;
                          _changed = false;
                        });
                      }
                    },

                    child: CircleAvatar(
                      radius: 14,

                      backgroundColor:
                      done ? Colors.green : Colors.grey,

                      child: done
                          ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.black,
                      )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    stages[index].title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  )
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ===================== SECTION =====================

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // ===================== INPUT =====================

  Widget _buildLabeledInput({
    required String label,
    required TextEditingController controller,
    String? suffix,
    bool numberOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),

          const SizedBox(height: 6),

          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),

            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),

              keyboardType:
              numberOnly ? TextInputType.number : TextInputType.text,

              inputFormatters: numberOnly
                  ? [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9\.,]'),
                ),
              ]
                  : null,

              onChanged: (value) {
                if (label == "Clay Type") {
                  final old = clayController.text;

                  _typeTimer?.cancel();

                  _typeTimer = Timer(
                    const Duration(milliseconds: TYPETIMER),
                        () async {
                      try {
                        await setType(
                          widget.ceramicId,
                          value,
                        );
                      } catch (e) {
                        clayController.text = old;
                      }
                    },
                  );
                }

                if (numberOnly) {
                  final old = weightController.text;

                  _weightTimer?.cancel();

                  _weightTimer = Timer(
                    const Duration(milliseconds: WEIGHTTIMER),
                        () async {
                      final w = double.tryParse(value);

                      if (w != null) {
                        try {
                          await setWeight(
                            widget.ceramicId,
                            w,
                          );
                        } catch (e) {
                          weightController.text = old;
                        }
                      }
                    },
                  );
                }
              },

              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(14),
                hintText: label,
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                suffixText: suffix,
                suffixStyle:
                const TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== GLAZES =====================

  Widget _buildGlazeList() {
    return Column(
      children: [
        ...List.generate(glazeControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),

            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: TextField(
                      controller: glazeControllers[index],
                      style: const TextStyle(color: Colors.white),

                      onChanged: (value) {
                        final old =
                            glazeControllers[index].text;

                        _glazeTimers[index]?.cancel();

                        _glazeTimers[index] = Timer(
                          const Duration(milliseconds: GLAZETIMER),
                              () async {
                            try {
                              await editGlazeNote(
                                widget.ceramicId,
                                glazesFromApi[index].id,
                                value,
                              );
                            } catch (e) {
                              glazeControllers[index].text =
                                  old;
                            }
                          },
                        );
                      },

                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(14),
                        hintText: "Glaze note",
                        hintStyle:
                        TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                IconButton(
                  onPressed: () async {
                    if (index < 0 || index >= glazeControllers.length) return;
                    final oldController = glazeControllers[index];

                    final oldGlaze = glazesFromApi[index];

                    setState(() {
                      glazeControllers.removeAt(index);
                      glazesFromApi.removeAt(index);
                    });

                    try {
                      await removeGlazeNote(
                        widget.ceramicId,
                        oldGlaze.id,
                      );
                    } catch (e) {
                      setState(() {
                        glazeControllers.insert(
                            index, oldController);

                        glazesFromApi.insert(index, oldGlaze);
                      });
                    }
                  },

                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                  ),
                )
              ],
            ),
          );
        }),

        Align(
          alignment: Alignment.centerLeft,

          child: TextButton.icon(
            onPressed: () async {
              final temp = TextEditingController();

              setState(() {
                glazeControllers.add(temp);
              });

              try {
                final temp2 = await addGlazeNote(widget.ceramicId, "");
                glazesFromApi.add(temp2);
              } catch (e) {
                setState(() {
                  glazeControllers.remove(temp);
                });
              }
            },

            icon: const Icon(Icons.add),
            label: const Text("Add glaze"),
          ),
        )
      ],
    );
  }

  // ===================== TAGS =====================

  Widget _buildInlineTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,

          children: List.generate(tags.length, (index) {
            return Chip(
              backgroundColor: Colors.grey[800],

              label: Text(
                tags[index],
                style: const TextStyle(color: Colors.white),
              ),

              deleteIconColor: Colors.white54,

              onDeleted: () async {
                final oldTags = List<String>.from(tags);
                final oldApi =
                List<CeramicTagDto>.from(tagsFromApi);

                setState(() {
                  tags.removeAt(index);
                  tagsFromApi.removeAt(index);
                });

                try {
                  await removeTag(
                    widget.ceramicId,
                    oldApi[index].id,
                  );
                } catch (e) {
                  setState(() {
                    tags
                      ..clear()
                      ..addAll(oldTags);

                    tagsFromApi
                      ..clear()
                      ..addAll(oldApi);
                  });
                }
              },
            );
          }),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),

                child: TextField(
                  controller: tagController,
                  style: const TextStyle(color: Colors.white),

                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    hintText: "Add tag...",
                    hintStyle:
                    TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),

                  onSubmitted: (_) => _addTagInline(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            IconButton(
              onPressed: _addTagInline,
              icon: const Icon(Icons.add_circle),
              color: Colors.green,
            ),
          ],
        )
      ],
    );
  }

  Future<void> _addTagInline() async {
    final text = tagController.text.trim();

    if (text.isEmpty) return;

    final oldTags = List<String>.from(tags);

    setState(() {
      tags.add(text);
      tagController.clear();
    });

    try {
      await addTag(widget.ceramicId, text);

      final data = await getTags(widget.ceramicId);

      setState(() {
        tagsFromApi = data;
        tags
          ..clear()
          ..addAll(data.map((e) => e.tag));
      });

    } catch (e) {
      setState(() {
        tags
          ..clear()
          ..addAll(oldTags);
      });

      debugPrint(e.toString());
    }
  }

  // ===================== RATING =====================

  Widget _buildRating() {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          padding: EdgeInsets.zero,

          onPressed: () async {
            final value = index + 1;
            final old = rating;

            setState(() {
              rating = value;
            });

            try {
              await setRate(
                widget.ceramicId,
                value,
              );
            } catch (e) {
              setState(() {
                rating = old;
              });
            }
          },

          icon: Icon(
            Icons.star,
            color:
            index < rating ? Colors.green : Colors.grey,
          ),
        );
      }),
    );
  }

  // ===================== NOTES =====================

  Widget _buildNotes() {
    return TextField(
      controller: notesController,
      maxLines: 6,
      style: const TextStyle(color: Colors.white),

      onChanged: (value) {
        final old = notesController.text;

        _noteTimer?.cancel();

        _noteTimer = Timer(
          const Duration(milliseconds: NOTETIMER),
              () async {
            try {
              await setNote(
                widget.ceramicId,
                value,
              );
            } catch (e) {
              notesController.text = old;
            }
          },
        );
      },

      decoration: InputDecoration(
        hintText: "Write notes...",
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.grey[900],

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ===================== MENU ITEM =====================

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String text,
    Color color = Colors.white,
  }) {
    return PopupMenuItem(
      value: value,

      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  // ===================== CLEANUP =====================

  @override
  void dispose() {
    _titleTimer?.cancel();
    _typeTimer?.cancel();
    _weightTimer?.cancel();
    _noteTimer?.cancel();

    titleController.dispose();
    clayController.dispose();
    weightController.dispose();
    notesController.dispose();
    tagController.dispose();

    for (final t in _glazeTimers.values) {
      t.cancel();
    }

    for (final c in glazeControllers) {
      c.dispose();
    }

    super.dispose();
  }
}