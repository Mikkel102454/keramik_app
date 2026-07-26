import 'dart:convert';
import 'dart:typed_data';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/material_inventory_dto.dart';
import 'package:ceramic_app/ui/pages/materials/inventory/material_inventory_account_page.dart';
import 'package:ceramic_app/ui/pages/materials/inventory/material_inventory_controller.dart';
import 'package:ceramic_app/ui/pages/materials/inventory/material_inventory_page.dart';
import 'package:ceramic_app/ui/pages/materials/inventory/ceramic_material_cost_page.dart';
import 'package:ceramic_app/utils/measurement.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  test('inventory DTO keeps fixed-precision amounts and audit references', () {
    expect(inventoryRecordableTransactionTypes, ['PURCHASE', 'USAGE']);
    expect(inventoryRecordableTransactionTypes, isNot(contains('ADJUSTMENT')));

    final account = MaterialInventoryAccountDto.fromJson(_accountJson());
    final transaction = MaterialInventoryTransactionDto.fromJson({
      'id': 4,
      'type': 'REVERSAL',
      'quantityDelta': '0.907185',
      'purchaseCostDelta': null,
      'usageCostDelta': '-4.5359',
      'currency': 'DKK',
      'supplier': null,
      'reference': 'LOT-2',
      'reason': 'Entered twice',
      'ceramicId': 7,
      'ceramicTitle': 'Usage bowl',
      'reversalOfId': 3,
      'occurredAt': '2026-07-26T10:00:00Z',
      'createdAt': '2026-07-26T10:00:01Z',
    });
    final cost = CeramicMaterialCostDto.fromJson({
      'ceramicId': 7,
      'estimatedMaterialCosts': [
        {'currency': 'DKK', 'amount': '4.5359'},
      ],
      'conversion': {
        'targetCurrency': 'EUR',
        'amount': '0.61',
        'rateDate': '2026-07-24',
        'provider': 'ECB',
        'stale': false,
        'unavailableCurrencies': <String>[],
      },
    });

    expect(account.currentStock, '9.092815');
    expect(transaction.reversalOfId, 3);
    expect(transaction.usageCostDelta, '-4.5359');
    expect(cost.estimatedMaterialCosts.single.currency, 'DKK');
    expect(cost.conversion?.amount, '0.61');
    expect(cost.conversion?.available, isTrue);
  });

  test('inventory display limits quantity and money decimal digits', () {
    expect(Measurement.formatDecimalText('1.803886', locale: 'en'), '1.804');
    expect(Measurement.formatMoneyText('187.3929', locale: 'en'), '187.39');
    expect(Measurement.formatDecimalText('1.803886', locale: 'da'), '1,804');
  });

  test(
    'inventory controller exposes retryable errors and owner data',
    () async {
      var fail = true;
      final controller = MaterialInventoryController(
        accountLoader: ({lowStockOnly = false}) async {
          if (fail) throw StateError('offline');
          return [MaterialInventoryAccountDto.fromJson(_accountJson())];
        },
        clayLoader: () async => [],
        glazeLoader: () async => [],
      );

      await controller.load();
      expect(controller.error, isNotNull);
      fail = false;
      await controller.load();
      expect(controller.error, isNull);
      expect(controller.accounts.single.lowStock, isTrue);
      controller.dispose();
    },
  );

  testWidgets('inventory dashboard remains usable on a compact layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = MaterialInventoryController(
      accountLoader: ({lowStockOnly = false}) async => [
        MaterialInventoryAccountDto.fromJson(_accountJson()),
      ],
      clayLoader: () async => [],
      glazeLoader: () async => [],
    );

    await tester.pumpWidget(
      localizedTestApp(home: MaterialInventoryPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Material inventory'), findsOneWidget);
    expect(find.text('Stoneware'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets(
    'closing the create inventory dialog keeps its controller alive',
    (tester) async {
      final controller = MaterialInventoryController(
        accountLoader: ({lowStockOnly = false}) async => [],
        clayLoader: () async => [],
        glazeLoader: () async => [],
      );

      await tester.pumpWidget(
        localizedTestApp(home: MaterialInventoryPage(controller: controller)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add inventory material'));
      await tester.pumpAndSettle();

      expect(find.text('Low-stock threshold (optional) (kg)'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      controller.dispose();
    },
  );

  testWidgets('ceramic cost errors include details and remain retryable', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: CeramicMaterialCostPage(
          ceramicId: 7,
          ceramicTitle: 'Usage bowl',
          costLoader: (_, _) async => throw StateError('cost unavailable'),
          inventoryLoader: () async => [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('cost unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'usage keeps the ceramic picker and loads cost history before conversion',
    (tester) async {
      final dio = Dio();
      dio.httpClientAdapter = _InventoryAdapter();
      ApiClient.dio = dio;

      await tester.pumpWidget(
        localizedTestApp(
          home: MaterialInventoryAccountPage(
            account: MaterialInventoryAccountDto.fromJson(_accountJson()),
            ceramicId: 7,
            ceramicTitle: 'Usage bowl',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record transaction'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory-transaction-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usage').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inventory-ceramic-picker')), findsOneWidget);
      expect(find.text('Usage bowl'), findsOneWidget);

      await tester.tap(find.byKey(const Key('inventory-cost-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Purchase-weighted average').last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('inventory-estimate-currency')),
        findsOneWidget,
      );
      expect(find.textContaining('No positive purchase history'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Map<String, dynamic> _accountJson() => {
  'id': 1,
  'version': 0,
  'materialType': 'CLAY',
  'materialId': 2,
  'materialTitle': 'Stoneware',
  'materialAvailable': true,
  'canonicalUnit': 'KG',
  'currentStock': '9.092815',
  'lowStockThreshold': '10',
  'lowStock': true,
  'createdAt': '2026-07-26T09:00:00Z',
  'updatedAt': '2026-07-26T10:00:00Z',
};

class _InventoryAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = switch (options.path) {
      '/api/material-inventory' => [_accountJson()],
      '/api/material-inventory/1/transactions' => {
        'items': <Object>[],
        'nextCursor': null,
      },
      '/api/material-inventory/1/cost-options' => {
        'weightedAverageUnitCosts': [
          {'currency': 'USD', 'amount': '12.50'},
        ],
      },
      '/api/ceramics' => [
        {
          'id': 7,
          'stageId': 1,
          'title': 'Usage bowl',
          'clayTypeId': 2,
          'rating': 0,
          'weight': 0.0,
          'note': '',
          'glazes': <Object>[],
          'tags': <Object>[],
          'images': <Object>[],
          'outcomeNote': '',
        },
      ],
      _ => throw StateError('Unexpected request: ${options.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
