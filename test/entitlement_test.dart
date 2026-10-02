import 'dart:async';
import 'package:ceramic_app/app/entitlement_controller.dart';
import 'package:ceramic_app/config/constants/app_constants.dart';
import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/objects/entitlement_dto.dart';
import 'package:ceramic_app/objects/project_template_dto.dart';
import 'package:ceramic_app/ui/pages/home/templates/project_templates_page.dart';
import 'package:ceramic_app/ui/widgets/feature_gate.dart';
import 'package:ceramic_app/ui/pages/settings/membership_page.dart';
import 'package:ceramic_app/ui/pages/notification/ceramic_sharing_pages.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';

EntitlementDto snapshot({
  String plan = 'Free',
  bool enforcement = true,
  int limit = 7,
}) => EntitlementDto(
  plan: plan,
  billingStatus: plan == 'Maker' ? 'active' : 'free',
  enforcementEnabled: enforcement,
  features: {
    Features.ceramicImages: FeatureAccess(
      available: true,
      readAccess: true,
      limit: limit,
    ),
    Features.projectTemplates: FeatureAccess(
      available: plan == 'Maker',
      readAccess: true,
    ),
    Features.privateCeramicSharing: FeatureAccess(
      available: plan == 'Maker',
      readAccess: true,
    ),
    Features.practiceAnalytics: FeatureAccess(
      available: plan == 'Maker',
      readAccess: plan == 'Maker',
    ),
  },
);

