import 'dart:io';

import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/ui/pages/image_view/image_view_page.dart';
import 'package:ceramic_app/ui/pages/materials/clays/clays_view/clays_view_page_controller.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ClaysViewPage extends StatefulWidget {
  final ClayDto clay;

  const ClaysViewPage({
    super.key,
    required this.clay
  });

  @override
  State<ClaysViewPage> createState() => _ClaysViewPageState();
}

class _ClaysViewPageState extends State<ClaysViewPage> {
  final ClaysViewPageController _controller = ClaysViewPageController();

  @override
  void initState() {
    super.initState();
    _controller.load(widget.clay);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;

          Navigator.of(context).pop(_controller.hasChanged);
        },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Clay body"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_controller.hasChanged);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Delete ceramic"),
                    content: const Text(
                      "Are you sure you want to delete this ceramic?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                final success = await _controller.deleteClay();

                if (success && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
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
                  _controller.load(null);
                },
                child: _pageContent(_controller),
              );
            },
          ),
        ),
      )
    );
  }

  SingleChildScrollView _pageContent(ClaysViewPageController controller) {
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
                for (final image in controller.clay.images) ... [
                  SquareWidget(
                    width: 92,
                    height: 92,
                    imageUri: image.uri,
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black87,
                        builder: (_) => ImageViewPage(
                          image: image,
                          onDelete: () async {

                            final success = await controller.deleteImage(image);

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
            initialValue: controller.clay.title,
            debounceDuration: Duration(milliseconds: 300),

            onChanged: (value) async {
              if(value == "") return true;
              return controller.setTitle(value);
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
            initialValue: controller.clay.title,
            debounceDuration: Duration(milliseconds: 300),

            onChanged: (value) async {
              return controller.setSupplier(value);
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
            initialValue: controller.clay.note,
            debounceDuration: Duration(milliseconds: 300),
            minLines: 3,
            maxLines: 5,

            onChanged: (value) async {
              return controller.setNote(value);
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
