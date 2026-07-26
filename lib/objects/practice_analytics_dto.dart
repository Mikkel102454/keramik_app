import 'package:ceramic_app/objects/material_inventory_dto.dart';

class PracticeAnalyticsDto {
  const PracticeAnalyticsDto({
    required this.calculationVersion,
    required this.from,
    required this.to,
    required this.activity,
    required this.stageDistribution,
    required this.creationToFinished,
    required this.stageDurations,
    required this.ratingDistribution,
    required this.unratedCount,
    required this.mostUsedClays,
    required this.mostUsedGlazes,
    required this.successfulCombinations,
    required this.dataQuality,
    this.firingTemperatures,
    this.materialSpending = const [],
    this.spendingConversion,
    this.inventoryUsage = const [],
  });

  final String calculationVersion;
  final DateTime from;
  final DateTime to;
  final List<AnalyticsActivityBucket> activity;
  final List<AnalyticsStageCount> stageDistribution;
  final AnalyticsDuration creationToFinished;
  final List<AnalyticsStageDuration> stageDurations;
  final List<AnalyticsRatingCount> ratingDistribution;
  final int unratedCount;
  final List<AnalyticsUsageRank> mostUsedClays;
  final List<AnalyticsUsageRank> mostUsedGlazes;
  final List<AnalyticsCombination> successfulCombinations;
  final AnalyticsFiringTemperature? firingTemperatures;
  final AnalyticsDataQuality dataQuality;
  final List<AnalyticsMoneyTotal> materialSpending;
  final CurrencyConversionDto? spendingConversion;
  final List<AnalyticsInventoryUsage> inventoryUsage;

  bool get hasCeramicData => dataQuality.ceramicCount > 0;
  bool get hasAnyData =>
      hasCeramicData ||
      materialSpending.isNotEmpty ||
      inventoryUsage.isNotEmpty;

  factory PracticeAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return PracticeAnalyticsDto(
      calculationVersion: json['calculationVersion'] as String,
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      activity: _list(json['activity'], AnalyticsActivityBucket.fromJson),
      stageDistribution: _list(
        json['stageDistribution'],
        AnalyticsStageCount.fromJson,
      ),
      creationToFinished: AnalyticsDuration.fromJson(
        json['creationToFinished'],
      ),
      stageDurations: _list(
        json['stageDurations'],
        AnalyticsStageDuration.fromJson,
      ),
      ratingDistribution: _list(
        json['ratingDistribution'],
        AnalyticsRatingCount.fromJson,
      ),
      unratedCount: json['unratedCount'] as int? ?? 0,
      mostUsedClays: _list(json['mostUsedClays'], AnalyticsUsageRank.fromJson),
      mostUsedGlazes: _list(
        json['mostUsedGlazes'],
        AnalyticsUsageRank.fromJson,
      ),
      successfulCombinations: _list(
        json['successfulCombinations'],
        AnalyticsCombination.fromJson,
      ),
      firingTemperatures: json['firingTemperatures'] == null
          ? null
          : AnalyticsFiringTemperature.fromJson(json['firingTemperatures']),
      dataQuality: AnalyticsDataQuality.fromJson(json['dataQuality']),
      materialSpending: _list(
        json['materialSpending'],
        AnalyticsMoneyTotal.fromJson,
      ),
      spendingConversion: json['spendingConversion'] == null
          ? null
          : CurrencyConversionDto.fromJson(
              json['spendingConversion'] as Map<String, dynamic>,
            ),
      inventoryUsage: _list(
        json['inventoryUsage'],
        AnalyticsInventoryUsage.fromJson,
      ),
    );
  }

  static List<T> _list<T>(
    dynamic value,
    T Function(Map<String, dynamic>) factory,
  ) => (value as List? ?? const [])
      .map((item) => factory(item as Map<String, dynamic>))
      .toList();
}

class AnalyticsActivityBucket {
  const AnalyticsActivityBucket({
    required this.bucketStart,
    required this.created,
    required this.completed,
  });
  final DateTime bucketStart;
  final int created;
  final int completed;

  factory AnalyticsActivityBucket.fromJson(Map<String, dynamic> json) =>
      AnalyticsActivityBucket(
        bucketStart: DateTime.parse(json['bucketStart']),
        created: json['created'] as int,
        completed: json['completed'] as int,
      );
}

class AnalyticsStageCount {
  const AnalyticsStageCount({
    required this.stageId,
    required this.stage,
    required this.count,
  });
  final int stageId;
  final String stage;
  final int count;

  factory AnalyticsStageCount.fromJson(Map<String, dynamic> json) =>
      AnalyticsStageCount(
        stageId: json['stageId'] as int,
        stage: json['stage'] as String,
        count: json['count'] as int,
      );
}

