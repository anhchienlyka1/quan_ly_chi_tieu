import 'package:flutter/foundation.dart';
import '../models/gold_asset_model.dart';
import '../models/gold_price_model.dart';
import '../repositories/gold_repository.dart';

/// State management for the Gold feature.
/// Single source of truth for gold assets and live prices.
///
/// Usage:
///   context.read<GoldProvider>()   // one-shot
///   context.watch<GoldProvider>()  // rebuild on change
class GoldProvider extends ChangeNotifier {
  final GoldRepository _repository = GoldRepository();

  // ── State ────────────────────────────────────────────────────
  List<GoldAssetModel> _assets = [];
  List<GoldPriceModel> _livePrices = [];
  bool _isLoading = false;
  bool _isPriceLoading = false;
  String? _error;
  String? _priceError;
  DateTime? _lastPriceFetchAt;

  // Cache duration for live prices (5 minutes)
  static const Duration _priceCacheDuration = Duration(minutes: 5);

  // ── Getters ──────────────────────────────────────────────────

  /// All assets (both active and sold)
  List<GoldAssetModel> get assets => List.unmodifiable(_assets);

  /// Only assets that are still being held (not sold)
  List<GoldAssetModel> get activeAssets =>
      _assets.where((a) => !a.isSold).toList();

  /// Only assets that have been sold (history)
  List<GoldAssetModel> get soldAssets {
    final sold = _assets.where((a) => a.isSold).toList();
    sold.sort(
      (a, b) => (b.sellDate ?? b.purchaseDate).compareTo(
        a.sellDate ?? a.purchaseDate,
      ),
    );
    return sold;
  }

  List<GoldPriceModel> get livePrices => List.unmodifiable(_livePrices);
  bool get isLoading => _isLoading;
  bool get isPriceLoading => _isPriceLoading;
  String? get error => _error;
  String? get priceError => _priceError;
  bool get hasAssets => _assets.isNotEmpty;
  bool get hasActiveAssets => activeAssets.isNotEmpty;
  bool get hasPrices => _livePrices.isNotEmpty;

  // ── Derived computations (active only) ───────────────────────

  /// Total current value of all active gold holdings (VNĐ)
  double get totalCurrentValue {
    return activeAssets.fold(0.0, (sum, asset) {
      final price = _priceForAsset(asset);
      if (price == null) return sum + asset.totalCost;
      return sum + asset.calculateProfit(price.buyPrice).currentValue;
    });
  }

  /// Total investment for active assets (VNĐ)
  double get totalInvested =>
      activeAssets.fold(0.0, (sum, a) => sum + a.totalCost);

  /// Overall profit/loss for active assets (VNĐ)
  double get totalProfit => totalCurrentValue - totalInvested;

  /// Overall profit percentage for active assets
  double get totalProfitPercent =>
      totalInvested > 0 ? (totalProfit / totalInvested) * 100 : 0.0;

  bool get isOverallProfit => totalProfit >= 0;

  // ── Realized stats (sold assets) ─────────────────────────────

  /// Total realized profit from all sold assets (VNĐ)
  double get totalRealizedProfit =>
      soldAssets.fold(0.0, (sum, a) => sum + (a.realizedProfit ?? 0));

  /// Total revenue from all sold assets (VNĐ)
  double get totalSellRevenue =>
      soldAssets.fold(0.0, (sum, a) => sum + (a.sellTotalRevenue ?? 0));

  // ── Private helpers ───────────────────────────────────────────

  /// Find the best matching price for an asset by menuId or name.
  GoldPriceModel? _priceForAsset(GoldAssetModel asset) {
    if (_livePrices.isEmpty) return null;

    // Match by menuId first (exact)
    if (asset.goldMenuId != null) {
      final byId = _livePrices.where((p) => p.menuId == asset.goldMenuId);
      if (byId.isNotEmpty) return byId.first;
    }

    // Fallback: fuzzy name match
    final assetNameLower = asset.goldTypeName.toLowerCase();
    final byName = _livePrices.where((p) {
      final pNameLower = p.name.toLowerCase();
      return pNameLower.contains(assetNameLower) ||
          assetNameLower.contains(pNameLower.split('(').first.trim());
    });
    if (byName.isNotEmpty) return byName.first;

    // Last resort: return first price (SJC default)
    return _livePrices.isNotEmpty ? _livePrices.first : null;
  }

