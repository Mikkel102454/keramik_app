import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/ui/pages/profile/profile_edit_controller.dart';
import 'package:ceramic_app/ui/pages/profile/profile_edit_page.dart';
import 'package:ceramic_app/ui/pages/profile/profile_page_controller.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const account = AccountProfileDto(
  userId: 'stable-id',
  username: 'original',
  avatarInitials: 'OR',
  avatarColor: '#6D597A',
  forename: 'First',
  surname: 'Last',
);
AccountProfileDto updated(String first, String last, String username) =>
    AccountProfileDto(
      userId: account.userId,
      username: username,
      avatarInitials: username.substring(0, 2),
      avatarColor: account.avatarColor,
      forename: first,
      surname: last,
    );

void main() {
  test(
    'validation counts Unicode code points and trims without restricting characters',
    () {
      expect(ProfileEditController.validName('  '), isFalse);
      expect(ProfileEditController.validName(' 🏺 '), isTrue);
      expect(ProfileEditController.validName('🏺' * 100), isTrue);
      expect(ProfileEditController.validName('🏺' * 101), isFalse);
      expect(ProfileEditController.validUsername('🏺' * 3), isTrue);
      expect(ProfileEditController.validUsername('🏺' * 50), isTrue);
      expect(ProfileEditController.validUsername('🏺' * 51), isFalse);
      expect(ProfileEditController.validUsername(' a@b '), isTrue);
      expect(ProfileEditController.validUsername('ab'), isFalse);
    },
  );

  testWidgets(
    'debounces valid changes, ignores stale responses and cancels on disposal',
    (tester) async {
      final requests = <String>[];
      final pending = <Completer<bool>>[];
      final draft = ProfileEditController(
        account,
        checkUsername: (value) {
          requests.add(value);
          final result = Completer<bool>();
          pending.add(result);
          return result.future;
        },
      );
      draft.changeUsername('ab');
      await tester.pump(const Duration(seconds: 1));
      expect(requests, isEmpty);
      draft.changeUsername('new');
      await tester.pump(const Duration(milliseconds: 499));
      expect(requests, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(requests, ['new']);
      draft.changeUsername('newer');
      await tester.pump(const Duration(milliseconds: 500));
      pending.first.complete(false);
      await tester.pump();
      expect(draft.usernameCheck, UsernameCheck.checking);
      pending.last.complete(true);
      await tester.pump();
      expect(draft.canSave, isTrue);
      draft.changeUsername('original');
      expect(draft.usernameCheck, UsernameCheck.unchanged);
      draft.changeUsername('pending');
      draft.dispose();
      await tester.pump(const Duration(seconds: 1));
      expect(requests, ['new', 'newer']);
      final active = Completer<bool>();
      final disposed = ProfileEditController(
        account,
        checkUsername: (_) => active.future,
      );
      disposed.changeUsername('other');
      await tester.pump(const Duration(milliseconds: 500));
      disposed.dispose();
      active.complete(true);
      await tester.pump();
    },
  );

  testWidgets(
    'unavailable and failed checks can recover; conflict overrides a successful check',
    (tester) async {
      var attempt = 0;
      final draft = ProfileEditController(
        account,
        checkUsername: (_) async {
          attempt++;
          if (attempt == 1) return false;
          if (attempt == 2) throw Exception();
          return true;
        },
        saveProfile: (_, _, _) async =>
            throw const ApiException('conflict', code: 'USERNAME_UNAVAILABLE'),
      );
      draft.changeUsername('changed');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(draft.usernameCheck, UsernameCheck.unavailable);
      expect(draft.canSave, isFalse);
      draft.retryCheck();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(draft.usernameCheck, UsernameCheck.failed);
      draft.retryCheck();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(draft.canSave, isTrue);
      expect(await draft.save(), isNull);
      expect(draft.usernameCheck, UsernameCheck.unavailable);
      expect(draft.username, 'changed');
      draft.dispose();
    },
  );

  test(
    'failed saves retain all draft values and successful retry submits trimmed names',
    () async {
      var attempts = 0;
      final draft = ProfileEditController(
        account,
        saveProfile: (first, last, username) async {
          attempts++;
          if (attempts == 1) throw Exception();
          return updated(first, last, username);
        },
      );
      draft.changeNames(forename: ' New first ', surname: ' New last ');
      expect(await draft.save(), isNull);
      expect(draft.saveFailed, isTrue);
      expect(draft.forename, ' New first ');
      expect(draft.surname, ' New last ');
      final saved = await draft.save();
      expect(saved!.forename, 'New first');
      expect(saved.surname, 'New last');
      draft.dispose();
    },
  );

  testWidgets(
    'discard Cancel preserves edits; photo refresh preserves text; Save refreshes parent',
    (tester) async {
      final controller = ProfilePageController()..account = account;
      ApiClient.dio = Dio(
        BaseOptions(baseUrl: 'http://localhost', validateStatus: (_) => true),
      )..httpClientAdapter = ProfileAdapter();
      await tester.pumpWidget(
        app(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Open editor'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileEditPage(controller: controller),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Edited');
      await tester.pump();
      controller.profileSaved(updated('First', 'Last', 'original'));
      await tester.pump();
      expect(find.text('Edited'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edited'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Open editor'), findsOneWidget);
      expect(controller.account!.forename, 'Edited');
      controller.dispose();
    },
  );

  testWidgets(
    'saving blocks edits, photo actions and back; failure keeps values',
    (tester) async {
      final controller = ProfilePageController()..account = account;
      final pending = Completer<ResponseBody>();
      final adapter = ProfileAdapter(pending: pending);
      ApiClient.dio = Dio(
        BaseOptions(baseUrl: 'http://localhost', validateStatus: (_) => true),
      )..httpClientAdapter = adapter;
      await tester.pumpWidget(
        app(home: ProfileEditPage(controller: controller)),
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Changed surname',
      );
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Save'))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        isFalse,
      );
      await tester.pageBack();
      await tester.pump();
      expect(find.text('Discard unsaved changes?'), findsNothing);
      pending.complete(
        ResponseBody.fromString(
          jsonEncode({
            'success': false,
            'error': {'code': 'INTERNAL_ERROR', 'message': 'failed'},
          }),
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Changed surname'), findsOneWidget);
      expect(
        find.text(
          'Your profile could not be saved. Your changes are preserved. Please retry.',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  for (final locale in ['en', 'da']) {
    for (final dark in [false, true]) {
      testWidgets(
        'compact $locale ${dark ? "dark" : "light"} enlarged text and keyboard layout',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = ProfilePageController()..account = account;
          await tester.pumpWidget(
            app(
              locale: locale,
              dark: dark,
              enlarged: true,
              home: ProfileEditPage(controller: controller),
            ),
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('profile-forename')),
            100,
            scrollable: find
                .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(find.byType(TextFormField).first);
          await tester.pumpAndSettle();
          await tester.tap(find.byType(TextFormField).first);
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('profile-user-id')),
            100,
            scrollable: find
                .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey('profile-user-id')),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
        },
      );
    }
  }
}

Widget app({
  required Widget home,
  String locale = 'en',
  bool dark = false,
  bool enlarged = false,
}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(enlarged ? 1.6 : 1),
      viewInsets: enlarged
          ? const EdgeInsets.only(bottom: 240)
          : EdgeInsets.zero,
    ),
    child: child!,
  ),
  home: home,
);

class ProfileAdapter implements HttpClientAdapter {
  ProfileAdapter({this.pending});
  final Completer<ResponseBody>? pending;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (pending != null) return pending!.future;
    final data = options.data as Map<String, dynamic>;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'userId': account.userId,
          'username': data['username'],
          'forename': data['forename'],
          'surname': data['surname'],
          'avatarInitials': 'OR',
          'avatarColor': account.avatarColor,
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
