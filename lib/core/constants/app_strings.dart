/// App-wide string constants.
/// Centralized to support future localization (i18n).
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Quản Lý Chi Tiêu';

  // Navigation
  static const String home = 'Trang chủ';
  static const String expenses = 'Chi tiêu';
  static const String statistics = 'Thống kê';
  static const String settings = 'Cài đặt';

  // Expense
  static const String addExpense = 'Thêm chi tiêu';
  static const String editExpense = 'Sửa chi tiêu';
  static const String deleteExpense = 'Xóa chi tiêu';
  static const String expenseAmount = 'Số tiền';
  static const String expenseCategory = 'Danh mục';
  static const String expenseNote = 'Ghi chú';
  static const String expenseDate = 'Ngày';

  // Categories
  static const String categoryFood = 'Ăn uống';
  static const String categoryTransport = 'Di chuyển';
  static const String categoryShopping = 'Mua sắm';
  static const String categoryEntertainment = 'Giải trí';
  static const String categoryHealth = 'Sức khỏe';
  static const String categoryEducation = 'Giáo dục';
  static const String categoryBills = 'Hóa đơn';
  static const String categoryOther = 'Khác';

  // Summary
  static const String totalExpense = 'Tổng chi tiêu';
  static const String totalIncome = 'Tổng thu nhập';
  static const String balance = 'Số dư';
  static const String thisMonth = 'Tháng này';
  static const String thisWeek = 'Tuần này';
  static const String today = 'Hôm nay';

  // Actions
  static const String save = 'Lưu';
  static const String cancel = 'Hủy';
  static const String delete = 'Xóa';
  static const String edit = 'Sửa';
  static const String confirm = 'Xác nhận';

  // Messages
  static const String deleteConfirm = 'Bạn có chắc chắn muốn xóa?';
  static const String saveSuccess = 'Lưu thành công!';
  static const String deleteSuccess = 'Xóa thành công!';
  static const String noExpenses = 'Chưa có chi tiêu nào';
  static const String errorOccurred = 'Đã có lỗi xảy ra';
}
