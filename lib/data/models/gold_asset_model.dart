/// Model representing a user's gold asset (a purchased lot of gold).
class GoldAssetModel {
  final String id;
  final String goldTypeName; // Display name, e.g. "VÀNG MIẾNG SJC"
  final int? goldMenuId; // BTMC menuid for getting live price
  final DateTime purchaseDate;
  final GoldUnit unit;
  final double quantity; // Amount in chosen unit
  final double pricePerUnit; // Purchase price per user's unit (VNĐ)
  final double fee; // Extra purchase fee / gia công (VNĐ)
  final String? note;
  final DateTime createdAt;

  // ── Sold fields ───────────────────────────────────────────────
  final bool isSold;
  final DateTime? sellDate;
  final double? sellPricePerUnit; // Sell price per user's unit (VNĐ)
  final String? sellNote;

  const GoldAssetModel({
    required this.id,
    required this.goldTypeName,
    this.goldMenuId,
    required this.purchaseDate,
    required this.unit,
    required this.quantity,
    required this.pricePerUnit,
    this.fee = 0,
    this.note,
    required this.createdAt,
    this.isSold = false,
    this.sellDate,
    this.sellPricePerUnit,
    this.sellNote,
  });

  // ── Derived helpers ──────────────────────────────────────────

  /// Quantity expressed in chỉ (BTMC API price is per chỉ)
  /// 1 lượng = 10 chỉ
  double get quantityInChi => unit.toChi(quantity);

  /// Quantity expressed in lượng
  double get quantityInLuong => unit.toLuong(quantity);

  /// Total investment cost (VNĐ)
  /// pricePerUnit theo đơn vị user chọn → totalCost = quantity × pricePerUnit
  double get totalCost => quantity * pricePerUnit + fee;

  // ── Sell-derived helpers ─────────────────────────────────────

  /// Total sell revenue if sold. Returns null if not sold.
  double? get sellTotalRevenue =>
      isSold && sellPricePerUnit != null ? quantity * sellPricePerUnit! : null;

  /// Realized profit if sold (revenue - totalCost). Returns null if not sold.
  double? get realizedProfit {
    final rev = sellTotalRevenue;
    if (rev == null) return null;
    return rev - totalCost;
  }

  /// Realized profit percent if sold. Returns null if not sold.
  double? get realizedProfitPercent {
    final p = realizedProfit;
    if (p == null || totalCost <= 0) return null;
    return (p / totalCost) * 100;
  }

  // ── Profit/Loss calculation ───────────────────────────────────

  /// Calculate current value + profit/loss given a live price per chỉ
  /// (Use the shop's BUY IN price when evaluating user's holdings)
  GoldProfitResult calculateProfit(double currentPricePerChi) {
    final currentValue = quantityInChi * currentPricePerChi;
    final profit = currentValue - totalCost;
    final percent = totalCost > 0 ? (profit / totalCost) * 100 : 0.0;
    return GoldProfitResult(
      currentValue: currentValue,
      profit: profit,
      profitPercent: percent,
      currentPricePerChi: currentPricePerChi,
    );
  }

  // ── Serialization ─────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'goldTypeName': goldTypeName,
    'goldMenuId': goldMenuId,
    'purchaseDate': purchaseDate.toIso8601String(),
    'unit': unit.name,
    'quantity': quantity,
    'pricePerUnit': pricePerUnit,
    'fee': fee,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'isSold': isSold,
    'sellDate': sellDate?.toIso8601String(),
    'sellPricePerUnit': sellPricePerUnit,
    'sellNote': sellNote,
  };

  factory GoldAssetModel.fromMap(Map<String, dynamic> map) => GoldAssetModel(
    id: map['id'] as String,
    goldTypeName: map['goldTypeName'] as String,
    goldMenuId: map['goldMenuId'] as int?,
    purchaseDate: DateTime.parse(map['purchaseDate'] as String),
    unit: GoldUnit.values.firstWhere(
      (u) => u.name == map['unit'],
      orElse: () => GoldUnit.luong,
    ),
    quantity: (map['quantity'] as num).toDouble(),
    pricePerUnit: (map['pricePerUnit'] as num).toDouble(),
    fee: (map['fee'] as num? ?? 0).toDouble(),
    note: map['note'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    isSold: (map['isSold'] as bool?) ?? false,
    sellDate: map['sellDate'] != null
        ? DateTime.parse(map['sellDate'] as String)
        : null,
    sellPricePerUnit: (map['sellPricePerUnit'] as num?)?.toDouble(),
    sellNote: map['sellNote'] as String?,
  );

  GoldAssetModel copyWith({
    String? goldTypeName,
    int? goldMenuId,
    DateTime? purchaseDate,
    GoldUnit? unit,
    double? quantity,
    double? pricePerUnit,
    double? fee,
    String? note,
    bool? isSold,
    DateTime? sellDate,
    double? sellPricePerUnit,
    String? sellNote,
  }) => GoldAssetModel(
    id: id,
    goldTypeName: goldTypeName ?? this.goldTypeName,
    goldMenuId: goldMenuId ?? this.goldMenuId,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    unit: unit ?? this.unit,
    quantity: quantity ?? this.quantity,
    pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    fee: fee ?? this.fee,
    note: note ?? this.note,
    createdAt: createdAt,
    isSold: isSold ?? this.isSold,
    sellDate: sellDate ?? this.sellDate,
    sellPricePerUnit: sellPricePerUnit ?? this.sellPricePerUnit,
    sellNote: sellNote ?? this.sellNote,
  );
}

// ─────────────────────────────────────────────────────────────────
// Enum: GoldUnit
// ─────────────────────────────────────────────────────────────────

enum GoldUnit {
  chi('Chỉ'),
  luong('Lượng');

  final String label;
  const GoldUnit(this.label);

  /// Convert a quantity in this unit to lượng.
  /// 1 lượng = 10 chỉ
  double toLuong(double qty) {
    return this == GoldUnit.luong ? qty : qty / 10.0;
  }

  /// Convert a quantity in this unit to chỉ.
  /// 1 lượng = 10 chỉ
  double toChi(double qty) {
    return this == GoldUnit.chi ? qty : qty * 10.0;
  }

  /// Abbreviation shown in UI
  String get abbr => this == GoldUnit.luong ? 'lượng' : 'chỉ';
}

// ─────────────────────────────────────────────────────────────────
// Value Object: GoldProfitResult
// ─────────────────────────────────────────────────────────────────

class GoldProfitResult {
  final double currentValue;
  final double profit;
  final double profitPercent;
  final double currentPricePerChi;

  const GoldProfitResult({
    required this.currentValue,
    required this.profit,
    required this.profitPercent,
    required this.currentPricePerChi,
  });

  bool get isProfit => profit >= 0;
  bool get isLoss => profit < 0;

  /// Formatted profit string with sign: "+₫ 4,500,000" or "-₫ 200,000"
  String get profitSign => isProfit ? '+' : '';
}