  // ── Actions ───────────────────────────────────────────────────

  /// Load all local assets. Call once on screen init.
  Future<void> loadAssets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assets = await _repository.getAllAssets();
      _assets.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch live prices from BTMC. Skips if cache is still valid.
  Future<void> fetchPrices({bool force = false}) async {
    final now = DateTime.now();
    final isCacheValid =
        _lastPriceFetchAt != null &&
        now.difference(_lastPriceFetchAt!) < _priceCacheDuration &&
        _livePrices.isNotEmpty;

    if (isCacheValid && !force) return;

    _isPriceLoading = true;
    _priceError = null;
    notifyListeners();

    try {
      final all = await _repository.fetchLivePrices();
      // Chỉ giữ lại mặt hàng VÀNG, bỏ bạc và kim loại khác
      _livePrices = all
          .where((p) => p.name.toUpperCase().contains('VÀNG'))
          .toList();
      _lastPriceFetchAt = now;
      _isPriceLoading = false;
      notifyListeners();
    } catch (e) {
      _priceError = e.toString();
      _isPriceLoading = false;
      notifyListeners();
    }
  }

  /// Add a new gold asset and reload state.
  Future<void> addAsset(GoldAssetModel asset) async {
    await _repository.addAsset(asset);
    await loadAssets();
  }

  /// Update an existing gold asset.
  Future<void> updateAsset(GoldAssetModel asset) async {
    await _repository.updateAsset(asset);
    await loadAssets();
  }

  /// Delete a gold asset by ID.
  Future<void> deleteAsset(String id) async {
    await _repository.deleteAsset(id);
    await loadAssets();
  }

  /// Mark a gold asset as sold with sell details.
  Future<void> sellAsset({
    required String id,
    required double sellPricePerUnit,
    required DateTime sellDate,
    String? sellNote,
  }) async {
    final asset = _assets.firstWhere((a) => a.id == id);
    final updated = asset.copyWith(
      isSold: true,
      sellDate: sellDate,
      sellPricePerUnit: sellPricePerUnit,
      sellNote: sellNote,
    );
    await _repository.updateAsset(updated);
    await loadAssets();
  }

  /// Revert a sold asset back to active (un-sell).
  Future<void> revertSell(String id) async {
    final asset = _assets.firstWhere((a) => a.id == id);
    final updated = GoldAssetModel(
      id: asset.id,
      goldTypeName: asset.goldTypeName,
      goldMenuId: asset.goldMenuId,
      purchaseDate: asset.purchaseDate,
      unit: asset.unit,
      quantity: asset.quantity,
      pricePerUnit: asset.pricePerUnit,
      fee: asset.fee,
      note: asset.note,
      createdAt: asset.createdAt,
      isSold: false,
    );
    await _repository.updateAsset(updated);
    await loadAssets();
  }

  /// Full refresh: reload assets and force price re-fetch.
  Future<void> refresh() async {
    await Future.wait([loadAssets(), fetchPrices(force: true)]);
  }

  /// Get profit result for a specific asset using live prices.
  GoldProfitResult? getProfitFor(GoldAssetModel asset) {
    final price = _priceForAsset(asset);
    if (price == null) return null;
    return asset.calculateProfit(price.buyPrice);
  }

  /// Get the matched live price for an asset.
  GoldPriceModel? getLivePriceFor(GoldAssetModel asset) =>
      _priceForAsset(asset);

  /// Get price by menuId (for add/edit screen dropdown).
  GoldPriceModel? getPriceByMenuId(int menuId) =>
      _livePrices.where((p) => p.menuId == menuId).firstOrNull;

  /// Formatted time since last price update.
  String get lastUpdateText {
    if (_lastPriceFetchAt == null) return 'Chưa cập nhật';
    final diff = DateTime.now().difference(_lastPriceFetchAt!);
    if (diff.inMinutes < 1) return 'Vừa cập nhật';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    return '${diff.inHours} giờ trước';
  }
}