Widget app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'server quotas and unknown feature keys are tolerated without client rules',
    () {
      final value = EntitlementDto.fromJson({
        'plan': 'Free',
        'billingStatus': 'free',
        'enforcementEnabled': true,
        'features': {
          'ceramic_images': {'available': true, 'readAccess': true, 'limit': 7},
          'future_feature': {'available': true, 'readAccess': true},
        },
      });
      expect(value.allows(Features.ceramicImages, currentUsage: 6), isTrue);
      expect(value.allows(Features.ceramicImages, currentUsage: 7), isFalse);
      expect(value.allows(Features.projectTemplates), isFalse);
      expect(value.features['future_feature']!.available, isTrue);
      expect(
        snapshot(enforcement: false).allows(Features.projectTemplates),
        isTrue,
      );
      expect(snapshot(enforcement: false).allows('missing'), isFalse);
    },
  );

  test(
    'loading and failure retain last session result, foreground and manual refresh update it',
    () async {
      final first = Completer<EntitlementDto>();
      var calls = 0;
      final controller = EntitlementController(
        load: () {
          calls++;
          if (calls == 1) return first.future;
          if (calls == 2) throw StateError('offline');
          return Future.value(snapshot(plan: 'Maker'));
        },
      );
      controller.start();
      expect(controller.loading, isTrue);
      expect(controller.value, isNull);
      first.complete(snapshot());
      await controller.refresh();
      expect(controller.value!.plan, 'Free');
      await controller.refresh();
      expect(controller.failed, isTrue);
      expect(controller.value!.plan, 'Free');
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await controller.refresh();
      expect(controller.failed, isFalse);
      expect(controller.value!.plan, 'Maker');
      expect(calls, 3);
      controller.reset();
      expect(controller.value, isNull);
      controller.dispose();
    },
  );

  test(
    'account switches ignore old in-flight results and clear on logout',
    () async {
      final first = Completer<EntitlementDto>();
      var calls = 0;
      final controller = EntitlementController(
        load: () => ++calls == 1 ? first.future : Future.value(snapshot()),
      );
      controller.start();
      controller.start();
      await controller.refresh();
      first.complete(snapshot(plan: 'Maker'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.value!.plan, 'Free');
      controller.reset();
      expect(controller.active, isFalse);
      expect(controller.value, isNull);
      controller.dispose();
    },
  );

  test('subscription error envelope preserves feature and quota metadata', () {
    final response = Response(
      data: {
        'success': false,
        'error': {
          'code': 'PLAN_LIMIT_REACHED',
          'message': 'Allowance reached',
          'featureKey': 'ceramic_images',
          'requiredPlan': 'Maker',
          'limit': 7,
          'currentUsage': 7,
        },
      },
      statusCode: 409,
      requestOptions: RequestOptions(),
    );
    expect(
      () => checkSuccess(response),
      throwsA(
        isA<ApiException>()
            .having((error) => error.isSubscriptionError, 'subscription', true)
            .having((error) => error.featureKey, 'feature', 'ceramic_images')
            .having((error) => error.limit, 'limit', 7)
            .having((error) => error.currentUsage, 'usage', 7),
      ),
    );
  });

  testWidgets(
    'gates distinguish unknown membership from Free and show server quota',
    (tester) async {
      final pending = Completer<EntitlementDto>();
      final controller = EntitlementController(load: () => pending.future)
        ..start();
      await tester.pumpWidget(
        app(
          Column(
            children: [
              FeatureGate(
                feature: Features.practiceAnalytics,
                controller: controller,
                child: const Text('analytics data'),
              ),
              QuotaIndicator(
                feature: Features.ceramicImages,
                currentUsage: 7,
                controller: controller,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Loading membership…'), findsOneWidget);
      expect(find.text('analytics data'), findsNothing);
      pending.complete(snapshot());
      await tester.pumpAndSettle();
      expect(find.text('Ceramic images: 7 of 7'), findsOneWidget);
      expect(find.text('View Maker membership'), findsOneWidget);
      expect(find.text('analytics data'), findsNothing);
      controller.dispose();
    },
  );

  testWidgets(
    'membership refresh failure does not present a confirmed Free account',
    (tester) async {
      final controller = EntitlementController(
        load: () async => throw StateError('offline'),
      )..start();
      await controller.refresh();
      await tester.pumpWidget(app(MembershipPage(controller: controller)));
      await tester.pumpAndSettle();
      expect(find.text('Free'), findsNothing);
      expect(
        find.textContaining('Membership could not be refreshed'),
        findsWidgets,
      );
      controller.dispose();
    },
  );

  testWidgets(
    'upgrade uses configured website membership URL in external browser',
    (tester) async {
      final launcher = RecordingLauncher();
      final previous = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = previous);
      final controller = EntitlementController(load: () async => snapshot())
        ..start();
      await controller.refresh();
      await tester.pumpWidget(
        app(
          FeatureGate(
            feature: Features.practiceAnalytics,
            controller: controller,
            child: const Text('analytics data'),
          ),
        ),
      );
      await tester.tap(find.text('View Maker membership'));
      await tester.pumpAndSettle();
      expect(launcher.url, AppConstants.api.membershipUrl);
      expect(Uri.parse(launcher.url!).path, '/membership');
      expect(launcher.url!.endsWith('/membership'), isTrue);
      expect(Uri.parse(launcher.url!).userInfo, isEmpty);
      expect(launcher.options!.mode, PreferredLaunchMode.externalApplication);
      controller.dispose();
    },
  );

  testWidgets(
    'Free public sharing bypasses private card gate and retry remains possible',
    (tester) async {
      final state = EntitlementController.instance;
      state.active = true;
      state.value = snapshot();
      addTearDown(state.reset);
      bool? result;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await confirmCeramicShare(
                  context,
                  publicPublication: true,
                );
              },
              child: const Text('share public'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('share public'));
      await tester.pumpAndSettle();
      expect(find.text('View Maker membership'), findsNothing);
      expect(
        find.textContaining('curated public Discover details'),
        findsOneWidget,
      );
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await confirmCeramicShare(
                  context,
                  checkMembership: false,
                );
              },
              child: const Text('retry'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('retry'));
      await tester.pumpAndSettle();
      expect(find.text('View Maker membership'), findsNothing);
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    },
  );

  testWidgets('Danish locked analytics and membership labels are localized', (
    tester,
  ) async {
    final controller = EntitlementController(load: () async => snapshot())
      ..start();
    await controller.refresh();
    await tester.pumpWidget(
      app(
        FeatureGate(
          feature: Features.practiceAnalytics,
          controller: controller,
          child: const Text('analytics data'),
        ),
        locale: const Locale('da'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Se Maker-medlemskab'), findsOneWidget);
    expect(find.text('analytics data'), findsNothing);
    controller.dispose();
  });

  testWidgets('saved templates remain fully readable after downgrade', (
    tester,
  ) async {
    final state = EntitlementController.instance;
    state.active = true;
    state.value = snapshot();
    addTearDown(state.reset);
    final template = ProjectTemplateDto(
      id: 1,
      version: 0,
      name: 'Saved plan',
      titlePattern: 'Cup {n}',
      note: 'Saved private planning note',
      tags: ['series'],
      glazes: [
        TemplateGlazeDto(
          glazeId: 1,
          glazeTitle: 'Saved glaze',
          note: 'Saved glaze note',
          layerOrder: 1,
          coatCount: 4,
        ),
      ],
      firings: [
        TemplateFiringDto(
          type: 'SINGLE',
          firingOrder: 1,
          targetCone: '06',
          kiln: 'Saved kiln',
          program: 'Saved program',
          note: 'Saved firing note',
        ),
      ],
    );
    await tester.pumpWidget(app(ProjectTemplateReadPage(template: template)));
    expect(find.text('Saved plan'), findsOneWidget);
    expect(find.text('Saved private planning note'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Saved firing note'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Saved firing note'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
  });
}

class RecordingLauncher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;
  String? url;
  LaunchOptions? options;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    this.options = options;
    return true;
  }
}
