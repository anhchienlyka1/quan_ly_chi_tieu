import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import 'budget_service.dart';
import 'local_storage_service.dart';

/// Mock data seeder — tạo dữ liệu thu chi đa dạng để test các trigger AI.
/// Gọi MockDataService.seedAll() để chèn data + thiết lập ngân sách.
class MockDataService {
  static const String _storageKey = 'expenses_data';

  /// Seed tất cả mock data + ngân sách
  static Future<void> seedAll() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // ─── THIẾT LẬP NGÂN SÁCH 3.5tr ─────────────────────────────
    final budgetService = BudgetService();
    await budgetService.saveBudget(BudgetModel.forCurrentMonth(
      totalBudget: 3500000,
      categoryBudgets: {
        ExpenseCategory.food: 1200000,
        ExpenseCategory.transport: 500000,
        ExpenseCategory.shopping: 800000,
        ExpenseCategory.entertainment: 300000,
        ExpenseCategory.bills: 500000,
      },
    ));

    // Set balance
    final storage = await LocalStorageService.getInstance();
    await storage.setTotalBalance(8500000);

    // ─── BUILD ALL EXPENSES ─────────────────────────────────────
    final List<ExpenseModel> allExpenses = [];
    int idCounter = 1000;

    ExpenseModel makeExpense(String title, double amount, ExpenseCategory cat, DateTime date, TransactionType type) {
      idCounter++;
      return ExpenseModel(
        id: 'mock_$idCounter',
        title: title,
        amount: amount,
        category: cat,
        date: date,
        type: type,
      );
    }

    // ── THU NHẬP ──
    allExpenses.add(makeExpense('Lương tháng ${now.month}', 9000000, ExpenseCategory.salary,
        DateTime(now.year, now.month, 1), TransactionType.income));
    allExpenses.add(makeExpense('Thưởng project', 2000000, ExpenseCategory.bonus,
        DateTime(now.year, now.month, 5), TransactionType.income));
    allExpenses.add(makeExpense('Freelance design', 1500000, ExpenseCategory.salary,
        DateTime(now.year, now.month, 15, 9), TransactionType.income));

    // ── TUẦN TRƯỚC (chi bình thường ~600k) ──
    final lastMonday = now.subtract(Duration(days: now.weekday - 1 + 7));
    allExpenses.addAll([
      makeExpense('Cơm trưa VP', 35000, ExpenseCategory.food, lastMonday, TransactionType.expense),
      makeExpense('Grab đi làm', 45000, ExpenseCategory.transport, lastMonday.add(const Duration(hours: 2)), TransactionType.expense),
      makeExpense('Cà phê Highlands', 49000, ExpenseCategory.food, lastMonday.add(const Duration(days: 1)), TransactionType.expense),
      makeExpense('Phở Thìn', 55000, ExpenseCategory.food, lastMonday.add(const Duration(days: 1, hours: 4)), TransactionType.expense),
      makeExpense('Xăng xe', 120000, ExpenseCategory.transport, lastMonday.add(const Duration(days: 2)), TransactionType.expense),
      makeExpense('Bánh mì', 25000, ExpenseCategory.food, lastMonday.add(const Duration(days: 2, hours: 3)), TransactionType.expense),
      makeExpense('Trà sữa Gong Cha', 55000, ExpenseCategory.food, lastMonday.add(const Duration(days: 3)), TransactionType.expense),
      makeExpense('Bida với bạn', 80000, ExpenseCategory.entertainment, lastMonday.add(const Duration(days: 4)), TransactionType.expense),
      makeExpense('Cơm tấm', 40000, ExpenseCategory.food, lastMonday.add(const Duration(days: 5)), TransactionType.expense),
      makeExpense('Rau củ quả', 85000, ExpenseCategory.food, lastMonday.add(const Duration(days: 6)), TransactionType.expense),
    ]);

    // ── TUẦN NÀY (chi cao ~1.1tr+ → vượt ngân sách tuần 875k) ──
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    final thisMondayDate = DateTime(thisMonday.year, thisMonday.month, thisMonday.day, 8);

    // Ngày 1 (Thứ 2)
    allExpenses.addAll([
      makeExpense('Cơm trưa VP', 40000, ExpenseCategory.food, thisMondayDate, TransactionType.expense),
      makeExpense('Grab đi họp', 75000, ExpenseCategory.transport, thisMondayDate.add(const Duration(hours: 2)), TransactionType.expense),
    ]);

