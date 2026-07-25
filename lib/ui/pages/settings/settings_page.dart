import 'package:ceramic_app/config/constants/app_constants.dart';
import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/ui/pages/profile/profile_edit_page.dart';
import 'package:ceramic_app/ui/pages/profile/profile_page_controller.dart';
import 'package:ceramic_app/ui/pages/settings/account_settings_pages.dart';
import 'package:ceramic_app/ui/pages/settings/privacy_settings_pages.dart';
import 'package:ceramic_app/ui/pages/settings/settings_controller.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.controller});
  final SettingsController? controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController _controller =
      widget.controller ?? SettingsController();
  bool _loggingOut = false;
  String? _logoutError;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _chooseAudience({
    required String title,
    required PrivacyAudience selected,
    required List<PrivacyAudience> options,
    required AccountSettingsDto Function(PrivacyAudience value) update,
  }) async {
    final value = await showModalBottomSheet<PrivacyAudience>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioGroup<PrivacyAudience>(
              groupValue: selected,
              onChanged: (value) => Navigator.pop(context, value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options
                    .map(
                      (option) => RadioListTile<PrivacyAudience>(
                        value: option,
                        title: Text(option.localizedLabel(context.l10n)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
    if (value != null) await _controller.save(update(value));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.logOutQuestion),
        content: Text(context.l10n.logOutExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.logOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _loggingOut = true;
      _logoutError = null;
    });
    try {
      await context.read<AuthenticationCubit>().logout();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loggingOut = false;
        _logoutError = context.l10n.logoutFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsAndPrivacy)),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.error != null &&
              _controller.settings == const AccountSettingsDto()) {
            return _LoadError(
              message: _settingsError(context, _controller.error!),
              onRetry: _controller.load,
            );
          }
          final settings = _controller.settings;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (_controller.error case final message?)
                MaterialBanner(
                  content: Text(_settingsError(context, message)),
                  actions: [
                    TextButton(
                      onPressed: _controller.load,
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              _Heading(context.l10n.settingsAccount),
              _SettingsRow(
                icon: Icons.edit_outlined,
                label: context.l10n.editProfile,
                onTap: () => _open(const _EditProfileDestination()),
              ),
              _SettingsRow(
                icon: Icons.person_outline,
                label: context.l10n.accountInformation,
                onTap: () => _open(const AccountInformationPage()),
              ),
              _SettingsRow(
                icon: Icons.lock_outline,
                label: context.l10n.passwordAndSecurity,
                onTap: () => _open(const PasswordSecurityPage()),
              ),
              _SettingsRow(
                icon: Icons.download_outlined,
                label: context.l10n.downloadYourData,
                onTap: () => _open(const DataExportPage()),
              ),
              _SettingsRow(
                icon: Icons.delete_outline,
                label: context.l10n.deleteAccount,
                destructive: true,
                onTap: () => _open(const DeleteAccountPage()),
              ),
              _Heading(context.l10n.settingsPrivacy),
              _SettingsRow(
                icon: Icons.travel_explore_outlined,
                label: context.l10n.discoverability,
                value: settings.discoverability.localizedLabel(context.l10n),
                onTap: () => _chooseAudience(
                  title: context.l10n.whoCanDiscover,
                  selected: settings.discoverability,
                  options: const [
                    PrivacyAudience.everyone,
                    PrivacyAudience.friends,
                    PrivacyAudience.noOne,
                  ],
                  update: (value) =>
                      _controller.settings.copyWith(discoverability: value),
                ),
              ),
              _SettingsRow(
                icon: Icons.person_add_alt_outlined,
                label: context.l10n.friendRequests,
                value: settings.friendRequests.localizedLabel(context.l10n),
                onTap: () => _chooseAudience(
                  title: context.l10n.whoCanSendFriendRequests,
                  selected: settings.friendRequests,
                  options: const [
                    PrivacyAudience.everyone,
                    PrivacyAudience.friendsOfFriends,
                    PrivacyAudience.noOne,
                  ],
                  update: (value) =>
                      _controller.settings.copyWith(friendRequests: value),
                ),
              ),
              _SettingsRow(
                icon: Icons.chat_bubble_outline,
                label: context.l10n.messages,
                value: settings.messages.localizedLabel(context.l10n),
                onTap: () => _chooseAudience(
                  title: context.l10n.whoCanSendMessageRequests,
                  selected: settings.messages,
                  options: const [
                    PrivacyAudience.everyone,
                    PrivacyAudience.friends,
                    PrivacyAudience.noOne,
                  ],
                  update: (value) =>
                      _controller.settings.copyWith(messages: value),
                ),
              ),
              _SettingsRow(
                icon: Icons.block_outlined,
                label: context.l10n.blockedAccounts,
                onTap: () => _open(const BlockedAccountsPage()),
              ),
              _Heading(context.l10n.contentAndDisplay),
              _SettingsRow(
                icon: Icons.notifications_outlined,
                label: context.l10n.notifications,
                onTap: () =>
                    _open(NotificationsSettingsPage(controller: _controller)),
              ),
              _SettingsRow(
                icon: Icons.dark_mode_outlined,
                label: context.l10n.appearance,
                value: settings.themeMode.localizedLabel(context.l10n),
                onTap: () async {
                  final value = await _selection<AccountThemeMode>(
                    context.l10n.appearance,
                    settings.themeMode,
                    AccountThemeMode.values,
                    (item) => item.localizedLabel(context.l10n),
                  );
                  if (value != null) {
                    await _controller.save(
                      _controller.settings.copyWith(themeMode: value),
                    );
                  }
                },
              ),
              _SettingsRow(
                icon: Icons.straighten_outlined,
                label: context.l10n.units,
                value: settings.measurementSystem.localizedLabel(context.l10n),
                onTap: () async {
                  final value = await _selection<MeasurementSystem>(
                    context.l10n.units,
                    settings.measurementSystem,
                    MeasurementSystem.values,
                    (item) =>
                        '${item.localizedLabel(context.l10n)} '
                        '(${item.lengthSymbol}, ${item.temperatureSymbol}, '
                        '${item.weightSymbol})',
                  );
                  if (value != null) {
                    await _controller.save(
                      _controller.settings.copyWith(measurementSystem: value),
                    );
                  }
                },
              ),
              _SettingsRow(
                icon: Icons.language_outlined,
                label: context.l10n.language,
                value: context.l10n.languageName,
                onTap: () =>
                    _open(LanguageSettingsPage(controller: _controller)),
              ),
              _Heading(context.l10n.supportAndAbout),
              _SettingsRow(
                icon: Icons.help_outline,
                label: context.l10n.websiteHelpCenter,
                external: true,
                onTap: () => _openLink('/support'),
              ),
              _SettingsRow(
                icon: Icons.privacy_tip_outlined,
                label: context.l10n.privacyInformation,
                external: true,
                onTap: () => _openLink('/privacy'),
              ),
              _SettingsRow(
                icon: Icons.info_outline,
                label: context.l10n.aboutKeramik,
                external: true,
                onTap: () => _openLink('/about'),
              ),
              _Heading(context.l10n.loginSection),
              _SettingsRow(
                icon: Icons.logout,
                label: _loggingOut
                    ? context.l10n.loggingOut
                    : context.l10n.logOut,
                destructive: true,
                enabled: !_loggingOut,
                showChevron: false,
                trailing: _loggingOut
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _logout,
              ),
              if (_logoutError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    _logoutError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<T?> _selection<T>(
    String title,
    T selected,
    List<T> values,
    String Function(T value) label,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(title)),
            RadioGroup<T>(
              groupValue: selected,
              onChanged: (choice) => Navigator.pop(context, choice),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: values
                    .map(
                      (value) => RadioListTile<T>(
                        value: value,
                        title: Text(label(value)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String path) async {
    try {
      await openWebPage('${AppConstants.api.apiDomain}$path');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.linkOpenFailed)),
      );
    }
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.destructive = false,
    this.external = false,
    this.enabled = true,
    this.showChevron = true,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool destructive;
  final bool external;
  final bool enabled;
  final bool showChevron;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final color = destructive ? error : null;
    return Column(
      children: [
        ListTile(
          enabled: enabled,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 3,
          ),
          leading: Icon(icon, size: 22, color: color),
          title: Text(label, style: TextStyle(color: color)),
          trailing:
              trailing ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    Text(
                      value!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (showChevron)
                    Icon(
                      external ? Icons.open_in_new : Icons.chevron_right,
                      size: external ? 18 : 23,
                    ),
                ],
              ),
          onTap: enabled ? onTap : null,
        ),
        Divider(
          height: 1,
          indent: 58,
          color: Theme.of(context).dividerColor.withValues(alpha: .55),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}

String _settingsError(BuildContext context, SettingsError error) {
  return switch (error) {
    SettingsError.loadFailed => context.l10n.settingsLoadFailed,
    SettingsError.saveFailed => context.l10n.settingSaveFailed,
  };
}

class _EditProfileDestination extends StatefulWidget {
  const _EditProfileDestination();

  @override
  State<_EditProfileDestination> createState() =>
      _EditProfileDestinationState();
}

class _EditProfileDestinationState extends State<_EditProfileDestination> {
  final ProfilePageController _controller = ProfilePageController();

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
  Widget build(BuildContext context) =>
      ProfileEditPage(controller: _controller);
}
