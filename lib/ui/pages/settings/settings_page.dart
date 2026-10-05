import 'package:clay_dock/repositories/ceramic_repository.dart';
import 'package:clay_dock/ui/pages/settings/mfa_settings_page.dart';
import 'package:clay_dock/config/constants/app_constants.dart';
import 'package:clay_dock/cubits/authentication/authentication_cubit.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:clay_dock/objects/account_settings_dto.dart';
import 'package:clay_dock/ui/pages/profile/profile_edit_page.dart';
import 'package:clay_dock/ui/pages/profile/profile_page_controller.dart';
import 'package:clay_dock/ui/pages/settings/account_settings_pages.dart';
import 'package:clay_dock/ui/pages/settings/privacy_settings_pages.dart';
import 'package:clay_dock/ui/pages/settings/settings_controller.dart';
import 'package:clay_dock/utils/web.dart';
import 'package:flutter/material.dart';
import 'package:clay_dock/ui/widgets/v2/studio_widgets.dart';
import 'package:clay_dock/ui/pages/settings/membership_page.dart';
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
        child: SingleChildScrollView(
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
      ),
    );
    if (value != null) await _controller.save(update(value));
  }

  Future<void> _clearViews() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearRecentlyViewed),
        content: Text(context.l10n.clearRecentlyViewedQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.clearRecentlyViewed),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CeramicRepository.clearViews();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.viewSyncFailed)));
      }
    }
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
      body: SafeArea(
        top: false,
        child: StudioContent(
          maxWidth: 800,
          child: AnimatedBuilder(
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
                  _SettingsRow(
                    icon: Icons.workspace_premium_outlined,
                    label: context.l10n.membership,
                    onTap: () => _open(const MembershipPage()),
                  ),
                  _Heading(context.l10n.settingsPrivacy),
                  _SettingsRow(
                    icon: Icons.travel_explore_outlined,
                    label: context.l10n.discoverability,
                    value: settings.discoverability.localizedLabel(
                      context.l10n,
                    ),
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
                  _SettingsRow(
                    icon: Icons.history,
                    label: context.l10n.clearRecentlyViewed,
                    onTap: _clearViews,
                  ),
                  _Heading(context.l10n.contentAndDisplay),
                  _SettingsRow(
                    icon: Icons.notifications_outlined,
                    label: context.l10n.notifications,
                    onTap: () => _open(
                      NotificationsSettingsPage(controller: _controller),
                    ),
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
                    value: settings.measurementSystem.localizedLabel(
                      context.l10n,
                    ),
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
                          _controller.settings.copyWith(
                            measurementSystem: value,
                          ),
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
                  _SettingsRow(
                    icon: Icons.currency_exchange,
                    label: context.l10n.preferredCurrency,
                    value: settings.preferredCurrency == 'AUTO'
                        ? context.l10n.automaticCurrency(
                            detectedCurrency(
                              WidgetsBinding.instance.platformDispatcher.locale,
                            ),
                          )
                        : settings.preferredCurrency,
                    onTap: () async {
                      final value = await _currencySelection(settings);
                      if (value != null) {
                        await _controller.save(
                          _controller.settings.copyWith(
                            preferredCurrency: value,
                          ),
                        );
                      }
                    },
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
                    label: context.l10n.aboutClayDock,
                    external: true,
                    onTap: () => _openLink('/about'),
                  ),
                  _Heading(context.l10n.loginSection),
                  _SettingsRow(
                    icon: Icons.security_outlined,
                    label: Localizations.localeOf(context).languageCode == 'da'
                        ? 'Totrinsbekræftelse'
                        : 'Two-factor authentication',
                    onTap: () => _open(const MfaSettingsPage()),
                  ),
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
        ),
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
        child: SingleChildScrollView(
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
      ),
    );
  }

  Future<String?> _currencySelection(AccountSettingsDto settings) {
    final automatic = detectedCurrency(
      WidgetsBinding.instance.platformDispatcher.locale,
    );
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: ListView(
            children: [
              ListTile(
                title: Text(
                  context.l10n.preferredCurrency,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(context.l10n.currencySettingHelp),
              ),
              RadioGroup<String>(
                groupValue: settings.preferredCurrency,
                onChanged: (value) => Navigator.pop(context, value),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'AUTO',
                      title: Text(context.l10n.automaticCurrency(automatic)),
                    ),
                    for (final currency in supportedExchangeCurrencies)
                      RadioListTile<String>(
                        value: currency,
                        title: Text(currency),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(String path) async {
    try {
      await openWebPage('${AppConstants.api.apiDomain}$path');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.linkOpenFailed)));
    }
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
      child: StudioSectionHeading(title: label),
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
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          enabled: enabled,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 4,
          ),
          leading: Icon(
            icon,
            size: 23,
            color: destructive ? colors.error : colors.onSurface,
          ),
          title: Text(
            label,
            style: TextStyle(color: destructive ? colors.error : null),
          ),
          subtitle: value == null ? null : Text(value!),
          trailing:
              trailing ??
              (showChevron
                  ? Icon(
                      external ? Icons.open_in_new : Icons.chevron_right,
                      size: external ? 18 : 22,
                      color: colors.onSurfaceVariant,
                    )
                  : null),
          onTap: enabled ? onTap : null,
        ),
        const Divider(height: 1, indent: 40),
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
    return StudioEmptyState(
      icon: Icons.cloud_off_outlined,
      title: message,
      action: FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
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
