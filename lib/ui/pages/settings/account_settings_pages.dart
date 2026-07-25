import 'dart:async';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/config/constants/app_constants.dart';
import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/account_lifecycle_dto.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/account_repository.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/ui/pages/settings/settings_controller.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountInformationPage extends StatelessWidget {
  const AccountInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.accountInformation)),
      body: FutureBuilder<AccountProfileDto>(
        future: SocialRepository.getMe(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.accountInformationLoadFailed,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final account = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Info(label: context.l10n.username, value: account.username),
              _Info(
                label: context.l10n.name,
                value: '${account.forename} ${account.surname}'.trim(),
              ),
              _Info(label: context.l10n.publicUserId, value: account.userId),
              const SizedBox(height: 16),
              Text(
                context.l10n.accountEmailPrivacyNote,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value.isEmpty ? context.l10n.notSet : value),
    );
  }
}

class PasswordSecurityPage extends StatefulWidget {
  const PasswordSecurityPage({super.key});

  @override
  State<PasswordSecurityPage> createState() => _PasswordSecurityPageState();
}

class _PasswordSecurityPageState extends State<PasswordSecurityPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _message = null;
      _success = false;
    });
    try {
      await AccountRepository.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
        confirmation: _confirmation.text,
      );
      _current.clear();
      _next.clear();
      _confirmation.clear();
      if (mounted) {
        setState(() {
          _success = true;
          _message = context.l10n.passwordChanged;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = context.l10n.passwordChangeFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.passwordAndSecurity)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _current,
            obscureText: true,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: context.l10n.currentPassword,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _next,
            obscureText: true,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: context.l10n.newPassword,
              helperText: context.l10n.passwordLengthHelp,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmation,
            obscureText: true,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: context.l10n.confirmNewPassword,
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 14),
            Text(
              _message!,
              style: TextStyle(
                color: _success
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.changePassword),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => openWebPage(
              '${AppConstants.api.apiDomain}/account/password',
            ),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(context.l10n.websitePasswordPage),
          ),
        ],
      ),
    );
  }
}

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  DataExportDto? _export;
  bool _busy = false;
  String? _error;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _create() async {
    final exportRequestFailed = context.l10n.exportRequestFailed;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _export = await AccountRepository.createExport();
      _startPolling();
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = exportRequestFailed;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  Future<void> _refresh() async {
    final current = _export;
    if (current == null || !mounted) return;
    try {
      final updated = await AccountRepository.getExport(current.exportId);
      if (!mounted) return;
      setState(() {
        _export = updated;
        _error = updated.errorMessage;
      });
      if (updated.status == 'READY' ||
          updated.status == 'FAILED' ||
          updated.status == 'EXPIRED') {
        _poll?.cancel();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.exportRefreshFailed);
      }
    }
  }

  Future<void> _download() async {
    final current = _export;
    if (current == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await AccountRepository.downloadExport(current.exportId);
      await openWebPage(file.uri.toString());
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.exportDownloadFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final export = _export;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.downloadYourData)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(context.l10n.dataExportDescription),
          const SizedBox(height: 12),
          Text(
            context.l10n.dataExportLimit,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (export != null) ...[
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: Icon(
                  export.downloadAvailable
                      ? Icons.check_circle_outline
                      : Icons.hourglass_top,
                ),
                title: Text(_exportStatus(context, export.status)),
                subtitle: export.expiresAt == null
                    ? null
                    : Text(
                        context.l10n.availableUntil(
                          export.expiresAt!.toLocal().toString(),
                        ),
                      ),
                trailing: export.status == 'PENDING' ||
                        export.status == 'PROCESSING'
                    ? IconButton(
                        tooltip: context.l10n.refreshStatus,
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                      )
                    : null,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : export?.downloadAvailable == true
                ? _download
                : export == null || export.status == 'FAILED'
                ? _create
                : _refresh,
            icon: Icon(
              export?.downloadAvailable == true
                  ? Icons.download
                  : Icons.archive_outlined,
            ),
            label: Text(
              _busy
                  ? context.l10n.pleaseWait
                  : export?.downloadAvailable == true
                  ? context.l10n.downloadZip
                  : export == null || export.status == 'FAILED'
                  ? context.l10n.createExport
                  : context.l10n.refreshStatus,
            ),
          ),
        ],
      ),
    );
  }

  static String _exportStatus(BuildContext context, String status) =>
      switch (status) {
    'PENDING' => context.l10n.exportQueued,
    'PROCESSING' => context.l10n.exportCreating,
    'READY' => context.l10n.exportReady,
    'EXPIRED' => context.l10n.exportExpired,
    _ => context.l10n.exportFailed,
  };
}

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _understood = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _schedule() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AccountRepository.scheduleDeletion(
        currentPassword: _password.text,
        confirmation: _confirmation.text,
      );
      await ApiClient.cookieJar.deleteAll();
      if (!mounted) return;
      context.read<AuthenticationCubit>().sessionExpired();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.deletionScheduleFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.deleteAccount)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.warning_amber_rounded, size: 44, color: error),
          const SizedBox(height: 14),
          Text(
            context.l10n.deletionCancellationPeriod,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.deletionSignOutExplanation),
          const SizedBox(height: 12),
          Text(context.l10n.deletionRetentionExplanation),
          const SizedBox(height: 18),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _understood,
            onChanged: _busy
                ? null
                : (value) => setState(() => _understood = value ?? false),
            title: Text(context.l10n.deletionUnderstand),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: context.l10n.currentPassword,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmation,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: context.l10n.typeDeleteToConfirm,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: error),
            onPressed:
                !_understood ||
                    _busy ||
                    _confirmation.text != 'DELETE' ||
                    _password.text.isEmpty
                ? null
                : _schedule,
            child: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.scheduleAccountDeletion),
          ),
        ],
      ),
    );
  }
}

