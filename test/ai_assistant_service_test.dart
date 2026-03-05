import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quan_ly_chi_tieu/data/services/ai_assistant_service.dart';
import 'package:quan_ly_chi_tieu/data/models/expense_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  group('AiAssistantService Tests', () {
    late AiAssistantService service;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({'gemini_api_key': 'mock_key'});
    });

    setUp(() async {
      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {}
      service = await AiAssistantService.getInstance();
    });

    test('parseActionsFromText extracts actions correctly', () {
      final actions1 = service.parseActionsFromText(
        'bạn nên thiết lập ngân sách nhé',
      );
      expect(actions1.contains(AiAction.setBudget), isTrue);

      final actions2 = service.parseActionsFromText(
        'bạn hãy thêm chi tiêu ngay đi',
      );
      expect(actions2.contains(AiAction.addExpense), isTrue);

      final actions3 = service.parseActionsFromText('xem thống kê của tôi');
      expect(actions3.contains(AiAction.showStats), isTrue);

      final actions4 = service.parseActionsFromText('xem danh sách chi tiêu');
      expect(actions4.contains(AiAction.viewExpenses), isTrue);
    });

    test('detectTopTrigger identifies correct trigger', () {
      final triggerNormal = service.detectTopTrigger(
        expenses: [
          ExpenseModel(
            id: '1',
            title: 'Normal',
            amount: 10000,
            date: DateTime.now(),
            category: ExpenseCategory.food,
            type: TransactionType.expense,
          ),
        ],
        monthlyBudget: 10000000,
        categoryBudgets: {},
      );
      expect(triggerNormal.type, 'normal');

      // Test budget near threshold
      final triggerWarning = service.detectTopTrigger(
        expenses: [
          ExpenseModel(
            id: '1',
            title: 'Test',
            amount: 2200000,
            date: DateTime.now(),
            category: ExpenseCategory.other,
            type: TransactionType.expense,
          ),
        ],
        monthlyBudget: 10000000,
        categoryBudgets: {},
      );
      expect(triggerWarning.type, 'near_budget');

      // Test budget exceeded
      final triggerAlert = service.detectTopTrigger(
        expenses: [
          ExpenseModel(
            id: '1',
            title: 'Test',
            amount: 3000000,
            date: DateTime.now(),
            category: ExpenseCategory.other,
            type: TransactionType.expense,
          ),
        ],
        monthlyBudget: 10000000,
        categoryBudgets: {},
      );
      expect(triggerAlert.type, 'over_budget');
    });

    test('getWeeklyStats logic works correctly', () {
      final now = DateTime.now();
      // Add expense for this week
      final thisWeekDate = now;
      // Add expense for last week
      final lastWeekDate = now.subtract(const Duration(days: 7));

      final stats = service.getWeeklyStats([
        ExpenseModel(
          id: '1',
          title: 'This week',
          amount: 50000,
          date: thisWeekDate,
          category: ExpenseCategory.food,
          type: TransactionType.expense,
        ),
        ExpenseModel(
          id: '2',
          title: 'This week',
          amount: 100000,
          date: thisWeekDate,
          category: ExpenseCategory.food,
          type: TransactionType.expense,
        ),
        ExpenseModel(
          id: '3',
          title: 'Last week',
          amount: 200000,
          date: lastWeekDate,
          category: ExpenseCategory.transport,
          type: TransactionType.expense,
        ),
        ExpenseModel(
          id: '4',
          title: 'Income',
          amount: 500000,
          date: thisWeekDate,
          category: ExpenseCategory.salary,
          type: TransactionType.income,
        ), // should be ignored
      ]);

      expect(stats['thisWeekTotal'], 150000.0);
      expect(stats['lastWeekTotal'], 200000.0);
    });

    test('buildSpendingForecast computes string with values', () {
      final spent = 500000.0;
      final budget = 2000000.0;
      final now = DateTime(2023, 10, 15);

      final forecast = service.buildSpendingForecast(spent, budget, now);

      expect(forecast, isNotEmpty);
      expect(forecast.toLowerCase().contains('dự kiến'), isTrue);
    });
  });
}
