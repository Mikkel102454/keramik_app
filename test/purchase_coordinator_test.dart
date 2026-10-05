import 'package:clay_dock/app/purchase_coordinator.dart';
import 'package:clay_dock/l10n/app_localizations.dart';
import 'package:clay_dock/repositories/purchase_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/claydock/billing');
  final native = <MethodCall>[];
  final requests = <RequestOptions>[];
  late Dio dio;
  String mode = 'PLAY';
  String? provider;
  bool eligibility = true;
  bool failFreshPolicy = false;
  dynamic purchase = [
    {'purchaseToken': 'verified-token', 'purchased': true},
  ];
  int policyLoads = 0;
  setUp(() {
    mode = 'PLAY';
    provider = null;
    eligibility = true;
    failFreshPolicy = false;
    purchase = [
      {'purchaseToken': 'verified-token', 'purchased': true},
    ];
    policyLoads = 0;
    native.clear();
    requests.clear();
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          dynamic data;
          if (request.path == '/api/billing/purchase-options') {
            policyLoads++;
            if (failFreshPolicy && policyLoads > 1) {
              handler.reject(
                DioException(
                  requestOptions: request,
                  type: DioExceptionType.connectionError,
                ),
              );
              return;
            }
            data = {
              'schemaVersion': 1,
              'revision': policyLoads,
              'validUntil': DateTime.now()
                  .toUtc()
                  .add(const Duration(seconds: 25))
                  .toIso8601String(),
              'accountId': 'account-hash-from-server',
              'membershipProvider': provider,
              'overlappingSubscriptions': false,
              'routes': provider == null
                  ? [
                      {
                        'mode': mode,
                        'products': [
                          {'id': 'maker', 'basePlanId': 'monthly'},
                        ],
                        'destination': mode == 'PLAY'
                            ? null
                            : 'https://claydock.invalid/membership/play-offer',
                      },
                    ]
                  : [],
            };
          } else if (request.path == '/api/billing/start') {
            data = {'operationId': 'operation'};
          } else if (request.path == '/api/billing/external/prepare') {
            data =
                'https://claydock.invalid/membership/play-offer?ticket=operation';
          }
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {'success': true, 'data': data},
            ),
          );
        },
      ),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          native.add(call);
          switch (call.method) {
            case 'restore':
              return [];
            case 'country':
              return 'US';
            case 'offers':
              if (!eligibility) {
                throw PlatformException(code: 'BILLING_UNAVAILABLE');
              }
              return mode == 'EXTERNAL_CONTENT_LINK' ||
                      mode == 'EXTERNAL_OFFERS'
                  ? []
                  : [
                      {
                        'productId': 'maker',
                        'basePlanId': 'monthly',
                        'offerToken': 'eligible-localized-offer',
                        'name': 'Maker offer',
                        'phases': [
                          {
                            'price': '\$4.99',
                            'currency': 'USD',
                            'period': 'P1M',
                            'cycles': 0,
                          },
                        ],
                      },
                    ];
            case 'purchase':
              return purchase;
            case 'reportingToken':
              return 'fresh-native-reporting-token';
            case 'externalLink':
              return true;
            case 'manage':
              return null;
            default:
              throw PlatformException(code: 'UNSUPPORTED');
          }
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    dio.close();
  });
  Future<void> open(WidgetTester tester) async {
    final coordinator = PurchaseCoordinator(
      repository: PurchaseRepository(dio: dio),
      channel: channel,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => coordinator.open(context),
              child: const Text('upgrade'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('upgrade'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'fresh policy and Google-localized offer bind account and verify server-side',
    (tester) async {
      await open(tester);
      expect(find.textContaining('\$4.99'), findsOneWidget);
      await tester.tap(find.textContaining('Maker offer'));
      await tester.pumpAndSettle();
      expect(policyLoads, 2);
      expect(
        requests
            .where((r) => r.path == '/api/billing/start')
            .single
            .data['revision'],
        2,
      );
      final launch = native.where((c) => c.method == 'purchase').single;
      expect(launch.arguments['accountId'], 'account-hash-from-server');
      expect(launch.arguments['offerToken'], 'eligible-localized-offer');
      expect(
        requests
            .where((r) => r.path == '/api/billing/play/verify')
            .single
            .data['purchaseToken'],
        'verified-token',
      );
      expect(requests.first.queryParameters['country'], 'US');
      expect(native.where((c) => c.method == 'externalLink'), isEmpty);
    },
  );
  testWidgets(
    'failed fresh policy cannot begin checkout or open external destination',
    (tester) async {
      failFreshPolicy = true;
      await open(tester);
      await tester.tap(find.textContaining('Maker offer'));
      await tester.pumpAndSettle();
      expect(requests.where((r) => r.path == '/api/billing/start'), isEmpty);
      expect(
        native.where(
          (c) => c.method == 'purchase' || c.method == 'externalLink',
        ),
        isEmpty,
      );
      expect(
        find.textContaining('Purchasing could not be verified'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'unenrolled native program is withheld even with an enabled server route',
    (tester) async {
      mode = 'EXTERNAL_CONTENT_LINK';
      eligibility = false;
      await open(tester);
      expect(find.byType(SimpleDialog), findsNothing);
      expect(requests.where((r) => r.path == '/api/billing/start'), isEmpty);
      expect(native.where((c) => c.method == 'externalLink'), isEmpty);
      expect(
        find.textContaining('Purchasing could not be verified'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'permitted website destination requires native reporting token and Play link API',
    (tester) async {
      mode = 'EXTERNAL_CONTENT_LINK';
      await open(tester);
      await tester.tap(
        find.text('Continue to the website through Google Play'),
      );
      await tester.pumpAndSettle();
      final reporting = requests
          .where((r) => r.path == '/api/billing/external/prepare')
          .single;
      expect(reporting.data['reportingToken'], 'fresh-native-reporting-token');
      expect(reporting.data['operationId'], 'operation');
      expect(
        native
            .where((c) => c.method == 'externalLink')
            .single
            .arguments['destination'],
        'https://claydock.invalid/membership/play-offer?ticket=operation',
      );
      expect(native.where((c) => c.method == 'purchase'), isEmpty);
    },
  );
  testWidgets(
    'Google-rendered billing choice receives both eligible product and reported approved destination',
    (tester) async {
      mode = 'BILLING_CHOICE';
      purchase = {'external': true};
      await open(tester);
      expect(
        find.textContaining('Choose Google Play or website billing'),
        findsOneWidget,
      );
      await tester.tap(find.textContaining('Maker offer'));
      await tester.pumpAndSettle();
      expect(
        native
            .where((c) => c.method == 'purchase')
            .single
            .arguments['destination'],
        'https://claydock.invalid/membership/play-offer?ticket=operation',
      );
      expect(
        requests.where((r) => r.path == '/api/billing/play/verify'),
        isEmpty,
      );
    },
  );
  testWidgets(
    'pending purchase retains coordination and never grants inferred access',
    (tester) async {
      purchase = [
        {'purchaseToken': 'pending', 'purchased': false, 'pending': true},
      ];
      await open(tester);
      await tester.tap(find.textContaining('Maker offer'));
      await tester.pumpAndSettle();
      expect(requests.where((r) => r.path == '/api/billing/release'), isEmpty);
      expect(
        requests
            .where((r) => r.path == '/api/billing/play/verify')
            .single
            .data['purchaseToken'],
        'pending',
      );
    },
  );
  testWidgets(
    'explicit Google cancellation releases the same durable operation',
    (tester) async {
      purchase = {'canceled': true};
      await open(tester);
      await tester.tap(find.textContaining('Maker offer'));
      await tester.pumpAndSettle();
      expect(
        requests
            .where((r) => r.path == '/api/billing/release')
            .single
            .data['operationId'],
        'operation',
      );
    },
  );
  testWidgets(
    'existing Stripe and Play memberships use their original management paths without new checkout',
    (tester) async {
      provider = 'STRIPE';
      await open(tester);
      expect(find.textContaining('managed by Stripe'), findsOneWidget);
      expect(
        native.where(
          (c) =>
              c.method == 'purchase' ||
              c.method == 'externalLink' ||
              c.method == 'manage',
        ),
        isEmpty,
      );
      provider = 'PLAY';
      await tester.pumpWidget(const SizedBox.shrink());
      await open(tester);
      expect(native.where((c) => c.method == 'manage'), hasLength(1));
      expect(requests.where((r) => r.path == '/api/billing/start'), isEmpty);
    },
  );
}
