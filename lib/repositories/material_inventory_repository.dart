import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/objects/material_inventory_dto.dart';
import 'package:ceramic_app/utils/web.dart';

class MaterialInventoryRepository {
  static Future<List<MaterialInventoryAccountDto>> getAccounts({
    bool lowStockOnly = false,
  }) async {
    final response = await ApiClient.dio.get(
      '/api/material-inventory',
      queryParameters: {'lowStockOnly': lowStockOnly},
    );
    checkSuccess(response);
    return (response.data['data'] as List)
        .map(
          (value) => MaterialInventoryAccountDto.fromJson(
            value as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<MaterialInventoryAccountDto> createAccount({
    required String materialType,
    required int materialId,
    required String canonicalUnit,
    String? lowStockThreshold,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/material-inventory',
      data: {
        'materialType': materialType,
        'materialId': materialId,
        'canonicalUnit': canonicalUnit,
        'lowStockThreshold': _blankToNull(lowStockThreshold),
      },
    );
    checkSuccess(response);
    return MaterialInventoryAccountDto.fromJson(response.data['data']);
  }

  static Future<MaterialInventoryAccountDto> updateThreshold(
    MaterialInventoryAccountDto account,
    String? threshold,
  ) async {
    final response = await ApiClient.dio.put(
      '/api/material-inventory/${account.id}',
      data: {
        'expectedVersion': account.version,
        'lowStockThreshold': _blankToNull(threshold),
      },
    );
    checkSuccess(response);
    return MaterialInventoryAccountDto.fromJson(response.data['data']);
  }

  static Future<MaterialInventoryTransactionPageDto> getTransactions(
    int accountId, {
    String? cursor,
    int limit = 50,
  }) async {
    final response = await ApiClient.dio.get(
      '/api/material-inventory/$accountId/transactions',
      queryParameters: {'cursor': cursor, 'limit': limit},
    );
    checkSuccess(response);
    return MaterialInventoryTransactionPageDto.fromJson(response.data['data']);
  }

  static Future<MaterialInventoryTransactionDto> recordTransaction(
    int accountId, {
    required String type,
    required String quantity,
    required String inputUnit,
    String? purchaseCost,
    String? currency,
    String? supplier,
    String? reference,
    String? reason,
    int? ceramicId,
    String costMode = 'NONE',
    String? manualEstimatedCost,
  }) async {
    final response = await ApiClient.dio.post(
      '/api/material-inventory/$accountId/transactions',
      data: _transactionData(
        type: type,
        quantity: quantity,
        inputUnit: inputUnit,
        purchaseCost: purchaseCost,
        currency: currency,
        supplier: supplier,
        reference: reference,
        reason: reason,
        ceramicId: ceramicId,
        costMode: costMode,
        manualEstimatedCost: manualEstimatedCost,
        occurredAt: DateTime.now(),
      ),
    );
    checkSuccess(response);
    return MaterialInventoryTransactionDto.fromJson(response.data['data']);
  }

  static Future<MaterialInventoryTransactionDto> editTransaction(
    int accountId,
    int transactionId, {
    required String type,
    required String quantity,
    required String inputUnit,
    required DateTime occurredAt,
    String? purchaseCost,
    String? currency,
    String? supplier,
    String? reference,
    int? ceramicId,
    String costMode = 'NONE',
    String? manualEstimatedCost,
  }) async {
    final response = await ApiClient.dio.put(
      '/api/material-inventory/$accountId/transactions/$transactionId',
      data: _transactionData(
        type: type,
        quantity: quantity,
        inputUnit: inputUnit,
        purchaseCost: purchaseCost,
        currency: currency,
        supplier: supplier,
        reference: reference,
        ceramicId: ceramicId,
        costMode: costMode,
        manualEstimatedCost: manualEstimatedCost,
        occurredAt: occurredAt,
      ),
    );
    checkSuccess(response);
    return MaterialInventoryTransactionDto.fromJson(response.data['data']);
  }

  static Future<MaterialInventoryTransactionDto> reverseTransaction(
    int accountId,
    int transactionId,
    String reason,
  ) async {
    final response = await ApiClient.dio.post(
      '/api/material-inventory/$accountId/transactions/$transactionId/reversal',
      data: {'reason': reason.trim()},
    );
    checkSuccess(response);
    return MaterialInventoryTransactionDto.fromJson(response.data['data']);
  }

  static Future<List<MoneyAmountDto>> getCostOptions(int accountId) async {
    final response = await ApiClient.dio.get(
      '/api/material-inventory/$accountId/cost-options',
    );
    checkSuccess(response);
    return (response.data['data']['weightedAverageUnitCosts'] as List)
        .map((value) => MoneyAmountDto.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  static Future<CeramicMaterialCostDto> getCeramicCost(
    int ceramicId, {
    String? targetCurrency,
  }) async {
    final response = await ApiClient.dio.get(
      '/api/ceramics/$ceramicId/material-cost',
      queryParameters: {
        'targetCurrency': ?targetCurrency,
      },
    );
    checkSuccess(response);
    return CeramicMaterialCostDto.fromJson(response.data['data']);
  }

  static String? _blankToNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  static Map<String, dynamic> _transactionData({
    required String type,
    required String quantity,
    required String inputUnit,
    required String costMode,
    required DateTime occurredAt,
    String? purchaseCost,
    String? currency,
    String? supplier,
    String? reference,
    String? reason,
    int? ceramicId,
    String? manualEstimatedCost,
  }) => {
    'type': type,
    'quantity': quantity,
    'inputUnit': inputUnit,
    'purchaseCost': _blankToNull(purchaseCost),
    'currency': _blankToNull(currency)?.toUpperCase(),
    'supplier': _blankToNull(supplier),
    'reference': _blankToNull(reference),
    'reason': _blankToNull(reason),
    'ceramicId': ceramicId,
    'costMode': costMode,
    'manualEstimatedCost': _blankToNull(manualEstimatedCost),
    'occurredAt': occurredAt.toUtc().toIso8601String(),
  };
}