    // Ngày 2 (Thứ 3) — mua sắm bất thường
    allExpenses.addAll([
      makeExpense('Quần áo Uniqlo', 450000, ExpenseCategory.shopping, thisMondayDate.add(const Duration(days: 1)), TransactionType.expense),
      makeExpense('Phở bò', 55000, ExpenseCategory.food, thisMondayDate.add(const Duration(days: 1, hours: 3)), TransactionType.expense),
      makeExpense('Cà phê The Coffee House', 59000, ExpenseCategory.food, thisMondayDate.add(const Duration(days: 1, hours: 6)), TransactionType.expense),
    ]);

    // Ngày 3 (Thứ 4)
    allExpenses.addAll([
      makeExpense('Tiền điện tháng ${now.month}', 350000, ExpenseCategory.bills, thisMondayDate.add(const Duration(days: 2)), TransactionType.expense),
      makeExpense('Cơm trưa', 35000, ExpenseCategory.food, thisMondayDate.add(const Duration(days: 2, hours: 4)), TransactionType.expense),
      makeExpense('Grab về nhà', 55000, ExpenseCategory.transport, thisMondayDate.add(const Duration(days: 2, hours: 8)), TransactionType.expense),
    ]);

    // Các ngày tiếp theo (chỉ thêm nếu đã qua)
    if (now.weekday > 3) {
      allExpenses.addAll([
        makeExpense('Lẩu nhóm bạn', 180000, ExpenseCategory.food, thisMondayDate.add(const Duration(days: 3)), TransactionType.expense),
        makeExpense('Xem phim CGV', 120000, ExpenseCategory.entertainment, thisMondayDate.add(const Duration(days: 3, hours: 4)), TransactionType.expense),
        makeExpense('Bắp nước rạp', 60000, ExpenseCategory.food, thisMondayDate.add(const Duration(days: 3, hours: 5)), TransactionType.expense),
      ]);
    }
    if (now.weekday > 4) {
      allExpenses.addAll([
        makeExpense('Sách lập trình', 250000, ExpenseCategory.education, thisMondayDate.add(const Duration(days: 4)), TransactionType.expense),
        makeExpense('Cơm gà', 45000, ExpenseCategory.food, thisMondayDate.add(const Duration(days: 4, hours: 4)), TransactionType.expense),
      ]);
    }
    if (now.weekday > 5) {
      allExpenses.addAll([
        makeExpense('Siêu thị tuần', 380000, ExpenseCategory.food, thisMondayDate.add(const Duration(days: 5)), TransactionType.expense),
        makeExpense('Kem Baskin Robbins', 89000, ExpenseCategory.food, thisMondayDate.add(const Duration(days: 5, hours: 3)), TransactionType.expense),
      ]);
    }

    // ── ĐẦU THÁNG (tuần 3 trước) ──
    if (now.day > 14) {
      final week3Ago = lastMonday.subtract(const Duration(days: 7));
      allExpenses.addAll([
        makeExpense('Tiền nước', 150000, ExpenseCategory.bills, week3Ago, TransactionType.expense),
        makeExpense('Internet', 220000, ExpenseCategory.bills, week3Ago.add(const Duration(days: 1)), TransactionType.expense),
        makeExpense('Ăn buffet', 299000, ExpenseCategory.food, week3Ago.add(const Duration(days: 2)), TransactionType.expense),
        makeExpense('Grab tuần', 180000, ExpenseCategory.transport, week3Ago.add(const Duration(days: 3)), TransactionType.expense),
        makeExpense('Khám bệnh', 500000, ExpenseCategory.health, week3Ago.add(const Duration(days: 4)), TransactionType.expense),
        makeExpense('Thuốc', 150000, ExpenseCategory.health, week3Ago.add(const Duration(days: 4, hours: 2)), TransactionType.expense),
      ]);
    }

    // ─── BATCH SAVE (1 lần write duy nhất → nhanh + không trùng ID) ──
    final jsonString = jsonEncode(allExpenses.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, jsonString);

    print('✅ Mock data seeded: ${allExpenses.length} transactions');
  }
}
