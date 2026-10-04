import 'package:ceramic_app/ui/widgets/v2/studio_widgets.dart';
import 'package:ceramic_app/ui/pages/profile/profile_page_controller.dart';
import 'package:ceramic_app/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_edit_controller.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/entry_page_widgets.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({required this.controller, super.key});

  final ProfilePageController controller;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final ImagePicker _picker = ImagePicker();
  ProfileEditController? _draft;
  final _forename = TextEditingController();
  final _surname = TextEditingController();
  final _username = TextEditingController();
  bool _allowPop = false, _pickingPhoto = false, _confirmingDiscard = false;
  bool get _busy =>
      (_draft?.saving ?? false) ||
      widget.controller.isUpdatingPhoto ||
      _pickingPhoto;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_profileChanged);
    _initializeDraft();
  }

  void _initializeDraft() {
    final account = widget.controller.account;
    if (_draft != null || account == null) return;
    _draft = ProfileEditController(account)..addListener(_draftChanged);
    _forename.text = account.forename;
    _surname.text = account.surname;
    _username.text = account.username;
  }

  void _profileChanged() {
    _initializeDraft();
    if (mounted) setState(() {});
  }

  void _draftChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_profileChanged);
    _draft?.dispose();
    _forename.dispose();
    _surname.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_busy || _confirmingDiscard) return;
    _confirmingDiscard = true;
    final discard =
        !(_draft?.dirty ?? false) || await confirmEntryDiscard(context);
    _confirmingDiscard = false;
    if (!mounted || !discard || _busy) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final result = await _draft?.save();
    if (!mounted || result == null) return;
    widget.controller.profileSaved(result);
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _showPhotoActions() async {
    final account = widget.controller.account;
    if (account == null || _busy) return;
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
                          builder: (_) =>
                              _PhotoViewer(imageUrl: account.avatarUrl!),
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
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  context.l10n.removePhoto,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    if (_busy) return;
    setState(() => _pickingPhoto = true);
    try {
      final selected = await _picker.pickImage(source: source);
      if (selected != null) await widget.controller.uploadPhoto(selected);
    } catch (exception) {
      if (mounted) _showError(exception);
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    if (_busy) return;
    try {
      await widget.controller.removePhoto();
    } catch (exception) {
      if (mounted) _showError(exception);
    }
  }

  void _showError(Object exception) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.profilePhotoUpdateFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.controller.account;
    final draft = _draft;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.editProfile),
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _busy ? null : _leave,
            icon: const BackButtonIcon(),
          ),
          actions: [
            TextButton(
              onPressed: !_busy && (draft?.canSave ?? false) ? _save : null,
              child: Text(context.l10n.save),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: StudioContent(
            maxWidth: 820,
            child: account == null || draft == null
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: AbsorbPointer(
                      absorbing: _busy,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (draft.saving) const LinearProgressIndicator(),
                          if (draft.saveFailed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                draft.saveTimedOut
                                    ? context.l10n.requestTimedOut
                                    : context.l10n.profileSaveFailed,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          Center(
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _busy ? null : _showPhotoActions,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ProfileAvatar(
                                    initials: account.avatarInitials,
                                    colorHex: account.avatarColor,
                                    imageUrl: account.avatarUrl,
                                    radius: 48,
                                  ),
                                  if (widget.controller.isUpdatingPhoto ||
                                      _pickingPhoto)
                                    const SizedBox.square(
                                      dimension: 42,
                                      child: CircularProgressIndicator(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _showPhotoActions,
                            child: Text(context.l10n.changePhoto),
                          ),
                          Text(
                            context.l10n.profilePhotoPrivacy,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextFieldWidget(
                            key: const ValueKey('profile-forename'),
                            controller: _forename,
                            label: context.l10n.forename,
                            enabled: !_busy,
                            textInputAction: TextInputAction.next,
                            errorText:
                                ProfileEditController.validName(draft.forename)
                                ? null
                                : context.l10n.profileNameInvalid,
                            onChanged: (value) async {
                              draft.changeNames(forename: value);
                              return true;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFieldWidget(
                            controller: _surname,
                            label: context.l10n.surname,
                            enabled: !_busy,
                            textInputAction: TextInputAction.next,
                            errorText:
                                ProfileEditController.validName(draft.surname)
                                ? null
                                : context.l10n.profileNameInvalid,
                            onChanged: (value) async {
                              draft.changeNames(surname: value);
                              return true;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFieldWidget(
                            controller: _username,
                            label: context.l10n.username,
                            enabled: !_busy,
                            textInputAction: TextInputAction.done,
                            errorText:
                                !ProfileEditController.validUsername(
                                  draft.username,
                                )
                                ? context.l10n.profileUsernameInvalid
                                : draft.usernameCheck ==
                                      UsernameCheck.unavailable
                                ? context.l10n.usernameUnavailable
                                : null,
                            onChanged: (value) async {
                              draft.changeUsername(value);
                              return true;
                            },
                          ),
                          if (ProfileEditController.validUsername(
                            draft.username,
                          )) ...[
                            const SizedBox(height: 8),
                            if (draft.usernameCheck == UsernameCheck.waiting ||
                                draft.usernameCheck == UsernameCheck.checking)
                              Text(context.l10n.usernameChecking),
                            if (draft.usernameCheck ==
                                    UsernameCheck.available ||
                                draft.usernameCheck == UsernameCheck.unchanged)
                              Text(context.l10n.usernameAvailable),
                            if (draft.usernameCheck ==
                                UsernameCheck.failed) ...[
                              Text(context.l10n.usernameCheckFailed),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _busy ? null : draft.retryCheck,
                                  child: Text(context.l10n.retry),
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 16),
                          EntryValue(
                            key: const ValueKey('profile-user-id'),
                            label: context.l10n.publicUserId,
                            value: account.userId,
                          ),
                          const SizedBox(height: 16),
                          Text(context.l10n.profileEditPrivacy),
                          const SizedBox(height: 8),
                          Text(context.l10n.usernameSessionNotice),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
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
