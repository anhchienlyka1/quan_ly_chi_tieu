import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/gold_asset_model.dart';

/// Persists GoldAssetModel list to SharedPreferences.
class GoldLocalDataSource {
  static const String _storageKey = 'gold_assets_data';

  Future<List<GoldAssetModel>> getAllAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((e) => GoldAssetModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<GoldAssetModel> addAsset(GoldAssetModel asset) async {
    final prefs = await SharedPreferences.getInstance();
    final List<GoldAssetModel> current = await getAllAssets();

    // Generate unique ID
    final newAsset = GoldAssetModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      goldTypeName: asset.goldTypeName,
      goldMenuId: asset.goldMenuId,
      purchaseDate: asset.purchaseDate,
      unit: asset.unit,
      quantity: asset.quantity,
      pricePerUnit: asset.pricePerUnit,
      fee: asset.fee,
      note: asset.note,
      createdAt: asset.createdAt,
    );

    current.add(newAsset);
    await _saveList(prefs, current);
    return newAsset;
  }

  Future<GoldAssetModel> updateAsset(GoldAssetModel asset) async {
    final prefs = await SharedPreferences.getInstance();
    final List<GoldAssetModel> current = await getAllAssets();

    final index = current.indexWhere((a) => a.id == asset.id);
    if (index == -1) throw Exception('Gold asset not found: ${asset.id}');

    current[index] = asset;
    await _saveList(prefs, current);
    return asset;
  }

  Future<void> deleteAsset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<GoldAssetModel> current = await getAllAssets();
    current.removeWhere((a) => a.id == id);
    await _saveList(prefs, current);
  }

  Future<void> deleteAllAssets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _saveList(
    SharedPreferences prefs,
    List<GoldAssetModel> assets,
  ) async {
    final String jsonString = jsonEncode(assets.map((a) => a.toMap()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}