class AnalyticsDuration {
  const AnalyticsDuration({this.averageSeconds, required this.sampleCount});
  final int? averageSeconds;
  final int sampleCount;

  factory AnalyticsDuration.fromJson(Map<String, dynamic> json) =>
      AnalyticsDuration(
        averageSeconds: json['averageSeconds'] as int?,
        sampleCount: json['sampleCount'] as int,
      );
}

class AnalyticsStageDuration {
  const AnalyticsStageDuration({
    required this.stageId,
    required this.stage,
    this.averageSeconds,
    required this.sampleCount,
  });
  final int stageId;
  final String stage;
  final int? averageSeconds;
  final int sampleCount;

  factory AnalyticsStageDuration.fromJson(Map<String, dynamic> json) =>
      AnalyticsStageDuration(
        stageId: json['stageId'] as int,
        stage: json['stage'] as String,
        averageSeconds: json['averageSeconds'] as int?,
        sampleCount: json['sampleCount'] as int,
      );
}

class AnalyticsRatingCount {
  const AnalyticsRatingCount({required this.rating, required this.count});
  final int rating;
  final int count;

  factory AnalyticsRatingCount.fromJson(Map<String, dynamic> json) =>
      AnalyticsRatingCount(
        rating: json['rating'] as int,
        count: json['count'] as int,
      );
}

class AnalyticsUsageRank {
  const AnalyticsUsageRank({
    required this.materialId,
    required this.title,
    required this.ceramicCount,
  });
  final int materialId;
  final String title;
  final int ceramicCount;

  factory AnalyticsUsageRank.fromJson(Map<String, dynamic> json) =>
      AnalyticsUsageRank(
        materialId: json['materialId'] as int,
        title: json['title'] as String,
        ceramicCount: json['ceramicCount'] as int,
      );
}

class AnalyticsCombination {
  const AnalyticsCombination({
    required this.clay,
    required this.glaze,
    required this.averageRating,
    required this.sampleCount,
  });
  final String clay;
  final String glaze;
  final String averageRating;
  final int sampleCount;

  factory AnalyticsCombination.fromJson(Map<String, dynamic> json) =>
      AnalyticsCombination(
        clay: json['clay'] as String,
        glaze: json['glaze'] as String,
        averageRating: json['averageRating'] as String,
        sampleCount: json['sampleCount'] as int,
      );
}

class AnalyticsFiringTemperature {
  const AnalyticsFiringTemperature({
    required this.averageDeltaC,
    required this.sampleCount,
    required this.belowTargetCount,
    required this.nearTargetCount,
    required this.aboveTargetCount,
  });
  final String averageDeltaC;
  final int sampleCount;
  final int belowTargetCount;
  final int nearTargetCount;
  final int aboveTargetCount;

  factory AnalyticsFiringTemperature.fromJson(Map<String, dynamic> json) =>
      AnalyticsFiringTemperature(
        averageDeltaC: json['averageDeltaC'] as String,
        sampleCount: json['sampleCount'] as int,
        belowTargetCount: json['belowTargetCount'] as int,
        nearTargetCount: json['nearTargetCount'] as int,
        aboveTargetCount: json['aboveTargetCount'] as int,
      );
}

class AnalyticsDataQuality {
  const AnalyticsDataQuality({
    required this.ceramicCount,
    required this.legacyBaselineCount,
    required this.trustedCompletionCount,
    required this.closedStageVisitCount,
  });
  final int ceramicCount;
  final int legacyBaselineCount;
  final int trustedCompletionCount;
  final int closedStageVisitCount;

  factory AnalyticsDataQuality.fromJson(Map<String, dynamic> json) =>
      AnalyticsDataQuality(
        ceramicCount: json['ceramicCount'] as int,
        legacyBaselineCount: json['legacyBaselineCount'] as int,
        trustedCompletionCount: json['trustedCompletionCount'] as int,
        closedStageVisitCount: json['closedStageVisitCount'] as int,
      );
}

class AnalyticsMoneyTotal {
  const AnalyticsMoneyTotal({required this.currency, required this.amount});
  final String currency;
  final String amount;
  factory AnalyticsMoneyTotal.fromJson(Map<String, dynamic> json) =>
      AnalyticsMoneyTotal(
        currency: json['currency'] as String,
        amount: json['amount'] as String,
      );
}

class AnalyticsInventoryUsage {
  const AnalyticsInventoryUsage({
    required this.material,
    required this.unit,
    required this.quantity,
  });
  final String material;
  final String unit;
  final String quantity;
  factory AnalyticsInventoryUsage.fromJson(Map<String, dynamic> json) =>
      AnalyticsInventoryUsage(
        material: json['material'] as String,
        unit: json['unit'] as String,
        quantity: json['quantity'] as String,
      );
}
