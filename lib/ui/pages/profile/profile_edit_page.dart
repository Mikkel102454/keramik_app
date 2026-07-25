import 'package:ceramic_app/ui/pages/profile/profile_page_controller.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({required this.controller, super.key});

  final ProfilePageController controller;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _showPhotoActions() async {
    final account = widget.controller.account;
    if (account == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text(context.l10n.viewPhoto),
              enabled: account.avatarUrl != null,
              onTap: account.avatarUrl == null
                  ? null
                  : () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _PhotoViewer(imageUrl: account.avatarUrl!),
                        ),
                      );
                    },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(context.l10n.takePhoto),
              onTap: () {
                Navigator.pop(sheetContext);
                _choosePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.uploadPhoto),
              subtitle: Text(context.l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(sheetContext);
                _choosePhoto(ImageSource.gallery);
              },
            ),
            if (account.avatarUrl != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text(
                  context.l10n.removePhoto,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _choosePhoto(ImageSource source) async {
    try {
      final selected = await _picker.pickImage(source: source);
      if (selected != null) await widget.controller.uploadPhoto(selected);
    } catch (exception) {
      if (mounted) _showError(exception);
    }
  }

  Future<void> _removePhoto() async {
    try {
      await widget.controller.removePhoto();
    } catch (exception) {
      if (mounted) _showError(exception);
    }
  }

  void _showError(Object exception) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          context.l10n.editProfile,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final account = widget.controller.account;
          if (account == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
            children: [
              Center(
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.controller.isUpdatingPhoto ? null : _showPhotoActions,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ProfileAvatar(
                        initials: account.avatarInitials,
                        colorHex: account.avatarColor,
                        imageUrl: account.avatarUrl,
                        radius: 68,
                      ),
                      if (widget.controller.isUpdatingPhoto)
                        const SizedBox.square(
                          dimension: 42,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.controller.isUpdatingPhoto ? null : _showPhotoActions,
                child: Text(
                  context.l10n.changePhoto,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                context.l10n.profilePhotoPrivacy,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              _ReadOnlyCard(
                children: [
                  _ReadOnlyField(
                    label: context.l10n.forename,
                    value: _display(context, account.forename),
                  ),
                  _ReadOnlyField(
                    label: context.l10n.surname,
                    value: _display(context, account.surname),
                  ),
                  _ReadOnlyField(
                    label: context.l10n.username,
                    value: account.username,
                  ),
                  _ReadOnlyField(
                    label: context.l10n.publicUserId,
                    value: account.userId,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  context.l10n.readOnlyFields,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _display(BuildContext context, String value) =>
      value.trim().isEmpty ? context.l10n.notSet : value;
}

class _ReadOnlyCard extends StatelessWidget {
  const _ReadOnlyCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value, this.compact = false});
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: compact ? 13 : 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.lock_outline,
            size: 17,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(context.l10n.profilePhoto),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Text(
              context.l10n.photoLoadFailed,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
