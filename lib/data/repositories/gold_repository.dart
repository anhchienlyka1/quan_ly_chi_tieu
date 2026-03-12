import '../datasources/local/gold_local_datasource.dart';
import '../datasources/remote/gold_remote_datasource.dart';
import '../models/gold_asset_model.dart';
import '../models/gold_price_model.dart';

/// Facade for gold data operations.
/// Combines local persistence (user's gold assets) with BTMC remote price feed.
class GoldRepository {
  final GoldLocalDataSource _local = GoldLocalDataSource();
  final GoldRemoteDataSource _remote = GoldRemoteDataSource();

  // ── Assets (local) ───────────────────────────────────────────

  Future<List<GoldAssetModel>> getAllAssets() => _local.getAllAssets();

  Future<GoldAssetModel> addAsset(GoldAssetModel asset) =>
      _local.addAsset(asset);

  Future<GoldAssetModel> updateAsset(GoldAssetModel asset) =>
      _local.updateAsset(asset);

  Future<void> deleteAsset(String id) => _local.deleteAsset(id);

  Future<void> deleteAllAssets() => _local.deleteAllAssets();

  // ── Prices (remote) ───────────────────────────────────────────

  Future<List<GoldPriceModel>> fetchLivePrices() => _remote.fetchPrices();
}
