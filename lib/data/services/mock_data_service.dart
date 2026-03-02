import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../repositories/expense_repository.dart';
import 'local_storage_service.dart';
import 'budget_service.dart';

/// Mock data seeder — tạo dữ liệu thu chi đa dạng để test các trigger AI.
/// Gọi MockDataService.seedAll() để chèn data + thiết lập ngân sách.
class MockDataService {
  static final ExpenseRepository _repo = ExpenseRepository();

  /// Seed tất cả mock data + ngân sách
  static Future<void> seedAll() async {
    // Xóa data cũ
    await _repo.deleteAllData();

    // Thiết lập ngân sách: 3.5tr/tháng
    final budgetService = BudgetService();
    await budgetService.saveBudget(BudgetModel.forCurrentMonth(
      totalBudget: 3500000,
      categoryBudgets: {
        ExpenseCategory.food: 1200000,      // 1.2tr ăn uống
        ExpenseCategory.transport: 500000,   // 500k di chuyển
        ExpenseCategory.shopping: 800000,    // 800k mua sắm
        ExpenseCategory.entertainment: 300000, // 300k giải trí
        ExpenseCategory.bills: 500000,       // 500k hóa đơn
      },
    ));

    // Set balance
    final storage = await LocalStorageService.getInstance();
    await storage.setTotalBalance(8500000);

    final now = DateTime.now();

    // ─── THU NHẬP ─────────────────────────────────────────────────
    await _addIncome('Lương tháng ${now.month}', 9000000, ExpenseCategory.salary,
        DateTime(now.year, now.month, 1));
    await _addIncome('Thưởng project', 2000000, ExpenseCategory.bonus,
        DateTime(now.year, now.month, 5));
    await _addIncome('Freelance design', 1500000, ExpenseCategory.salary,
        DateTime(now.year, now.month, 15));

    // ─── TUẦN TRƯỚC (chi bình thường ~600k) ─────────────────────
    final lastMonday = now.subtract(Duration(days: now.weekday - 1 + 7));
    await _addExpense('Cơm trưa VP', 35000, ExpenseCategory.food,
        lastMonday);
    await _addExpense('Grab đi làm', 45000, ExpenseCategory.transport,
        lastMonday.add(const Duration(days: 0)));
    await _addExpense('Cà phê Highlands', 49000, ExpenseCategory.food,
        lastMonday.add(const Duration(days: 1)));
    await _addExpense('Phở Thìn', 55000, ExpenseCategory.food,
        lastMonday.add(const Duration(days: 1)));
    await _addExpense('Xăng xe', 120000, ExpenseCategory.transport,
        lastMonday.add(const Duration(days: 2)));
    await _addExpense('Bánh mì', 25000, ExpenseCategory.food,
        lastMonday.add(const Duration(days: 2)));
    await _addExpense('Trà sữa Gong Cha', 55000, ExpenseCategory.food,
        lastMonday.add(const Duration(days: 3)));
    await _addExpense('Bida với bạn', 80000, ExpenseCategory.entertainment,
        lastMonday.add(const Duration(days: 4)));
    await _addExpense('Cơm tấm', 40000, ExpenseCategory.food,
        lastMonday.add(const Duration(days: 5)));
    await _addExpense('Rau củ quả', 85000, ExpenseCategory.food,
        lastMonday.add(const Duration(days: 6)));

    // ─── TUẦN NÀY (chi cao ~1.4tr → vượt ngân sách tuần 875k) ──
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));

    // Ngày 1 (Thứ 2)
    await _addExpense('Cơm trưa VP', 40000, ExpenseCategory.food,
        thisMonday);
    await _addExpense('Grab đi họp', 75000, ExpenseCategory.transport,
        thisMonday);

    // Ngày 2 (Thứ 3) — mua sắm bất thường  
    await _addExpense('Quần áo Uniqlo', 450000, ExpenseCategory.shopping,
        thisMonday.add(const Duration(days: 1)));
    await _addExpense('Phở bò', 55000, ExpenseCategory.food,
        thisMonday.add(const Duration(days: 1)));
    await _addExpense('Cà phê The Coffee House', 59000, ExpenseCategory.food,
        thisMonday.add(const Duration(days: 1)));

    // Ngày 3 (Thứ 4)
    await _addExpense('Tiền điện tháng ${now.month}', 350000, ExpenseCategory.bills,
        thisMonday.add(const Duration(days: 2)));
    await _addExpense('Cơm trưa', 35000, ExpenseCategory.food,
        thisMonday.add(const Duration(days: 2)));
    await _addExpense('Grab về nhà', 55000, ExpenseCategory.transport,
        thisMonday.add(const Duration(days: 2)));

    // Ngày 4+ (nếu đã qua)
    if (now.weekday > 3) {
      await _addExpense('Lẩu nhóm bạn', 180000, ExpenseCategory.food,
          thisMonday.add(const Duration(days: 3)));
      await _addExpense('Xem phim CGV', 120000, ExpenseCategory.entertainment,
          thisMonday.add(const Duration(days: 3)));
      await _addExpense('Bắp nước rạp', 60000, ExpenseCategory.food,
          thisMonday.add(const Duration(days: 3)));
    }
    if (now.weekday > 4) {
      await _addExpense('Sách lập trình', 250000, ExpenseCategory.education,
          thisMonday.add(const Duration(days: 4)));
      await _addExpense('Cơm gà', 45000, ExpenseCategory.food,
          thisMonday.add(const Duration(days: 4)));
    }
    if (now.weekday > 5) {
      await _addExpense('Siêu thị tuần', 380000, ExpenseCategory.food,
          thisMonday.add(const Duration(days: 5)));
      await _addExpense('Kem Baskin Robbins', 89000, ExpenseCategory.food,
          thisMonday.add(const Duration(days: 5)));
    }

    // ─── ĐẦU THÁNG (thêm data các tuần trước nữa) ──────────────
    if (now.day > 14) {
      final week3Ago = lastMonday.subtract(const Duration(days: 7));
      await _addExpense('Tiền nước', 150000, ExpenseCategory.bills,
          week3Ago);
      await _addExpense('Internet', 220000, ExpenseCategory.bills,
          week3Ago.add(const Duration(days: 1)));
      await _addExpense('Ăn buffet', 299000, ExpenseCategory.food,
          week3Ago.add(const Duration(days: 2)));
      await _addExpense('Grab tuần', 180000, ExpenseCategory.transport,
          week3Ago.add(const Duration(days: 3)));
      await _addExpense('Khám bệnh', 500000, ExpenseCategory.health,
          week3Ago.add(const Duration(days: 4)));
      await _addExpense('Thuốc', 150000, ExpenseCategory.health,
          week3Ago.add(const Duration(days: 4)));
    }

    print('✅ Mock data seeded successfully!');
  }

  static Future<void> _addExpense(
    String title, double amount, ExpenseCategory category, DateTime date,
  ) async {
    await _repo.addExpense(ExpenseModel(
      title: title,
      amount: amount,
      category: category,
      date: date,
      type: TransactionType.expense,
    ));
  }

  static Future<void> _addIncome(
    String title, double amount, ExpenseCategory category, DateTime date,
  ) async {
    await _repo.addExpense(ExpenseModel(
      title: title,
      amount: amount,
      category: category,
      date: date,
      type: TransactionType.income,
    ));
  }
}
