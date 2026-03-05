import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/expense_repository.dart';
import '../models/expense_model.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "budgetCheckTask") {
      try {
        final prefs = await SharedPreferences.getInstance();

        // ── Read real budget from SharedPreferences ──
        final monthlyBudget = prefs.getDouble('monthly_budget') ?? 0.0;
        if (monthlyBudget <= 0) {
          print("⏭️ Background: No budget set, skipping check.");
          return true;
        }

        // ── Read real expenses from local datasource ──
        final repository = ExpenseRepository();
        final now = DateTime.now();
        final expenses = await repository.getExpensesByMonth(
          now.year,
          now.month,
        );

        // ── Calculate weekly stats ──
        final weeklyBudget = monthlyBudget / 4;
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );

        final thisWeekExpenses = expenses.where(
          (e) =>
              e.type == TransactionType.expense &&
              e.date.isAfter(
                startOfWeekDate.subtract(const Duration(seconds: 1)),
              ),
        );

        final thisWeekTotal = thisWeekExpenses.fold<double>(
          0,
          (s, e) => s + e.amount,
        );

        final percentUsed = weeklyBudget > 0
            ? ((thisWeekTotal / weeklyBudget) * 100).round()
            : 0;
        final daysRemaining = 7 - now.weekday;

        // ── Initialize notification service ──
        final notificationService = NotificationService();
        await notificationService.initialize();

        // ── Send notification based on threshold ──
        if (thisWeekTotal > weeklyBudget) {
          // 🔴 Exceeded weekly budget
          await notificationService.showBudgetOverAlert(
            spent: thisWeekTotal,
            budget: weeklyBudget,
          );
          print(
            "🔴 Background: Budget EXCEEDED — Spent: $thisWeekTotal / Budget: $weeklyBudget",
          );
        } else if (percentUsed >= 80) {
          // 🟠 Near weekly budget (>= 80%)
          await notificationService.showBudgetNearAlert(
            percentUsed: percentUsed,
            daysRemaining: daysRemaining,
          );
          print(
            "🟠 Background: Budget WARNING — $percentUsed% used, $daysRemaining days left",
          );
        } else if (percentUsed < 50 && thisWeekTotal > 0) {
          // 🎉 Good saving behavior
          await notificationService.showSavingRewardAlert(
            saved: weeklyBudget - thisWeekTotal,
          );
          print("🎉 Background: Saving reward — only $percentUsed% used!");
        } else {
          print(
            "✅ Background: Normal — $percentUsed% used, no notification needed.",
          );
        }
      } catch (err) {
        print("❌ Background task error: $err");
      }
    }
    return Future.value(true);
  });
}
