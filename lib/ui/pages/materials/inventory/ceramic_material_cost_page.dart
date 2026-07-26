import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/material_inventory_dto.dart';
import 'package:ceramic_app/repositories/material_inventory_repository.dart';
import 'package:ceramic_app/ui/pages/materials/inventory/material_inventory_account_page.dart';
import 'package:ceramic_app/utils/measurement.dart';
import 'package:flutter/material.dart';

typedef CeramicCostLoader =
    Future<CeramicMaterialCostDto> Function(
      int ceramicId,
      String targetCurrency,
    );
typedef CeramicInventoryLoader =
    Future<List<MaterialInventoryAccountDto>> Function();

class CeramicMaterialCostPage extends StatefulWidget {
  const CeramicMaterialCostPage({
    super.key,
    required this.ceramicId,
    required this.ceramicTitle,
    this.costLoader = _defaultCostLoader,
    this.inventoryLoader = MaterialInventoryRepository.getAccounts,
  });
  final int ceramicId;
  final String ceramicTitle;
  final CeramicCostLoader costLoader;
  final CeramicInventoryLoader inventoryLoader;

  @override
  State<CeramicMaterialCostPage> createState() =>
      _CeramicMaterialCostPageState();
}

class _CeramicMaterialCostPageState extends State<CeramicMaterialCostPage> {
  CeramicMaterialCostDto? _cost;
  List<MaterialInventoryAccountDto> _accounts = const [];
  bool _loading = true;
  Object? _costError;
  Object? _inventoryError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _costError = null;
      _inventoryError = null;
    });
    try {
      _cost = await widget.costLoader(
        widget.ceramicId,
        AppSettingsController.instance.preferredCurrency,
      );
    } catch (value) {
      _costError = value;
    }
    try {
      _accounts = await widget.inventoryLoader();
    } catch (value) {
      _inventoryError = value;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.materialUsageAndCost)),
      body: _loading && _cost == null && _accounts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  if (_cost == null)
                    _LoadError(error: _costError, onRetry: _load)
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.estimatedMaterialCost,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            if (_cost!.estimatedMaterialCosts.isEmpty)
                              Text(context.l10n.noRecordedMaterialCost)
                            else
                              for (final value in _cost!.estimatedMaterialCosts)
                                Text(
                                  '${Measurement.formatMoneyText(value.amount, locale: Localizations.localeOf(context).toLanguageTag())} ${value.currency}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                            if (_cost!.conversion case final conversion?) ...[
                              const SizedBox(height: 12),
                              if (conversion.available)
                                Text(
                                  context.l10n.convertedTotal(
                                    Measurement.formatMoneyText(
                                      conversion.amount!,
                                      locale: Localizations.localeOf(
                                        context,
                                      ).toLanguageTag(),
                                    ),
                                    conversion.targetCurrency,
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                )
                              else
                                Text(
                                  context.l10n.currencyConversionUnavailable,
                                ),
                              if (conversion.rateDate != null)
                                Text(
                                  context.l10n.exchangeRateSource(
                                    conversion.provider ?? 'ECB',
                                    conversion.rateDate!
                                        .toIso8601String()
                                        .split('T')
                                        .first,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              localizedCostEstimateExplanation(context.l10n),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.recordMaterialUsage,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(context.l10n.chooseInventoryMaterial),
                  const SizedBox(height: 8),
                  if (_inventoryError != null)
                    _LoadError(error: _inventoryError, onRetry: _load)
                  else if (_accounts.isEmpty)
                    Text(context.l10n.noInventoryForUsage)
                  else
                    for (final account in _accounts)
                      Card(
                        child: ListTile(
                          title: Text(account.materialTitle),
                          subtitle: Text(
                            '${Measurement.formatDecimalText(account.currentStock, locale: Localizations.localeOf(context).toLanguageTag())} ${account.canonicalUnit.toLowerCase()}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: account.materialAvailable
                              ? () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MaterialInventoryAccountPage(
                                            account: account,
                                            ceramicId: widget.ceramicId,
                                            ceramicTitle: widget.ceramicTitle,
                                          ),
                                    ),
                                  );
                                  if (mounted) await _load();
                                }
                              : null,
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

Future<CeramicMaterialCostDto> _defaultCostLoader(
  int ceramicId,
  String targetCurrency,
) => MaterialInventoryRepository.getCeramicCost(
  ceramicId,
  targetCurrency: targetCurrency,
);

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.errorWithDetails(
              error?.toString() ?? context.l10n.inventoryLoadFailed,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    ),
  );
}
