/// Model representing a single gold price entry from the BTMC API.
/// API URL: http://api.btmc.vn/api/BTMCAPI/getpricebtmc?key=...
///
/// Fields mapping (format mới: mỗi key có @ prefix và số row):
///  @row  → row number
///  @n_{row}  → name         (tên giá vàng)
///  @k_{row}  → karat        (hàm lượng Kara)
///  @h_{row}  → purity       (hàm lượng vàng)
///  @pb_{row} → buyPrice     (giá mua vào, VNĐ/lượng)
///  @ps_{row} → sellPrice    (giá bán ra, VNĐ/lượng)
///  @pt_{row} → worldPrice   (giá thế giới theo USD/oz)
///  @d_{row}  → updatedAt    (thời gian nhập giá, dd/MM/yyyy HH:mm)
///  (menuid đã bị bỏ trong format mới)
class GoldPriceModel {
  final int row;
  final String name;
  final String karat;
  final String purity;
  final double buyPrice;
  final double sellPrice;
  final double worldPrice;
  final DateTime? updatedAt;
  final int? menuId;

  const GoldPriceModel({
    required this.row,
    required this.name,
    required this.karat,
    required this.purity,
    required this.buyPrice,
    required this.sellPrice,
    required this.worldPrice,
    this.updatedAt,
    this.menuId,
  });

  /// Parse from BTMC API attribute map.
  ///
  /// Hỗ trợ 2 format:
  ///   - JSON mới (row=1):  {"@row":"1", "@n_1":"...", "@pb_1":"..."}
  ///   - JSON cũ / XML:     {"row":"1",  "n_1":"...",  "pb_1":"..."}
  factory GoldPriceModel.fromApiMap(Map<String, dynamic> attrs) {
    // Helper: tìm value theo key, thử cả dạng "@key" và "key"
    dynamic get(String key) => attrs['@$key'] ?? attrs[key];

    // Với row attribute cũng có thể là "@row"
    final rowRaw = attrs['@row'] ?? attrs['row'];

    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      var s = value.toString().trim();
      if (s.isEmpty) return 0.0;

      // BTMC API trả giá dạng: "18,330,000" hoặc "18.330.000" hoặc "18330000"
      // Cần phân biệt dấu phân cách nghìn vs dấu thập phân:
      // - Nếu có cả '.' và ',' → dấu cuối cùng là thập phân
      // - Nếu chỉ có '.' hoặc ',' với ≥2 lần xuất hiện → đó là phân cách nghìn
      // - Nếu chỉ có '.' hoặc ',' 1 lần và sau nó có đúng 3 chữ số → phân cách nghìn

      final hasDot = s.contains('.');
      final hasComma = s.contains(',');

      if (hasDot && hasComma) {
        // Cả hai: dấu cuối là thập phân, dấu kia là nghìn
        final lastDot = s.lastIndexOf('.');
        final lastComma = s.lastIndexOf(',');
        if (lastDot > lastComma) {
          // '.' là thập phân → xóa ',' (nghìn)
          s = s.replaceAll(',', '');
        } else {
          // ',' là thập phân → xóa '.' (nghìn), đổi ',' → '.'
          s = s.replaceAll('.', '').replaceAll(',', '.');
        }
      } else if (hasDot) {
        final parts = s.split('.');
        if (parts.length > 2) {
          // Nhiều dấu '.' → phân cách nghìn (VN format: 18.330.000)
          s = s.replaceAll('.', '');
        } else if (parts.length == 2 && parts[1].length == 3) {
          // "18.330" → phân cách nghìn (1 nhóm 3 số)
          s = s.replaceAll('.', '');
        }
        // Còn lại: "18330000.50" → giữ nguyên dấu '.' thập phân
      } else if (hasComma) {
        final parts = s.split(',');
        if (parts.length > 2) {
          // Nhiều dấu ',' → phân cách nghìn (US format: 18,330,000)
          s = s.replaceAll(',', '');
        } else if (parts.length == 2 && parts[1].length == 3) {
          // "18,330" → phân cách nghìn
          s = s.replaceAll(',', '');
        } else {
          // "18330000,50" → thập phân kiểu VN → đổi ',' → '.'
          s = s.replaceAll(',', '.');
        }
      }

      return double.tryParse(s) ?? 0.0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        // Format: "dd/MM/yyyy HH:MM"
        final parts = value.toString().trim().split(' ');
        if (parts.length < 2) return null;
        final dateParts = parts[0].split('/');
        final timeParts = parts[1].split(':');
        if (dateParts.length < 3 || timeParts.length < 2) return null;
        return DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      } catch (_) {
        return null;
      }
    }

    // BTMC API mới (JSON): key dạng "@{prefix}_{row}" (e.g. "@n_359" cho row 359)
    // BTMC API cũ (XML):   key dạng "{prefix}_1" (e.g. "n_1")
    // Ưu tiên key theo row thực trước để tránh đọc nhầm dữ liệu.
    final rowStr = rowRaw?.toString() ?? '';
    String? findValue(String prefix) {
      // Ưu tiên 1: key theo row thực (format JSON mới)
      if (rowStr.isNotEmpty) {
        final byRow = attrs['@${prefix}_$rowStr'] ?? attrs['${prefix}_$rowStr'];
        if (byRow != null) return byRow.toString();
      }
      // Fallback: key _1 (format XML cũ)
      final fallback = get('${prefix}_1');
      return fallback?.toString();
    }

    return GoldPriceModel(
      row: int.tryParse(rowRaw?.toString() ?? '0') ?? 0,
      name: findValue('n')?.trim() ?? '',
      karat: findValue('k')?.trim() ?? '',
      purity: findValue('h')?.trim() ?? '',
      buyPrice: parsePrice(findValue('pb')),
      sellPrice: parsePrice(findValue('ps')),
      worldPrice: parsePrice(findValue('pt')),
      updatedAt: parseDate(findValue('d')),
      menuId: int.tryParse(
        (attrs['@menuid'] ?? attrs['menuid'])?.toString() ?? '',
      ),
    );
  }

  /// Short display name (remove parenthetical suffix).
  String get shortName {
    final parenIdx = name.indexOf('(');
    if (parenIdx > 0) return name.substring(0, parenIdx).trim();
    return name.trim();
  }

  @override
  String toString() =>
      'GoldPriceModel(name: $name, buy: $buyPrice, sell: $sellPrice)';
}
