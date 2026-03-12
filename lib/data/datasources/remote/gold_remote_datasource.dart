import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/gold_price_model.dart';

/// Fetches live gold prices from the BTMC API.
/// API: http://api.btmc.vn/api/BTMCAPI/getpricebtmc?key=3kd8ub1llcg9t45hnoh8hmn7t5kc2v
///
/// The API returns XML-like data with attributes per row.
class GoldRemoteDataSource {
  static const String _apiUrl =
      'http://api.btmc.vn/api/BTMCAPI/getpricebtmc?key=3kd8ub1llcg9t45hnoh8hmn7t5kc2v';

  static const Duration _timeout = Duration(seconds: 15);

  Future<List<GoldPriceModel>> fetchPrices() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('BTMC API error: ${response.statusCode}');
      }

      return _parseResponse(response.body);
    } catch (e) {
      throw Exception('Không thể tải giá vàng: $e');
    }
  }

  /// Parse either JSON or XML string returned by the BTMC API.
  List<GoldPriceModel> _parseResponse(String body) {
    final trimmed = body.trim();

    // Try JSON first
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return _parseJson(trimmed);
    }

    // Fall back to XML parsing
    return _parseXml(trimmed);
  }

  List<GoldPriceModel> _parseJson(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      List<dynamic> rows;

      if (decoded is Map && decoded.containsKey('DataList')) {
        final dataList = decoded['DataList'];
        if (dataList is Map && dataList.containsKey('Data')) {
          rows = dataList['Data'] is List
              ? dataList['Data']
              : [dataList['Data']];
        } else {
          rows = [];
        }
      } else if (decoded is List) {
        rows = decoded;
      } else {
        return [];
      }

      return rows
          .whereType<Map<String, dynamic>>()
          .map((r) => GoldPriceModel.fromApiMap(r))
          .where(
            (m) => m.name.isNotEmpty && (m.buyPrice > 0 || m.sellPrice > 0),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<GoldPriceModel> _parseXml(String body) {
    final List<GoldPriceModel> models = [];

    // Regex-based XML attribute extractor (avoids xml package dependency)
    // Matches <Data row="..." n_1="..." ... />
    final dataPattern = RegExp(r'<Data\s+([^/]*?)\s*/?>', dotAll: true);
    final attrPattern = RegExp(r'(\w+)="([^"]*)"');

    for (final dataMatch in dataPattern.allMatches(body)) {
      final attrsStr = dataMatch.group(1) ?? '';
      final Map<String, dynamic> attrs = {};

      for (final attrMatch in attrPattern.allMatches(attrsStr)) {
        attrs[attrMatch.group(1)!] = attrMatch.group(2);
      }

      if (attrs.isNotEmpty) {
        final model = GoldPriceModel.fromApiMap(attrs);
        if (model.name.isNotEmpty &&
            (model.buyPrice > 0 || model.sellPrice > 0)) {
          models.add(model);
        }
      }
    }

    return models;
  }
}
