import 'package:ceramic_app/ui/widgets/v2/studio_widgets.dart';
import 'dart:io';

import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/ui/pages/image_view/image_view_page.dart';
import 'package:ceramic_app/ui/pages/materials/clays/clays_view/clays_view_page_controller.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:image_picker/image_picker.dart';

class ClaysViewPage extends StatefulWidget {
  final ClayDto clay;

  const ClaysViewPage({super.key, required this.clay});

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
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        Navigator.of(context).pop(_controller.hasChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.clayBody),
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_controller.hasChanged);
            },
          ),
          actions: [
            IconButton(
              tooltip: context.l10n.delete,
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.error,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(context.l10n.deleteClay),
                    content: Text(context.l10n.deleteClayQuestion),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(context.l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(context.l10n.delete),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                final success = await _controller.deleteClay();

                if (success && context.mounted) {
                  Navigator.of(context).pop(true);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.deleteClayFailed)),
                  );
                }
              },
            ),
          ],
        ),
        body: StudioContent(
          maxWidth: StudioSpacing.formWidth,
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.error != null) {
                  return StudioEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: context.l10n.operationFailed,
                    action: FilledButton.icon(
                      onPressed: () => _controller.load(null),
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.retry),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _controller.load(null),
                  child: _pageContent(_controller),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  SingleChildScrollView _pageContent(ClaysViewPageController controller) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          StudioPageHeader(
            title: controller.clay.title,
            icon: Icons.landscape_outlined,
          ),
          // =========================
          // Images
          // =========================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,

            physics: const BouncingScrollPhysics(),

            child: Row(
              children: [
                for (final image in controller.clay.images) ...[
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
                            final navigator = Navigator.of(context);

                            final success = await controller.deleteImage(image);

                            if (success) {
                              navigator.pop();
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
                  iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  iconSize: 42,
                  width: 92,
                  height: 92,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  onPressed: () async {
                    final source = await showModalBottomSheet<ImageSource>(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: Text(context.l10n.selectFromGallery),
                                onTap: () {
                                  Navigator.pop(context, ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: Text(context.l10n.takePicture),
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
          const SizedBox(height: 16),

          // =========================
          // Information
          // =========================
          StudioSectionHeading(title: context.l10n.information),
          const SizedBox(height: 8),
          TextFieldWidget(
            label: context.l10n.title,
            placeholder: context.l10n.title,
            initialValue: controller.clay.title,
            debounceDuration: Duration(milliseconds: 300),

            onChanged: (value) async {
              if (value == "") return true;
              return controller.setTitle(value);
            },
          ),

          const SizedBox(height: 12),

          TextFieldWidget(
            label: context.l10n.supplier,
            placeholder: context.l10n.supplier,
            initialValue: controller.clay.supplier,
            debounceDuration: Duration(milliseconds: 300),

            onChanged: (value) async {
              return controller.setSupplier(value);
            },
          ),

          const SizedBox(height: 16),

          // =========================
          // Notes
          // =========================
          StudioSectionHeading(title: context.l10n.notes),
          const SizedBox(height: 8),

          TextFieldWidget(
            semanticsLabel: context.l10n.notes,
            placeholder: context.l10n.clayNotes,
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
