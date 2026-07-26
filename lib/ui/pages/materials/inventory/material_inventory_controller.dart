import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/objects/material_inventory_dto.dart';
import 'package:ceramic_app/repositories/clay_repository.dart';
import 'package:ceramic_app/repositories/glaze_repository.dart';
import 'package:ceramic_app/repositories/material_inventory_repository.dart';
import 'package:flutter/foundation.dart';

typedef InventoryAccountLoader =
    Future<List<MaterialInventoryAccountDto>> Function({bool lowStockOnly});
typedef InventoryClayLoader = Future<List<ClayDto>> Function();
typedef InventoryGlazeLoader = Future<List<GlazeDto>> Function();

class MaterialInventoryController extends ChangeNotifier {
  MaterialInventoryController({
    InventoryAccountLoader? accountLoader,
    InventoryClayLoader? clayLoader,
    InventoryGlazeLoader? glazeLoader,
  }) : _accountLoader =
           accountLoader ?? MaterialInventoryRepository.getAccounts,
       _clayLoader = clayLoader ?? ClayRepository.getClayTypes,
       _glazeLoader = glazeLoader ?? GlazeRepository.getGlazes;

  final InventoryAccountLoader _accountLoader;
  final InventoryClayLoader _clayLoader;
  final InventoryGlazeLoader _glazeLoader;
  List<MaterialInventoryAccountDto> accounts = const [];
  List<ClayDto> clays = const [];
  List<GlazeDto> glazes = const [];
  bool loading = false;
  bool lowStockOnly = false;
  Object? error;
  bool _disposed = false;

  Future<void> load({bool? showLowStockOnly}) async {
    if (_disposed || loading) return;
    if (showLowStockOnly != null) lowStockOnly = showLowStockOnly;
    loading = true;
    error = null;
    _notify();
    try {
      final values = await Future.wait([
        _accountLoader(lowStockOnly: lowStockOnly),
        _clayLoader(),
        _glazeLoader(),
      ]);
      accounts = values[0] as List<MaterialInventoryAccountDto>;
      clays = values[1] as List<ClayDto>;
      glazes = values[2] as List<GlazeDto>;
    } catch (value) {
      error = value;
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<bool> create({
    required String type,
    required int materialId,
    required String unit,
    String? threshold,
  }) async {
    try {
      await MaterialInventoryRepository.createAccount(
        materialType: type,
        materialId: materialId,
        canonicalUnit: unit,
        lowStockThreshold: threshold,
      );
      await load();
      return true;
    } catch (value) {
      error = value;
      _notify();
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
