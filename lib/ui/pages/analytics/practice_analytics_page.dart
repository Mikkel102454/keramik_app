import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/practice_analytics_dto.dart';
import 'package:ceramic_app/ui/pages/analytics/practice_analytics_controller.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/utils/measurement.dart';
import 'package:intl/intl.dart';

class PracticeAnalyticsPage extends StatefulWidget {
  const PracticeAnalyticsPage({super.key, this.controller});
  final PracticeAnalyticsController? controller;

  @override
  State<PracticeAnalyticsPage> createState() => _PracticeAnalyticsPageState();
}

class _PracticeAnalyticsPageState extends State<PracticeAnalyticsPage> {
  late final PracticeAnalyticsController _controller =
      widget.controller ?? PracticeAnalyticsController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.practiceAnalytics)),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.loading && _controller.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.error != null && _controller.data == null) {
            return _Retry(onRetry: _controller.load);
          }
          final data = _controller.data;
          if (data == null) return const SizedBox.shrink();
          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                _rangeSelector(),
                if (_controller.loading) const LinearProgressIndicator(),
                if (_controller.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      context.l10n.analyticsRefreshFailed,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (!data.hasAnyData)
                  _Empty()
                else ...[
                  if (data.dataQuality.legacyBaselineCount > 0)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(context.l10n.incompleteHistory),
                        subtitle: Text(
                          context.l10n.incompleteHistoryBody(
                            data.dataQuality.legacyBaselineCount,
                          ),
                        ),
                      ),
                    ),
                  _activity(data),
                  _stages(data),
                  _durations(data),
                  _ratings(data),
                  _materials(data),
                  _inventory(data),
                  _combinations(data),
                  _firings(data),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _rangeSelector() {
    return Wrap(
      spacing: 8,
      children: AnalyticsRange.values.map((range) {
        return ChoiceChip(
          label: Text(switch (range) {
            AnalyticsRange.days90 => context.l10n.last90Days,
            AnalyticsRange.year => context.l10n.lastYear,
            AnalyticsRange.all => context.l10n.allTime,
          }),
          selected: _controller.range == range,
          onSelected: (_) => _controller.load(selectedRange: range),
        );
      }).toList(),
    );
  }

  Widget _activity(PracticeAnalyticsDto data) {
    final totalCreated = data.activity.fold<int>(
      0,
      (sum, value) => sum + value.created,
    );
    final totalCompleted = data.activity.fold<int>(
      0,
      (sum, value) => sum + value.completed,
    );
    final maximum = data.activity.fold<int>(
      1,
      (value, bucket) => [
        value,
        bucket.created,
        bucket.completed,
      ].reduce((a, b) => a > b ? a : b),
    );
    return _AnalyticsSection(
      title: context.l10n.createdAndCompleted,
      summary: context.l10n.createdCompletedSummary(
        totalCreated,
        totalCompleted,
      ),
      explanation: context.l10n.createdCompletedExplanation,
      child: data.activity.isEmpty
          ? _NoData(message: context.l10n.noTrustedActivityData)
          : Column(
              children: data.activity.map((bucket) {
                final month = DateFormat.yMMM(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(bucket.bucketStart);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(month),
                      _Bar(
                        label: context.l10n.created,
                        value: bucket.created,
                        maximum: maximum,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      _Bar(
                        label: context.l10n.completed,
                        value: bucket.completed,
                        maximum: maximum,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _stages(PracticeAnalyticsDto data) {
    final maximum = data.stageDistribution.fold<int>(
      1,
      (value, stage) => value > stage.count ? value : stage.count,
    );
    return _AnalyticsSection(
      title: context.l10n.currentStages,
      explanation: context.l10n.currentStagesExplanation,
      child: data.stageDistribution.isEmpty
          ? _NoData()
          : Column(
              children: data.stageDistribution
                  .map(
                    (stage) => _Bar(
                      label: localizedStageName(context.l10n, stage.stage),
                      value: stage.count,
                      maximum: maximum,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _durations(PracticeAnalyticsDto data) {
    final completion = data.creationToFinished;
    return _AnalyticsSection(
      title: context.l10n.practiceTiming,
      explanation: context.l10n.practiceTimingExplanation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.creationToFinished,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            completion.averageSeconds == null
                ? context.l10n.notEnoughHistory
                : context.l10n.durationWithSamples(
                    _duration(completion.averageSeconds!),
                    completion.sampleCount,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.timeInEachStage,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (data.stageDurations.isEmpty)
            _NoData(message: context.l10n.notEnoughHistory)
          else
            for (final stage in data.stageDurations)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(localizedStageName(context.l10n, stage.stage)),
                trailing: Text(
                  stage.averageSeconds == null
                      ? context.l10n.noData
                      : _duration(stage.averageSeconds!),
                ),
                subtitle: Text(context.l10n.sampleCount(stage.sampleCount)),
              ),
        ],
      ),
    );
  }

  Widget _ratings(PracticeAnalyticsDto data) {
    final maximum = [
      data.unratedCount,
      ...data.ratingDistribution.map((value) => value.count),
      1,
    ].reduce((a, b) => a > b ? a : b);
    return _AnalyticsSection(
      title: context.l10n.ratingDistribution,
      explanation: context.l10n.ratingExplanation,
      child: Column(
        children: [
          for (final rating in data.ratingDistribution)
            _Bar(
              label: context.l10n.starRating(rating.rating),
              value: rating.count,
              maximum: maximum,
              color: Colors.amber.shade700,
            ),
          _Bar(
            label: context.l10n.unrated,
            value: data.unratedCount,
            maximum: maximum,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }

  Widget _materials(PracticeAnalyticsDto data) {
    return _AnalyticsSection(
      title: context.l10n.mostUsedMaterials,
      explanation: context.l10n.mostUsedMaterialsExplanation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.clays,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          _ranked(data.mostUsedClays),
          const SizedBox(height: 12),
          Text(
            context.l10n.glazes,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          _ranked(data.mostUsedGlazes),
        ],
      ),
    );
  }

  Widget _ranked(List<AnalyticsUsageRank> values) {
    if (values.isEmpty) return _NoData();
    return Column(
      children: values
          .map(
            (value) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(value.title),
              trailing: Text(context.l10n.usedOnCeramics(value.ceramicCount)),
            ),
          )
          .toList(),
    );
  }

  Widget _inventory(PracticeAnalyticsDto data) {
    return _AnalyticsSection(
      title: context.l10n.inventorySpendingAndUsage,
      explanation: localizedInventoryAnalyticsExplanation(context.l10n),
      child: data.materialSpending.isEmpty && data.inventoryUsage.isEmpty
          ? _NoData(message: context.l10n.noInventoryAnalytics)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.materialSpending,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (data.materialSpending.isEmpty)
                  _NoData()
                else
                  for (final value in data.materialSpending)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(value.currency),
                      trailing: Text(
                        '${Measurement.formatMoneyText(value.amount, locale: Localizations.localeOf(context).toLanguageTag())} ${value.currency}',
                      ),
                    ),
                if (data.spendingConversion case final conversion?) ...[
                  if (conversion.available)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.l10n.convertedSpending(
                          Measurement.formatMoneyText(
                            conversion.amount!,
                            locale: Localizations.localeOf(
                              context,
                            ).toLanguageTag(),
                          ),
                          conversion.targetCurrency,
                        ),
                      ),
                    )
                  else
                    Text(context.l10n.currencyConversionUnavailable),
                  if (conversion.rateDate != null)
                    Text(
                      context.l10n.exchangeRateSource(
                        conversion.provider ?? 'ECB',
                        conversion.rateDate!.toIso8601String().split('T').first,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
                const SizedBox(height: 8),
                Text(
                  context.l10n.recordedInventoryUsage,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (data.inventoryUsage.isEmpty)
                  _NoData()
                else
                  for (final value in data.inventoryUsage)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(value.material),
                      trailing: Text(
                        '${Measurement.formatDecimalText(value.quantity, locale: Localizations.localeOf(context).toLanguageTag())} ${value.unit.toLowerCase()}',
                      ),
                    ),
              ],
            ),
    );
  }

  Widget _combinations(PracticeAnalyticsDto data) {
    return _AnalyticsSection(
      title: context.l10n.successfulCombinations,
      explanation: context.l10n.successfulCombinationsExplanation,
      child: data.successfulCombinations.isEmpty
          ? _NoData(message: context.l10n.noSuccessfulCombinations)
          : Column(
              children: data.successfulCombinations
                  .map(
                    (value) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${value.clay} + ${value.glaze}'),
                      subtitle: Text(
                        context.l10n.sampleCount(value.sampleCount),
                      ),
                      trailing: Text('★ ${value.averageRating}'),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _firings(PracticeAnalyticsDto data) {
    final firing = data.firingTemperatures;
    return _AnalyticsSection(
      title: context.l10n.firingTemperatureAccuracy,
      explanation: context.l10n.firingTemperatureExplanation,
      child: firing == null
          ? _NoData(message: context.l10n.noComparableFirings)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.averageTemperatureDelta(firing.averageDeltaC),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(context.l10n.sampleCount(firing.sampleCount)),
                const SizedBox(height: 12),
                Text(context.l10n.belowTargetCount(firing.belowTargetCount)),
                Text(context.l10n.nearTargetCount(firing.nearTargetCount)),
                Text(context.l10n.aboveTargetCount(firing.aboveTargetCount)),
              ],
            ),
    );
  }

  String _duration(int seconds) {
    final days = seconds ~/ Duration.secondsPerDay;
    final hours = (seconds % Duration.secondsPerDay) ~/ Duration.secondsPerHour;
    return context.l10n.durationDaysHours(days, hours);
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({
    required this.title,
    required this.explanation,
    required this.child,
    this.summary,
  });
  final String title;
  final String? summary;
  final String explanation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (summary != null) ...[const SizedBox(height: 4), Text(summary!)],
            const SizedBox(height: 14),
            child,
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(context.l10n.howCalculated),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(explanation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.maximum,
    required this.color,
  });
  final String label;
  final int value;
  final int maximum;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 92, child: Text(label)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 12,
                  value: maximum <= 0 ? 0 : value / maximum,
                  color: color,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            SizedBox(
              width: 42,
              child: Text('$value', textAlign: TextAlign.end),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData({this.message});
  final String? message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(message ?? context.l10n.noData),
  );
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
    child: Column(
      children: [
        const Icon(Icons.insights_outlined, size: 52),
        const SizedBox(height: 12),
        Text(
          context.l10n.noPracticeData,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(context.l10n.noPracticeDataBody, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.analyticsLoadFailed),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    ),
  );
}
