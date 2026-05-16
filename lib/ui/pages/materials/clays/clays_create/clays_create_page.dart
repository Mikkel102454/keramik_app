import 'dart:io';

import 'package:ceramic_app/ui/pages/image_view/image_view_page.dart';
import 'package:ceramic_app/ui/pages/materials/clays/clays_create/clays_create_page_controller.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ClaysCreatePage extends StatefulWidget {
  const ClaysCreatePage({super.key});

  @override
  State<ClaysCreatePage> createState() => _ClaysCreatePageState();
}

class _ClaysCreatePageState extends State<ClaysCreatePage> {
  final ClaysCreatePageController _controller = ClaysCreatePageController();

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
        title: const Text("Clay body"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _createClay();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.error != null) {
              return Center(child: Text("Error: ${_controller.error}"));
            }

            return RefreshIndicator(
              onRefresh: () async {
                _controller.load();
              },
              child: _pageContent(_controller),
            );
          },
        ),
      ),
    );
  }

  SingleChildScrollView _pageContent(ClaysCreatePageController controller) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // =========================
          // Images
          // =========================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,

            physics: const BouncingScrollPhysics(),

            child: Row(
              children: [
                for (final entry in controller.images.asMap().entries) ...[
                  SquareWidget(
                    width: 92,
                    height: 92,
                    imageFile: entry.value,
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black87,
                        builder: (_) => ImageViewPage(
                          xFile: entry.value,
                          onDelete: () async {
                            final success = await controller.deleteImage(
                              entry.key,
                            );

                            if (success && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 12),
                ],

                SquareWidget(
                  icon: Icons.add,
                  iconColor: Colors.grey.shade500,
                  iconSize: 42,
                  width: 92,
                  height: 92,
                  backgroundColor: Colors.grey.shade300,
                  onPressed: () async {
                    final source = await showModalBottomSheet<ImageSource>(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Select from gallery'),
                                onTap: () {
                                  Navigator.pop(context, ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Take a picture'),
                                onTap: () {
                                  Navigator.pop(context, ImageSource.camera);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    if (source == null) return;

                    final picked = await ImagePicker().pickImage(
                      source: source,
                    );

                    if (picked != null) {
                      controller.uploadImage(File(picked.path));
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // =========================
          // Information
          // =========================
          TextWidget(
            text: "Information",
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          TextWidget(
            text: "Title",
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 4),
          TextFieldWidget(
            placeholder: "Title",
            onChanged: (value) async {
              controller.setTitle(value);
              return true;
            },
          ),

          const SizedBox(height: 12),

          TextWidget(
            text: "Supplier",
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 4),
          TextFieldWidget(
            placeholder: "Supplier",
            onChanged: (value) async {
              controller.setSupplier(value);
              return true;
            },
          ),

          const SizedBox(height: 20),

          // =========================
          // Notes
          // =========================
          TextWidget(text: "Notes", fontSize: 18, fontWeight: FontWeight.w700),
          const SizedBox(height: 8),

          TextFieldWidget(
            placeholder: "Clay notes",

            minLines: 3,
            maxLines: 5,

            onChanged: (value) async {
              controller.setNotes(value);
              return true;
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _createClay() async {
    if (_controller.title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a title")));
      return;
    }

    try {
      await _controller.create();
      if (!context.mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Create failed: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}
