import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/objects/material_inventory_dto.dart';
import 'package:ceramic_app/ui/pages/materials/inventory/material_inventory_account_page.dart';
import 'package:ceramic_app/ui/pages/materials/inventory/material_inventory_controller.dart';
import 'package:ceramic_app/utils/measurement.dart';
import 'package:flutter/material.dart';

class MaterialInventoryPage extends StatefulWidget {
  const MaterialInventoryPage({super.key, this.controller});
  final MaterialInventoryController? controller;

  @override
  State<MaterialInventoryPage> createState() => _MaterialInventoryPageState();
}

class _MaterialInventoryPageState extends State<MaterialInventoryPage> {
  late final MaterialInventoryController _controller =
      widget.controller ?? MaterialInventoryController();

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
      appBar: AppBar(
        title: Text(context.l10n.materialInventory),
        actions: [
          IconButton(
            tooltip: context.l10n.addInventoryMaterial,
            onPressed: _showCreate,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.loading && _controller.accounts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.error != null && _controller.accounts.isEmpty) {
            return _Retry(onRetry: _controller.load);
          }
          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.showLowStockOnly),
                  value: _controller.lowStockOnly,
                  onChanged: (value) =>
                      _controller.load(showLowStockOnly: value),
                ),
                if (_controller.loading) const LinearProgressIndicator(),
                if (_controller.error != null)
                  Text(
                    context.l10n.inventoryRefreshFailed,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_controller.accounts.isEmpty)
                  _Empty(onCreate: _showCreate)
                else
                  for (final account in _controller.accounts)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          account.materialType == 'CLAY'
                              ? Icons.landscape_outlined
                              : Icons.opacity_outlined,
                        ),
                        title: Text(account.materialTitle),
                        subtitle: Text(
                          [
                            _stock(account),
                            if (!account.materialAvailable)
                              context.l10n.catalogueMaterialRemoved,
                          ].join(' · '),
                        ),
                        trailing: account.lowStock
                            ? Tooltip(
                                message: context.l10n.lowStock,
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MaterialInventoryAccountPage(
                                account: account,
                              ),
                            ),
                          );
                          if (mounted) await _controller.load();
                        },
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _stock(MaterialInventoryAccountDto account) {
    final quantity = double.tryParse(account.currentStock) ?? 0;
    if (account.canonicalUnit == 'KG' &&
        AppSettingsController.instance.measurementSystem ==
            MeasurementSystem.imperial) {
      return context.l10n.stockAmount(
        Measurement.format(
          Measurement.weightFromKilograms(quantity, MeasurementSystem.imperial),
        ),
        MeasurementSystem.imperial.weightSymbol,
      );
    }
    return context.l10n.stockAmount(
      Measurement.format(quantity),
      account.canonicalUnit.toLowerCase(),
    );
  }

  Future<void> _showCreate() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateInventoryDialog(controller: _controller),
    );
    if (created == false && mounted && _controller.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${_controller.error}')));
    }
  }
}

class _CreateInventoryDialog extends StatefulWidget {
  const _CreateInventoryDialog({required this.controller});

  final MaterialInventoryController controller;

  @override
  State<_CreateInventoryDialog> createState() => _CreateInventoryDialogState();
}

class _CreateInventoryDialogState extends State<_CreateInventoryDialog> {
  final TextEditingController _threshold = TextEditingController();
  String _type = 'CLAY';
  String _unit = 'KG';
  int? _materialId;
  bool _saving = false;

  List<(int, String)> get _choices {
    final usedIds = widget.controller.accounts
        .where((value) => value.materialType == _type)
        .map((value) => value.materialId)
        .toSet();
    return _type == 'CLAY'
        ? widget.controller.clays
              .where((value) => !usedIds.contains(value.id))
              .map((value) => (value.id, value.title))
              .toList()
        : widget.controller.glazes
              .where((value) => !usedIds.contains(value.id))
              .map((value) => (value.id, value.title))
              .toList();
  }

  @override
  void initState() {
    super.initState();
    final choices = _choices;
    _materialId = choices.isEmpty ? null : choices.first.$1;
  }

  @override
  void dispose() {
    _threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final choices = _choices;
    return AlertDialog(
      title: Text(context.l10n.addInventoryMaterial),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: context.l10n.materialType,
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              items: [
                DropdownMenuItem(value: 'CLAY', child: Text(context.l10n.clay)),
                DropdownMenuItem(
                  value: 'GLAZE',
                  child: Text(context.l10n.glaze),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                      _type = value!;
                      _unit = 'KG';
                      final nextChoices = _choices;
                      _materialId = nextChoices.isEmpty
                          ? null
                          : nextChoices.first.$1;
                    }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey(_type),
              initialValue: _materialId,
              decoration: InputDecoration(
                labelText: context.l10n.material,
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              items: choices
                  .map(
                    (value) => DropdownMenuItem(
                      value: value.$1,
                      child: Text(value.$2),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _materialId = value),
            ),
            if (_type == 'GLAZE') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _unit,
                decoration: InputDecoration(
                  labelText: context.l10n.inventoryMeasurement,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'KG',
                    child: Text(context.l10n.byWeightKilograms),
                  ),
                  DropdownMenuItem(
                    value: 'L',
                    child: Text(context.l10n.byVolumeLitres),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _unit = value!),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.glazeMeasurementHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _threshold,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText:
                    '${context.l10n.lowStockThresholdOptional} (${_unit.toLowerCase()})',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving || _materialId == null ? null : _create,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.create),
        ),
      ],
    );
  }

  Future<void> _create() async {
    setState(() => _saving = true);
    final success = await widget.controller.create(
      type: _type,
      materialId: _materialId!,
      unit: _unit,
      threshold: _threshold.text,
    );
    if (mounted) Navigator.pop(context, success);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 24),
    child: Column(
      children: [
        const Icon(Icons.inventory_2_outlined, size: 52),
        const SizedBox(height: 12),
        Text(
          context.l10n.noInventoryYet,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(context.l10n.noInventoryYetBody, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: Text(context.l10n.addInventoryMaterial),
        ),
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
        Text(context.l10n.inventoryLoadFailed),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    ),
  );
}
