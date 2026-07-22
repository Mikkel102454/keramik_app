import 'package:ceramic_app/ui/pages/profile/profile_page_controller.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
              title: const Text('View photo'),
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
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _choosePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload photo'),
              subtitle: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _choosePhoto(ImageSource.gallery);
              },
            ),
            if (account.avatarUrl != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text('Remove photo', style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: const Color(0xfff5f5f5),
        centerTitle: true,
        title: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w700)),
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
                child: const Text('Change photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              const Text(
                'Profile photos are public. Cached copies may remain after removal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 28),
              _ReadOnlyCard(
                children: [
                  _ReadOnlyField(label: 'Forename', value: _display(account.forename)),
                  _ReadOnlyField(label: 'Surname', value: _display(account.surname)),
                  _ReadOnlyField(label: 'Username', value: account.username),
                  _ReadOnlyField(label: 'Public user ID', value: account.userId, compact: true),
                ],
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text('These fields are read-only for now.', style: TextStyle(color: Colors.black45)),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _display(String value) => value.trim().isEmpty ? 'Not set' : value;
}

class _ReadOnlyCard extends StatelessWidget {
  const _ReadOnlyCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
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
          SizedBox(width: 96, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 16))),
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
          const Icon(Icons.lock_outline, size: 17, color: Colors.black38),
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
        title: const Text('Profile photo'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text('Unable to load photo', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
