import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense_model.dart';

/// Result of an Excel import operation.
class ImportResult {
  final List<ExpenseModel> expenses;
  final int errorCount;
  final List<String> errors;

  const ImportResult({
    required this.expenses,
    required this.errorCount,
    this.errors = const [],
  });
}

/// Service for importing/exporting expense data as Excel (.xlsx) files.
class ExcelService {
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  ExcelService._internal();

  // ─── Column definitions ───
  static const _headers = [
    'STT',
    'Tiêu đề',
    'Số tiền',
    'Loại',
    'Danh mục',
    'Ngày',
    'Ghi chú',
  ];

  // ─── EXPORT ───────────────────────────────────────────────

  /// Export a list of expenses to an .xlsx file and share it.
  Future<void> exportAndShare(List<ExpenseModel> expenses) async {
    final bytes = _buildExcelBytes(expenses);
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/chi_tieu_$timestamp.xlsx');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Dữ liệu chi tiêu - Quản lý chi tiêu',
      ),
    );
  }

  /// Build the raw xlsx bytes from a list of expenses.
  List<int> _buildExcelBytes(List<ExpenseModel> expenses) {
    final excel = Excel.createExcel();

    // Rename the default sheet
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, 'Chi tiêu');
    }
    final sheet = excel['Chi tiêu'];

    // ─── Header row ───
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    for (var i = 0; i < _headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(_headers[i]);
      cell.cellStyle = headerStyle;
    }

    // ─── Data rows ───
    final dateFormat = DateFormat('dd/MM/yyyy');
    final amountFormat = NumberFormat('#,###', 'vi_VN');

    for (var rowIdx = 0; rowIdx < expenses.length; rowIdx++) {
      final e = expenses[rowIdx];
      final row = rowIdx + 1; // skip header

      // STT
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = IntCellValue(
        row,
      );

      // Tiêu đề
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(
        e.title,
      );

      // Số tiền
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(
        amountFormat.format(e.amount),
      );

      // Loại
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(
        e.type.label,
      );

      // Danh mục
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(
        e.category.label,
      );

      // Ngày
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(
        dateFormat.format(e.date),
      );

      // Ghi chú
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = TextCellValue(
        e.note ?? '',
      );
    }

    // ─── Column widths ───
    sheet.setColumnWidth(0, 6); // STT
    sheet.setColumnWidth(1, 25); // Tiêu đề
    sheet.setColumnWidth(2, 18); // Số tiền
    sheet.setColumnWidth(3, 12); // Loại
    sheet.setColumnWidth(4, 15); // Danh mục
    sheet.setColumnWidth(5, 14); // Ngày
    sheet.setColumnWidth(6, 30); // Ghi chú

    // Remove any other default sheets
    for (final name in excel.sheets.keys.toList()) {
      if (name != 'Chi tiêu') {
        excel.delete(name);
      }
    }

    return excel.encode()!;
  }

  // ─── IMPORT ───────────────────────────────────────────────

  /// Import expenses from an Excel file at [filePath].
  /// Returns an [ImportResult] with valid expenses and error count.
  Future<ImportResult> importFromFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final expenses = <ExpenseModel>[];
    final errors = <String>[];

    // Use the first sheet
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;

    // Skip header row (row 0)
    for (var rowIdx = 1; rowIdx < sheet.maxRows; rowIdx++) {
      try {
        final row = sheet.row(rowIdx);
        if (row.isEmpty || _isEmptyRow(row)) continue;

        final expense = _parseRow(row, rowIdx);
        if (expense != null) {
          expenses.add(expense);
        } else {
          errors.add('Dòng ${rowIdx + 1}: Không thể đọc dữ liệu');
        }
      } catch (e) {
        errors.add('Dòng ${rowIdx + 1}: $e');
      }
    }

    return ImportResult(
      expenses: expenses,
      errorCount: errors.length,
      errors: errors,
    );
  }

  bool _isEmptyRow(List<Data?> row) {
    return row.every(
      (cell) =>
          cell == null ||
          cell.value == null ||
          cell.value.toString().trim().isEmpty,
    );
  }

  /// Parse a single row into an [ExpenseModel].
  /// Expected column order: STT, Tiêu đề, Số tiền, Loại, Danh mục, Ngày, Ghi chú
  ExpenseModel? _parseRow(List<Data?> row, int rowIdx) {
    // Need at least columns 1-5 (title, amount, type, category, date)
    if (row.length < 6) return null;

    // Title (column 1)
    final title = _cellString(row, 1);
    if (title.isEmpty) return null;

    // Amount (column 2) — handle both number and formatted string
    final amount = _parseAmount(row, 2);
    if (amount == null || amount <= 0) return null;

    // Type (column 3)
    final typeStr = _cellString(row, 3).toLowerCase().trim();
    TransactionType type;
    if (typeStr.contains('thu') || typeStr == 'income') {
      type = TransactionType.income;
    } else {
      type = TransactionType.expense;
    }

    // Category (column 4)
    final categoryLabel = _cellString(row, 4).trim();
    final category = _parseCategory(categoryLabel);

    // Date (column 5)
    final date = _parseDate(row, 5);
    if (date == null) return null;

    // Note (column 6, optional)
    final note = row.length > 6 ? _cellString(row, 6) : '';

    return ExpenseModel(
      title: title,
      amount: amount,
      category: category,
      date: date,
      note: note.isNotEmpty ? note : null,
      type: type,
    );
  }

  String _cellString(List<Data?> row, int col) {
    if (col >= row.length || row[col] == null || row[col]!.value == null) {
      return '';
    }
    return row[col]!.value.toString().trim();
  }

  double? _parseAmount(List<Data?> row, int col) {
    final raw = _cellString(row, col);
    if (raw.isEmpty) return null;

    // Remove thousand separators (dot, comma, space) and parse
    final cleaned = raw
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('đ', '')
        .replaceAll('₫', '')
        .trim();

    return double.tryParse(cleaned);
  }

  DateTime? _parseDate(List<Data?> row, int col) {
    final raw = _cellString(row, col);
    if (raw.isEmpty) return null;

    // Try dd/MM/yyyy
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(raw);
    } catch (_) {}

    // Try yyyy-MM-dd
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(raw);
    } catch (_) {}

    // Try ISO 8601
    return DateTime.tryParse(raw);
  }

  /// Map Vietnamese category label to [ExpenseCategory].
  ExpenseCategory _parseCategory(String label) {
    if (label.isEmpty) return ExpenseCategory.other;

    final lower = label.toLowerCase();
    for (final cat in ExpenseCategory.values) {
      if (cat.label.toLowerCase() == lower || cat.name.toLowerCase() == lower) {
        return cat;
      }
    }
    return ExpenseCategory.other;
  }
}
