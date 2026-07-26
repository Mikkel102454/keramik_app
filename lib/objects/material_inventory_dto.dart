const inventoryRecordableTransactionTypes = ['PURCHASE', 'USAGE'];

class MaterialInventoryAccountDto {
  const MaterialInventoryAccountDto({
    required this.id,
    required this.version,
    required this.materialType,
    required this.materialId,
    required this.materialTitle,
    required this.materialAvailable,
    required this.canonicalUnit,
    required this.currentStock,
    required this.lowStock,
    required this.createdAt,
    required this.updatedAt,
    this.lowStockThreshold,
  });

  final int id;
  final int version;
  final String materialType;
  final int? materialId;
  final String materialTitle;
  final bool materialAvailable;
  final String canonicalUnit;
  final String currentStock;
  final String? lowStockThreshold;
  final bool lowStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MaterialInventoryAccountDto.fromJson(Map<String, dynamic> json) =>
      MaterialInventoryAccountDto(
        id: json['id'] as int,
        version: json['version'] as int,
        materialType: json['materialType'] as String,
        materialId: json['materialId'] as int?,
        materialTitle: json['materialTitle'] as String,
        materialAvailable: json['materialAvailable'] as bool,
        canonicalUnit: json['canonicalUnit'] as String,
        currentStock: json['currentStock'] as String,
        lowStockThreshold: json['lowStockThreshold'] as String?,
        lowStock: json['lowStock'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class MaterialInventoryTransactionDto {
  const MaterialInventoryTransactionDto({
    required this.id,
    required this.type,
    required this.quantityDelta,
    required this.occurredAt,
    required this.createdAt,
    this.purchaseCostDelta,
    this.usageCostDelta,
    this.currency,
    this.supplier,
    this.reference,
    this.reason,
    this.ceramicId,
    this.ceramicTitle,
    this.reversalOfId,
  });

  final int id;
  final String type;
  final String quantityDelta;
  final String? purchaseCostDelta;
  final String? usageCostDelta;
  final String? currency;
  final String? supplier;
  final String? reference;
  final String? reason;
  final int? ceramicId;
  final String? ceramicTitle;
  final int? reversalOfId;
  final DateTime occurredAt;
  final DateTime createdAt;

  factory MaterialInventoryTransactionDto.fromJson(Map<String, dynamic> json) =>
      MaterialInventoryTransactionDto(
        id: json['id'] as int,
        type: json['type'] as String,
        quantityDelta: json['quantityDelta'] as String,
        purchaseCostDelta: json['purchaseCostDelta'] as String?,
        usageCostDelta: json['usageCostDelta'] as String?,
        currency: json['currency'] as String?,
        supplier: json['supplier'] as String?,
        reference: json['reference'] as String?,
        reason: json['reason'] as String?,
        ceramicId: json['ceramicId'] as int?,
        ceramicTitle: json['ceramicTitle'] as String?,
        reversalOfId: json['reversalOfId'] as int?,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class MaterialInventoryTransactionPageDto {
  const MaterialInventoryTransactionPageDto({
    required this.items,
    this.nextCursor,
  });
  final List<MaterialInventoryTransactionDto> items;
  final String? nextCursor;

  factory MaterialInventoryTransactionPageDto.fromJson(
    Map<String, dynamic> json,
  ) => MaterialInventoryTransactionPageDto(
    items: (json['items'] as List)
        .map(
          (value) => MaterialInventoryTransactionDto.fromJson(
            value as Map<String, dynamic>,
          ),
        )
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );
}

class MoneyAmountDto {
  const MoneyAmountDto({required this.currency, required this.amount});
  final String currency;
  final String amount;

  factory MoneyAmountDto.fromJson(Map<String, dynamic> json) => MoneyAmountDto(
    currency: json['currency'] as String,
    amount: json['amount'] as String,
  );
}

class CeramicMaterialCostDto {
  const CeramicMaterialCostDto({
    required this.ceramicId,
    required this.estimatedMaterialCosts,
    this.conversion,
  });
  final int ceramicId;
  final List<MoneyAmountDto> estimatedMaterialCosts;
  final CurrencyConversionDto? conversion;

  factory CeramicMaterialCostDto.fromJson(Map<String, dynamic> json) =>
      CeramicMaterialCostDto(
        ceramicId: json['ceramicId'] as int,
        estimatedMaterialCosts: (json['estimatedMaterialCosts'] as List)
            .map(
              (value) => MoneyAmountDto.fromJson(value as Map<String, dynamic>),
            )
            .toList(),
        conversion: json['conversion'] == null
            ? null
            : CurrencyConversionDto.fromJson(
                json['conversion'] as Map<String, dynamic>,
              ),
      );
}

class CurrencyConversionDto {
  const CurrencyConversionDto({
    required this.targetCurrency,
    required this.stale,
    required this.unavailableCurrencies,
    this.amount,
    this.rateDate,
    this.provider,
  });

  final String targetCurrency;
  final String? amount;
  final DateTime? rateDate;
  final String? provider;
  final bool stale;
  final List<String> unavailableCurrencies;

  bool get available => amount != null && !stale;

  factory CurrencyConversionDto.fromJson(Map<String, dynamic> json) =>
      CurrencyConversionDto(
        targetCurrency: json['targetCurrency'] as String,
        amount: json['amount'] as String?,
        rateDate: json['rateDate'] == null
            ? null
            : DateTime.parse(json['rateDate'] as String),
        provider: json['provider'] as String?,
        stale: json['stale'] as bool? ?? false,
        unavailableCurrencies: (json['unavailableCurrencies'] as List? ?? [])
            .cast<String>(),
      );
}