class NotificationsSettingsPage extends StatelessWidget {
  const NotificationsSettingsPage({required this.controller, super.key});
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notifications)),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final settings = controller.settings;
          return ListView(
            children: [
              SwitchListTile(
                title: Text(context.l10n.directMessages),
                value: settings.notifyDirectMessages,
                onChanged: (value) => controller.save(
                  controller.settings.copyWith(notifyDirectMessages: value),
                ),
              ),
              SwitchListTile(
                title: Text(context.l10n.messageRequests),
                value: settings.notifyMessageRequests,
                onChanged: (value) => controller.save(
                  controller.settings.copyWith(notifyMessageRequests: value),
                ),
              ),
              SwitchListTile(
                title: Text(context.l10n.friendRequests),
                value: settings.notifyFriendRequests,
                onChanged: (value) => controller.save(
                  controller.settings.copyWith(notifyFriendRequests: value),
                ),
              ),
              SwitchListTile(
                title: Text(context.l10n.groupActivity),
                value: settings.notifyGroupActivity,
                onChanged: (value) => controller.save(
                  controller.settings.copyWith(notifyGroupActivity: value),
                ),
              ),
              const Divider(),
              ListTile(
                enabled: false,
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(context.l10n.pushNotifications),
                subtitle: Text(context.l10n.pushNotificationsComingLater),
                trailing: const Switch(value: false, onChanged: null),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key, this.controller});

  final SettingsController? controller;

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  late final SettingsController _controller =
      widget.controller ?? SettingsController();
  late final Future<List<_LanguageOption>> _languages = _loadLanguages();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<List<_LanguageOption>> _loadLanguages() async {
    final options = <_LanguageOption>[];
    for (final locale in AppLocalizations.supportedLocales) {
      final localizations = await AppLocalizations.delegate.load(locale);
      options.add(
        _LanguageOption(
          languageTag: locale.toLanguageTag(),
          nativeName: localizations.languageName,
        ),
      );
    }
    return options;
  }

  Future<void> _select(String? languageTag) async {
    if (languageTag == null ||
        languageTag == _controller.activeLanguageTag ||
        _controller.isSaving) {
      return;
    }
    await _controller.save(
      _controller.settings.copyWith(languageTag: languageTag),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.language)),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => FutureBuilder<List<_LanguageOption>>(
          future: _languages,
          builder: (context, snapshot) {
            final languages = snapshot.data;
            if (languages == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                if (_controller.error == SettingsError.saveFailed)
                  MaterialBanner(
                    content: Text(context.l10n.languageSaveFailed),
                    actions: [
                      TextButton(
                        onPressed: _controller.clearError,
                        child: Text(context.l10n.ok),
                      ),
                    ],
                  ),
                RadioGroup<String>(
                  groupValue: _controller.activeLanguageTag,
                  onChanged: _select,
                  child: Column(
                    children: languages
                        .map(
                          (language) => RadioListTile<String>(
                            value: language.languageTag,
                            enabled: !_controller.isSaving,
                            title: Text(language.nativeName),
                            subtitle:
                                language.languageTag ==
                                    _controller.activeLanguageTag
                                ? Text(context.l10n.currentLanguage)
                                : null,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.languageTag,
    required this.nativeName,
  });

  final String languageTag;
  final String nativeName;
}
