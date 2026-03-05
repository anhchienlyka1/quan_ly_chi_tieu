import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_chi_tieu/data/services/intent_classifier_service.dart';

void main() {
  group('IntentClassifierService Tests', () {
    test('classify "thêm chi tiêu" -> addExpense', () {
      expect(
        IntentClassifierService.classify('tôi muốn thêm chi tiêu'),
        IntentType.addExpense,
      );
      expect(
        IntentClassifierService.classify('ghi chi tiêu cho tớ'),
        IntentType.addExpense,
      );
      expect(
        IntentClassifierService.classify('tốn tiền quá'),
        IntentType.addExpense,
      );
      expect(
        IntentClassifierService.classify('vừa chi 50k vào trà sữa'),
        IntentType.addExpense,
      );
    });

    test('classify "đặt ngân sách" -> setBudget', () {
      expect(
        IntentClassifierService.classify('đặt ngân sách tháng này là 5tr'),
        IntentType.setBudget,
      );
      expect(
        IntentClassifierService.classify('thiết lập ngân sách mới đi'),
        IntentType.setBudget,
      );
      expect(
        IntentClassifierService.classify('chỉnh budget giùm mình'),
        IntentType.setBudget,
      );
    });

    test('classify "xem thống kê" -> showStats', () {
      expect(
        IntentClassifierService.classify('xem thống kê tháng này'),
        IntentType.showStats,
      );
      expect(
        IntentClassifierService.classify('báo cáo tuần qua thế nào'),
        IntentType.showStats,
      );
      expect(
        IntentClassifierService.classify('vẽ biểu đồ cho tôi xem'),
        IntentType.showStats,
      );
    });

    test('classify "lịch sử giao dịch" -> viewExpenses', () {
      expect(
        IntentClassifierService.classify('xem giao dịch gần đây'),
        IntentType.viewExpenses,
      );
      expect(
        IntentClassifierService.classify('xem danh sách chi tiêu'),
        IntentType.viewExpenses,
      );
      expect(
        IntentClassifierService.classify('lịch sử chi tiêu tháng này'),
        IntentType.viewExpenses,
      );
    });

    test('classify "thời tiết hôm nay" -> query (fallback)', () {
      expect(
        IntentClassifierService.classify('hôm nay trời có mưa không?'),
        IntentType.query,
      );
      expect(
        IntentClassifierService.classify('bạn biết gì về chứng khoán?'),
        IntentType.query,
      );
      expect(IntentClassifierService.classify('hello bạn'), IntentType.query);
    });
  });
}
