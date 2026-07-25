import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/ui/pages/profile/profile_feature_page.dart';
import 'package:ceramic_app/ui/pages/profile/profile_page_controller.dart';
import 'package:ceramic_app/ui/pages/notification/notification_controller_page.dart';
import 'package:ceramic_app/ui/pages/notification/notification_page.dart';
import 'package:ceramic_app/ui/pages/settings/account_settings_pages.dart';
import 'package:ceramic_app/ui/pages/settings/privacy_settings_pages.dart';
import 'package:ceramic_app/ui/pages/settings/settings_controller.dart';
import 'package:ceramic_app/ui/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_app.dart';

void main() {
  testWidgets('profile exposes menu instead of account search', (tester) async {
    final controller = _ProfileController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      localizedTestApp(home: ProfileFeaturePage(controller: controller)),
    );
    await tester.pump();

    expect(find.byTooltip('Settings and privacy'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byTooltip('Search accounts'), findsNothing);
  });

  testWidgets('account search remains available from Chats', (tester) async {
    final controller = _NotificationController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      localizedTestApp(home: NotificationPage(controller: controller)),
    );
    await tester.pump();

    expect(find.text('Chats'), findsOneWidget);
    expect(find.byTooltip('Search accounts'), findsOneWidget);
  });

  testWidgets('settings sections are rendered in the required order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SettingsController(
      loader: () async => const AccountSettingsDto(),
      saver: (settings) async => settings,
      appSettings: _testAppSettings(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      localizedTestApp(home: SettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    final account = tester.getTopLeft(find.text('Account')).dy;
    final privacy = tester.getTopLeft(find.text('Privacy')).dy;
    final content = tester.getTopLeft(find.text('Content and display')).dy;
    final support = tester.getTopLeft(find.text('Support and about')).dy;
    final login = tester.getTopLeft(find.text('Login')).dy;
    expect(account, lessThan(privacy));
    expect(privacy, lessThan(content));
    expect(content, lessThan(support));
    expect(support, lessThan(login));
    expect(find.text('Activity'), findsNothing);
  });

  testWidgets('privacy selector exposes the required audiences', (
    tester,
  ) async {
    final controller = SettingsController(
      loader: () async => const AccountSettingsDto(),
      saver: (settings) async => settings,
      appSettings: _testAppSettings(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      localizedTestApp(home: SettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discoverability'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(RadioListTile<PrivacyAudience>, 'Everyone'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(RadioListTile<PrivacyAudience>, 'Friends'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(RadioListTile<PrivacyAudience>, 'No one'),
      findsOneWidget,
    );
  });

  testWidgets('failed unblock restores the blocked account', (tester) async {
    const blocked = UserProfileDto(
      userId: 'blocked-id',
      username: 'blocked-member',
      avatarInitials: 'BM',
      avatarColor: '#6D597A',
      relationshipState: 'BLOCKED',
      actions: {'UNBLOCK'},
    );

    await tester.pumpWidget(
      localizedTestApp(
        home: BlockedAccountsPage(
          loader: ({cursor}) async =>
              const CursorPage<UserProfileDto>(items: [blocked]),
          unblocker: (_) async => throw Exception('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();

    expect(find.text('blocked-member'), findsOneWidget);
    expect(find.textContaining('could not be unblocked'), findsOneWidget);
  });

  testWidgets('push placeholder remains and generated languages are available', (
    tester,
  ) async {
    final controller = SettingsController(
      loader: () async => const AccountSettingsDto(),
      saver: (settings) async => settings,
      appSettings: _testAppSettings(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      localizedTestApp(
        home: NotificationsSettingsPage(controller: controller),
      ),
    );
    expect(find.text('Push notifications'), findsOneWidget);
    expect(find.textContaining('Coming later'), findsOneWidget);

    await tester.pumpWidget(
      localizedTestApp(
        home: LanguageSettingsPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Dansk'), findsOneWidget);
    expect(find.text('German'), findsNothing);
    final danish = tester.widget<RadioListTile<String>>(
      find.widgetWithText(RadioListTile<String>, 'Dansk'),
    );
    expect(danish.enabled, isTrue);
  });

  testWidgets('logout asks for confirmation before ending the session', (
    tester,
  ) async {
    final controller = SettingsController(
      loader: () async => const AccountSettingsDto(),
      saver: (settings) async => settings,
      appSettings: _testAppSettings(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      localizedTestApp(home: SettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Log out'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}

class _ProfileController extends ProfilePageController {
  _ProfileController() {
    account = const AccountProfileDto(
      userId: 'member-id',
      username: 'member',
      avatarInitials: 'ME',
      avatarColor: '#6D597A',
      forename: 'Member',
      surname: 'Test',
    );
  }

  @override
  Future<void> load() async {}
}

class _NotificationController extends NotificationControllerPage {
  @override
  Future<void> load() async {}
}

AppSettingsController _testAppSettings() =>
    AppSettingsController(localeCache: _TestLocaleCache());

class _TestLocaleCache implements LocaleCache {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String languageTag) async {}
}
