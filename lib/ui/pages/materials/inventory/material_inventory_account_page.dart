import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/material_inventory_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';
import 'package:ceramic_app/repositories/material_inventory_repository.dart';
import 'package:ceramic_app/utils/measurement.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MaterialInventoryAccountPage extends StatefulWidget {
  const MaterialInventoryAccountPage({
    super.key,
    required this.account,
    this.ceramicId,
    this.ceramicTitle,
  });
  final MaterialInventoryAccountDto account;
  final int? ceramicId;
  final String? ceramicTitle;

  @override
  State<MaterialInventoryAccountPage> createState() =>
      _MaterialInventoryAccountPageState();
}

class _MaterialInventoryAccountPageState
    extends State<MaterialInventoryAccountPage> {
  late MaterialInventoryAccountDto _account = widget.account;
  List<MaterialInventoryTransactionDto> _transactions = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        MaterialInventoryRepository.getAccounts(),
        MaterialInventoryRepository.getTransactions(_account.id),
      ]);
      final accounts = values[0] as List<MaterialInventoryAccountDto>;
      _account = accounts.firstWhere((value) => value.id == _account.id);
      _transactions = (values[1] as MaterialInventoryTransactionPageDto).items;
    } catch (value) {
      _error = value;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reversedTransactionIds = _transactions
        .map((value) => value.reversalOfId)
        .whereType<int>()
        .toSet();
    return Scaffold(
      appBar: AppBar(
        title: Text(_account.materialTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.editLowStockThreshold,
            onPressed: _editThreshold,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _record,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.recordTransaction),
      ),
      body: _loading && _transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _transactions.isEmpty
          ? Center(
              child: FilledButton(
                onPressed: _load,
                child: Text(context.l10n.retry),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayQuantity(_account.currentStock),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(context.l10n.currentStock),
                          const SizedBox(height: 8),
                          Text(
                            _account.lowStockThreshold == null
                                ? context.l10n.noLowStockThreshold
                                : context.l10n.thresholdValue(
                                    _displayQuantity(
                                      _account.lowStockThreshold!,
                                    ),
                                  ),
                          ),
                          if (!_account.materialAvailable)
                            Text(context.l10n.catalogueMaterialRemoved),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.transactionHistory,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    Text(context.l10n.noTransactions)
                  else
                    for (final transaction in _transactions)
                      Card(
                        child: ListTile(
                          leading: Icon(_transactionIcon(transaction.type)),
                          title: Text(
                            context.l10n.inventoryTransactionType(
                              transaction.type,
                            ),
                          ),
                          subtitle: Text(
                            [
                              _displaySignedQuantity(transaction.quantityDelta),
                              DateFormat.yMMMd(
                                Localizations.localeOf(context).toLanguageTag(),
                              ).format(transaction.occurredAt),
                              if (transaction.ceramicTitle != null)
                                transaction.ceramicTitle!,
                              if (transaction.reason != null)
                                transaction.reason!,
                            ].join(' · '),
                          ),
                          trailing:
                              transaction.type == 'REVERSAL' ||
                                  reversedTransactionIds.contains(
                                    transaction.id,
                                  )
                              ? null
                              : PopupMenuButton<String>(
                                  onSelected: (action) => action == 'edit'
                                      ? _edit(transaction)
                                      : _reverse(transaction),
                                  itemBuilder: (_) => [
                                    if (transaction.type == 'PURCHASE' ||
                                        transaction.type == 'USAGE')
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(
                                          context.l10n.editTransaction,
                                        ),
                                      ),
                                    PopupMenuItem(
                                      value: 'reverse',
                                      child: Text(
                                        context.l10n.reverseTransaction,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }

  IconData _transactionIcon(String type) => switch (type) {
    'PURCHASE' => Icons.shopping_bag_outlined,
    'USAGE' => Icons.remove_circle_outline,
    'ADJUSTMENT' => Icons.tune,
    _ => Icons.undo,
  };

  String get _inputUnit {
    if (_account.canonicalUnit == 'KG' &&
        AppSettingsController.instance.measurementSystem ==
            MeasurementSystem.imperial) {
      return 'LB';
    }
    return _account.canonicalUnit;
  }

  String _displayQuantity(String canonicalText) {
    final canonical = double.tryParse(canonicalText) ?? 0;
    if (_inputUnit == 'LB') {
      return '${Measurement.format(Measurement.weightFromKilograms(canonical, MeasurementSystem.imperial))} lb';
    }
    return '${Measurement.format(canonical)} ${_inputUnit.toLowerCase()}';
  }

  String _displaySignedQuantity(String canonicalText) {
    final canonical = double.tryParse(canonicalText) ?? 0;
    final displayed = _inputUnit == 'LB'
        ? Measurement.weightFromKilograms(canonical, MeasurementSystem.imperial)
        : canonical;
    final prefix = displayed > 0 ? '+' : '';
    return '$prefix${Measurement.format(displayed)} ${_inputUnit.toLowerCase()}';
  }

  Future<void> _editThreshold() async {
    final controller = TextEditingController(
      text: _account.lowStockThreshold ?? '',
    );
    final value = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.editLowStockThreshold),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText:
                '${context.l10n.lowStockThresholdOptional} (${_account.canonicalUnit.toLowerCase()})',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(context.l10n.clear),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    if (value == null) return;
    try {
      _account = await MaterialInventoryRepository.updateThreshold(
        _account,
        value,
      );
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _record() async {
    final result = await showDialog<_TransactionInput>(
      context: context,
      builder: (_) => _TransactionDialog(
        account: _account,
        inputUnit: _inputUnit,
        ceramicId: widget.ceramicId,
        ceramicTitle: widget.ceramicTitle,
      ),
    );
    if (result == null || !mounted) return;
    if (!await _confirmInput(result)) return;
    await _saveInput(result);
  }

  Future<void> _edit(MaterialInventoryTransactionDto transaction) async {
    final result = await showDialog<_TransactionInput>(
      context: context,
      builder: (_) => _TransactionDialog(
        account: _account,
        inputUnit: _inputUnit,
        ceramicId: widget.ceramicId,
        ceramicTitle: widget.ceramicTitle,
        transaction: transaction,
      ),
    );
    if (result == null || !mounted) return;
    if (!await _confirmInput(result, editing: true)) return;
    await _saveInput(result, original: transaction);
  }

  Future<bool> _confirmInput(
    _TransactionInput result, {
    bool editing = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          editing
              ? context.l10n.confirmEditTransaction
              : context.l10n.confirmInventoryTransaction,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizedConfirmInventoryTransactionBody(
                context.l10n,
                context.l10n.inventoryTransactionType(result.type),
                result.quantity,
                result.inputUnit.toLowerCase(),
                _account.materialTitle,
              ),
            ),
            if (editing) ...[
              const SizedBox(height: 12),
              Text(context.l10n.editTransactionAuditNote),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _saveInput(
    _TransactionInput result, {
    MaterialInventoryTransactionDto? original,
  }) async {
    try {
      if (original == null) {
        await MaterialInventoryRepository.recordTransaction(
          _account.id,
          type: result.type,
          quantity: result.quantity,
          inputUnit: result.inputUnit,
          purchaseCost: result.purchaseCost,
          currency: result.currency,
          supplier: result.supplier,
          reference: result.reference,
          ceramicId: result.ceramicId,
          costMode: result.costMode,
          manualEstimatedCost: result.manualCost,
        );
      } else {
        await MaterialInventoryRepository.editTransaction(
          _account.id,
          original.id,
          type: result.type,
          quantity: result.quantity,
          inputUnit: result.inputUnit,
          occurredAt: original.occurredAt,
          purchaseCost: result.purchaseCost,
          currency: result.currency,
          supplier: result.supplier,
          reference: result.reference,
          ceramicId: result.ceramicId,
          costMode: result.costMode,
          manualEstimatedCost: result.manualCost,
        );
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              original == null
                  ? context.l10n.transactionSaved
                  : context.l10n.transactionUpdated,
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _reverse(MaterialInventoryTransactionDto transaction) async {
    final reason = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.reverseTransaction),
        content: TextField(
          controller: reason,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: context.l10n.reversalReason,
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, reason.text),
            child: Text(context.l10n.reverse),
          ),
        ],
      ),
    );
    if (value == null || value.trim().isEmpty) return;
    try {
      await MaterialInventoryRepository.reverseTransaction(
        _account.id,
        transaction.id,
        value,
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

class _TransactionInput {
  const _TransactionInput({
    required this.type,
    required this.quantity,
    required this.inputUnit,
    required this.costMode,
    this.purchaseCost,
    this.currency,
    this.supplier,
    this.reference,
    this.ceramicId,
    this.manualCost,
  });
  final String type;
  final String quantity;
  final String inputUnit;
  final String? purchaseCost;
  final String? currency;
  final String? supplier;
  final String? reference;
  final int? ceramicId;
  final String costMode;
  final String? manualCost;
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({
    required this.account,
    required this.inputUnit,
    this.ceramicId,
    this.ceramicTitle,
    this.transaction,
  });
  final MaterialInventoryAccountDto account;
  final String inputUnit;
  final int? ceramicId;
  final String? ceramicTitle;
  final MaterialInventoryTransactionDto? transaction;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  late String type;
  late String costMode;
  late final TextEditingController quantity;
  late final TextEditingController purchaseCost;
  late String currency;
  late final TextEditingController supplier;
  late final TextEditingController reference;
  late final TextEditingController manualCost;
  List<CeramicDto>? ceramics;
  Object? ceramicsError;
  bool ceramicsLoading = false;
  List<MoneyAmountDto>? weightedCostOptions;
  Object? costOptionsError;
  bool costOptionsLoading = false;
  late int? selectedCeramicId;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    type = transaction?.type == 'USAGE' ? 'USAGE' : 'PURCHASE';
    costMode = transaction?.usageCostDelta == null ? 'NONE' : 'MANUAL';
    quantity = TextEditingController(
      text: transaction == null
          ? ''
          : _displayInputQuantity(transaction.quantityDelta),
    );
    purchaseCost = TextEditingController(
      text: transaction?.purchaseCostDelta ?? '',
    );
    currency =
        transaction?.currency ??
        AppSettingsController.instance.preferredCurrency;
    supplier = TextEditingController(text: transaction?.supplier ?? '');
    reference = TextEditingController(text: transaction?.reference ?? '');
    manualCost = TextEditingController(
      text: transaction?.usageCostDelta?.replaceFirst('-', '') ?? '',
    );
    selectedCeramicId = widget.ceramicId ?? transaction?.ceramicId;
    if (type == 'USAGE') {
      _loadCeramics();
    }
  }

  @override
  void dispose() {
    for (final value in [
      quantity,
      purchaseCost,
      supplier,
      reference,
      manualCost,
    ]) {
      value.dispose();
    }
    super.dispose();
  }

  String _displayInputQuantity(String canonicalText) {
    final canonical = (double.tryParse(canonicalText) ?? 0).abs();
    final displayed = widget.inputUnit == 'LB'
        ? Measurement.weightFromKilograms(canonical, MeasurementSystem.imperial)
        : canonical;
    return Measurement.format(displayed);
  }

  Future<void> _loadCeramics() async {
    setState(() {
      ceramicsLoading = true;
      ceramicsError = null;
    });
    try {
      final values = await CeramicRepository.getCeramics();
      if (mounted) {
        setState(() {
          ceramics = values;
          if (selectedCeramicId != null &&
              !values.any((value) => value.id == selectedCeramicId)) {
            selectedCeramicId = null;
          }
        });
      }
    } catch (error) {
      if (mounted) setState(() => ceramicsError = error);
    } finally {
      if (mounted) setState(() => ceramicsLoading = false);
    }
  }

  void _changeType(String value) {
    setState(() => type = value);
    if (value == 'USAGE' && ceramics == null && !ceramicsLoading) {
      _loadCeramics();
    }
  }

  void _changeCostMode(String value) {
    setState(() => costMode = value);
    if (value == 'WEIGHTED_AVERAGE' &&
        weightedCostOptions == null &&
        !costOptionsLoading) {
      _loadCostOptions();
    }
  }

  Future<void> _loadCostOptions() async {
    setState(() {
      costOptionsLoading = true;
      costOptionsError = null;
    });
    try {
      final values = await MaterialInventoryRepository.getCostOptions(
        widget.account.id,
      );
      if (!mounted) return;
      setState(() {
        weightedCostOptions = values;
      });
    } catch (error) {
      if (mounted) setState(() => costOptionsError = error);
    } finally {
      if (mounted) setState(() => costOptionsLoading = false);
    }
  }

  Widget _currencyDropdown({String? label, Key? key}) {
    final currencies = supportedExchangeCurrencies.contains(currency)
        ? supportedExchangeCurrencies
        : [currency, ...supportedExchangeCurrencies];
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: currency,
      decoration: InputDecoration(
        labelText: label ?? context.l10n.currency,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      items: currencies
          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
      onChanged: (value) => setState(() => currency = value!),
    );
  }

  Widget _weightedCurrencyField() {
    if (costOptionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (costOptionsError != null) {
      return Row(
        children: [
          Expanded(child: Text(context.l10n.costOptionsLoadFailed)),
          TextButton(
            onPressed: _loadCostOptions,
            child: Text(context.l10n.retry),
          ),
        ],
      );
    }
    final options = weightedCostOptions ?? const <MoneyAmountDto>[];
    if (options.isEmpty) {
      return Text(
        context.l10n.noCostedPurchaseHistory,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return _currencyDropdown(
      key: const Key('inventory-estimate-currency'),
      label: context.l10n.purchaseCostCurrency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final weightedAverageReady =
        type != 'USAGE' ||
        costMode != 'WEIGHTED_AVERAGE' ||
        (weightedCostOptions?.isNotEmpty == true &&
            !costOptionsLoading &&
            costOptionsError == null);
    return AlertDialog(
      title: Text(
        widget.transaction == null
            ? context.l10n.recordTransaction
            : context.l10n.editTransaction,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('inventory-transaction-type'),
              initialValue: type,
              decoration: InputDecoration(
                labelText: context.l10n.transactionType,
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              items: inventoryRecordableTransactionTypes
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(context.l10n.inventoryTransactionType(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _changeType(value!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantity,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText:
                    '${context.l10n.quantity} (${widget.inputUnit.toLowerCase()})',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            if (type == 'PURCHASE') ...[
              const SizedBox(height: 12),
              TextField(
                controller: purchaseCost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.totalPurchaseCostOptional,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              const SizedBox(height: 12),
              _currencyDropdown(),
              TextField(
                controller: supplier,
                decoration: InputDecoration(
                  labelText: context.l10n.supplierOptional,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              TextField(
                controller: reference,
                decoration: InputDecoration(
                  labelText: context.l10n.referenceOptional,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
            ],
            if (type == 'USAGE') ...[
              const SizedBox(height: 12),
              if (ceramicsLoading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                )
              else if (ceramicsError != null)
                Row(
                  children: [
                    Expanded(child: Text(context.l10n.ceramicsLoadFailed)),
                    TextButton(
                      onPressed: _loadCeramics,
                      child: Text(context.l10n.retry),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<int?>(
                  key: const Key('inventory-ceramic-picker'),
                  initialValue: selectedCeramicId,
                  decoration: InputDecoration(
                    labelText: context.l10n.chooseCeramicOptional,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(context.l10n.noAssociatedCeramic),
                    ),
                    for (final ceramic in ceramics ?? const <CeramicDto>[])
                      DropdownMenuItem<int?>(
                        value: ceramic.id,
                        child: Text(ceramic.title),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedCeramicId = value),
                ),
              DropdownButtonFormField<String>(
                key: const Key('inventory-cost-mode'),
                initialValue: costMode,
                decoration: InputDecoration(
                  labelText: context.l10n.costEstimate,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'NONE',
                    child: Text(context.l10n.noCostEstimate),
                  ),
                  DropdownMenuItem(
                    value: 'WEIGHTED_AVERAGE',
                    child: Text(context.l10n.weightedAverageCost),
                  ),
                  DropdownMenuItem(
                    value: 'MANUAL',
                    child: Text(context.l10n.manualCost),
                  ),
                ],
                onChanged: (value) => _changeCostMode(value!),
              ),
              if (costMode == 'WEIGHTED_AVERAGE') ...[
                const SizedBox(height: 12),
                _weightedCurrencyField(),
              ],
              if (costMode == 'MANUAL') ...[
                const SizedBox(height: 12),
                _currencyDropdown(),
              ],
              if (costMode == 'MANUAL')
                TextField(
                  controller: manualCost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.estimatedUsageCost,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                context.l10n.usageIsNeverInferred,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (widget.transaction != null) ...[
              const SizedBox(height: 12),
              Text(
                context.l10n.editTransactionAuditNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: quantity.text.trim().isEmpty || !weightedAverageReady
              ? null
              : () => Navigator.pop(
                  context,
                  _TransactionInput(
                    type: type,
                    quantity: quantity.text.trim(),
                    inputUnit: widget.inputUnit,
                    purchaseCost: purchaseCost.text,
                    currency: currency,
                    supplier: supplier.text,
                    reference: reference.text,
                    ceramicId: type == 'USAGE'
                        ? widget.ceramicId ?? selectedCeramicId
                        : null,
                    costMode: costMode,
                    manualCost: manualCost.text,
                  ),
                ),
          child: Text(context.l10n.review),
        ),
      ],
    );
  }
}
