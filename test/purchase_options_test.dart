import 'package:flutter_test/flutter_test.dart';
import 'package:clay_dock/objects/purchase_options.dart';

void main() {
  Map<String, dynamic> policy() => {
    'schemaVersion': 1,
    'revision': 9,
    'validUntil': DateTime.now()
        .toUtc()
        .add(const Duration(seconds: 25))
        .toIso8601String(),
    'accountId': 'server-bound-account',
    'membershipProvider': null,
    'overlappingSubscriptions': false,
    'routes': [
      {
        'mode': 'PLAY',
        'products': [
          {'id': 'maker', 'basePlanId': 'monthly'},
        ],
        'destination': null,
      },
    ],
  };
  test('compatible fresh policy preserves provider mapping', () {
    final value = PurchaseOptions.fromJson(policy());
    expect(value.revision, 9);
    expect(value.routes.single.products.single.basePlanId, 'monthly');
  });
  test('unknown contract and expired or unbounded freshness fail closed', () {
    expect(
      () => PurchaseOptions.fromJson(policy()..['schemaVersion'] = 2),
      throwsFormatException,
    );
    expect(
      () => PurchaseOptions.fromJson(
        policy()
          ..['validUntil'] = DateTime.now()
              .toUtc()
              .subtract(const Duration(seconds: 1))
              .toIso8601String(),
      ),
      throwsFormatException,
    );
    expect(
      () => PurchaseOptions.fromJson(
        policy()
          ..['validUntil'] = DateTime.now()
              .toUtc()
              .add(const Duration(hours: 1))
              .toIso8601String(),
      ),
      throwsFormatException,
    );
  });
  test('unknown modes and insecure external routes never become raw links', () {
    final document = policy();
    document['routes'] = [
      {
        'mode': 'UNKNOWN',
        'products': [],
        'destination': 'https://billing.invalid',
      },
      {
        'mode': 'EXTERNAL_CONTENT_LINK',
        'products': [],
        'destination': 'http://billing.invalid',
      },
    ];
    expect(PurchaseOptions.fromJson(document).routes, isEmpty);
  });
  test(
    'existing provider membership survives emergency checkout disablement',
    () {
      final document = policy()
        ..['membershipProvider'] = 'STRIPE'
        ..['routes'] = [];
      final value = PurchaseOptions.fromJson(document);
      expect(value.membershipProvider, 'STRIPE');
      expect(value.routes, isEmpty);
    },
  );
}
