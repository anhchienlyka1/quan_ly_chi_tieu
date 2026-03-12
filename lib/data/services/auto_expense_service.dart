import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/bank_notification_model.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import 'bank_notification_parser.dart';
import 'local_storage_service.dart';
import 'transaction_categorizer_service.dart';

/// Callback chạy ở background isolate khi có notification mới.
/// PHẢI là top-level function và có annotation @pragma('vm:entry-point')
@pragma('vm:entry-point')
void onNotificationReceived(NotificationEvent event) async {
  // 1. Forward to UI Isolate if running
  try {
    final SendPort? send = IsolateNameServer.lookupPortByName(
      NotificationsListener.SEND_PORT_NAME,
    );
    send?.send(event);
  } catch (e) {
    debugPrint('⚠️ Error sending to UI isolate: $e');
  }

  // 2. Filter nhanh
  final packageName = event.packageName ?? '';
  if (!BankNotificationParser.isBankNotification(packageName)) return;

  // Plugin flutter_notification_listener thường gửi event khi có noti.

  try {
    // 2. Init SharedPreferences
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();

    // 3. Parse Notification
    final parsed = BankNotificationParser.parseNotification(
      packageName: packageName,
      title: event.title ?? '',
      content: event.text ?? '', // Changed from .content to .text
    );

    if (parsed == null) return;

    // 4. Load pending list cũ
    final historyJson = prefs.getString('auto_expense_history') ?? '[]';
    List<BankNotificationModel> pendingNotifications = [];
    try {
      final List<dynamic> jsonList = jsonDecode(historyJson);
      pendingNotifications = jsonList
          .map(
            (json) =>
                BankNotificationModel.fromMap(json as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      pendingNotifications = [];
    }

    // 5. CHeck Duplicate
    final isDuplicate = pendingNotifications.any((n) {
      final timeDiff = n.timestamp.difference(parsed.timestamp).inSeconds.abs();
      return n.amount == parsed.amount &&
          n.isIncoming == parsed.isIncoming &&
          timeDiff < 60;
    });

    if (isDuplicate) return;

    // 6. Thêm vào list (mặc định chưa có AI category, sẽ xử lý khi mở app hoặc nếu config được AI background sau này)
    // Lưu ý: TransactionCategorizerService cần API Key, ở background có thể không lấy được từ user preferences an toàn hoặc phức tạp.
    // Tạm thời lưu raw, khi mở app User sẽ thấy transaction.
    // Hoặc nếu muốn tốt hơn: instance TransactionCategorizerService ở đây nếu có thể.

    // Fallback category logic đơn giản cho background (keyword)
    // Vì TransactionCategorizerService có logic fallback keyword, ta có thể dùng nó.
    // Tuy nhiên TransactionCategorizerService setup hơi phức tạp với Singleton.
    // Ta copy logic basic hoặc chấp nhận category 'other' lúc đầu.

    // 5b. Internal Transfer Check (Link & Merge)
    int matchIndex = -1;
    for (int i = 0; i < pendingNotifications.length; i++) {
      final item = pendingNotifications[i];

      // Time diff < 120s
      if (item.timestamp.difference(parsed.timestamp).inSeconds.abs() > 120) {
        continue;
      }

      // Check criteria: Same amount, Opposite direction, Unlinked
      if (item.amount == parsed.amount &&
          item.isIncoming != parsed.isIncoming &&
          item.linkedTransactionId == null) {
        matchIndex = i;
        break;
      }
    }

    if (matchIndex != -1) {
      // Merge found!
      final existing = pendingNotifications[matchIndex];
      debugPrint(
        '🔗 [Background] Internal transfer detected: $packageName <-> ${existing.packageName}',
      );

      final merged = existing.copyWith(
        linkedTransactionId: parsed.id,
        parsedTitle: 'Chuyển tiền nội bộ',
        category: ExpenseCategory.other,
        // Keep timestamp of older or newer? Usually keep first one.
      );
      pendingNotifications[matchIndex] = merged;
    } else {
      // No match -> Standard Insert
      pendingNotifications.insert(
        0,
        parsed.copyWith(
          parsedTitle: parsed.isIncoming ? 'Nhận tiền' : 'Chuyển tiền',
        ),
      );
    }

    // Limit 50
    if (pendingNotifications.length > 50) {
      pendingNotifications = pendingNotifications.sublist(0, 50);
    }

    // 7. Save back
    final newJsonList = pendingNotifications.map((n) => n.toMap()).toList();
    await prefs.setString('auto_expense_history', jsonEncode(newJsonList));

    debugPrint('💾 [Background] Saved transaction: ${parsed.amount}');
  } catch (e) {
    debugPrint('❌ [Background] Error: $e');
  }
}

/// Service tổng hợp: lắng nghe notification ngân hàng → parse → AI categorize → ghi chi tiêu.
/// Hỗ trợ chạy ngầm trên Android nhờ `flutter_notification_listener`.
class AutoExpenseService with WidgetsBindingObserver {
  static AutoExpenseService? _instance;

  final ExpenseRepository _expenseRepository = ExpenseRepository();
  LocalStorageService? _storage;
  TransactionCategorizerService? _categorizer;
  StreamSubscription? _notificationSubscription;

  List<BankNotificationModel> _pendingNotifications = [];
  bool _isListening = false;

  // Stream controller to broadcast new notifications to UI
  final _notificationStreamController =
      StreamController<BankNotificationModel>.broadcast();
  Stream<BankNotificationModel> get notificationStream =>
      _notificationStreamController.stream;

  AutoExpenseService._();

  static Future<AutoExpenseService> getInstance() async {
    if (_instance == null) {
      _instance = AutoExpenseService._();
      await _instance!._init();
    }
    return _instance!;
  }

  static AutoExpenseService? get instance => _instance;

  Future<void> _init() async {
    WidgetsBinding.instance.addObserver(this); // Listen to app lifecycle

    _storage = await LocalStorageService.getInstance();
    _categorizer = await TransactionCategorizerService.getInstance();
    _loadHistory();

    // Remove any legacy mock data that might be persisted
    _pendingNotifications.removeWhere((n) => n.id.startsWith('mock_'));
    _saveHistory();

    // Auto-start if enabled (only on Android)
    if (isSupported && _storage?.isAutoExpenseEnabled() == true) {
      await startListening();
    }
  }

  /// App resume -> reload data từ SharedPreferences (do background isolate có thể đã update)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed, reloading notifications from storage...');
      _loadHistory();
      // Notify listeners (UI) that list might have changed
      _notificationStreamController.add(
        BankNotificationModel(
          id: 's',
          bankName: '',
          packageName: '',
          amount: 0,
          isIncoming: false,
          rawContent: '',
          timestamp: DateTime.now(),
        ),
      ); // Dummy event to trigger stream? Or better: UI should invoke refresh
      // Actually, standard StreamBuilder might not update list if list reference changed?
      // Better ensure the getter returns the new list.
    }
  }

  bool get isListening => _isListening;
  bool get isEnabled => _storage?.isAutoExpenseEnabled() ?? false;
  bool get isAIConfigured => _categorizer?.isConfigured ?? false;
  bool get isSupported => !kIsWeb && Platform.isAndroid; // Android-only plugin
  List<BankNotificationModel> get pendingNotifications => List.unmodifiable(
    _pendingNotifications.where((n) => !n.isAutoRecorded).toList(),
  );
  List<BankNotificationModel> get allNotifications =>
      List.unmodifiable(_pendingNotifications);

  /// Kiểm tra quyền notification access
  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      final bool? isGranted = await NotificationsListener.hasPermission;
      return isGranted ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Yêu cầu cấp quyền notification access
  Future<void> requestPermission() async {
    if (!isSupported) return;
    try {
      await NotificationsListener.openPermissionSettings();
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
    }
  }

  /// Bật tính năng và bắt đầu lắng nghe
  Future<bool> enable() async {
    if (kIsWeb) return false;

    // Open settings to let user enable
    await requestPermission();

    await _storage?.setAutoExpenseEnabled(true);
    await startListening();
    return true;
  }

  /// Tắt tính năng
  Future<void> disable() async {
    await _storage?.setAutoExpenseEnabled(false);
    stopListening();
  }

  /// Bắt đầu lắng nghe notification
  Future<void> startListening() async {
    if (_isListening || !isSupported) return;

    try {
      // Register background callback
      await NotificationsListener.initialize(
        callbackHandle: onNotificationReceived,
      );

      // Listen to ReceivePort for foreground updates
      // Note: receivePort might require re-registration if isolate changed, but plugin handles it.
      _notificationSubscription = NotificationsListener.receivePort?.listen((
        event,
      ) {
        if (event is NotificationEvent) {
          _onForegroundNotificationInternal(event);
        }
      });

      // Start service (HEADLESS support)
      await NotificationsListener.startService(
        title: "Quản lý chi tiêu",
        description: "Đang lắng nghe giao dịch...",
      );

      _isListening = true;
      debugPrint(
        '✅ Auto-expense listener started (flutter_notification_listener)',
      );
    } catch (e) {
      debugPrint('❌ Failed to start notification listener: $e');
      _isListening = false;
    }
  }

  /// Dừng lắng nghe
  Future<void> stopListening() async {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    if (isSupported) await NotificationsListener.stopService();
    _isListening = false;
    debugPrint('🛑 Auto-expense listener stopped');
  }

  /// Xử lý notification nhận được qua Port (Foreground/Background active)
  Future<void> _onForegroundNotificationInternal(
    NotificationEvent event,
  ) async {
    // Background callback (isolate) đã xử lý việc lưu vào SharedPreferences.
    // Ở đây ta chỉ cần reload dữ liệu để UI cập nhật.

    final String packageName = event.packageName ?? '';
    if (!BankNotificationParser.isBankNotification(packageName)) return;

    debugPrint('🏦 [Foreground] Bank notification event received');
    _loadHistory();

    // Notify UI to refresh
    _notificationStreamController.add(
      BankNotificationModel(
        id: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
        bankName: '',
        packageName: '',
        amount: 0,
        isIncoming: false,
        rawContent: '',
        timestamp: DateTime.now(),
      ),
    );
  }

  /// User chấp nhận giao dịch → lưu vào chi tiêu
  Future<bool> acceptTransaction(String id) async {
    final index = _pendingNotifications.indexWhere((n) => n.id == id);
    if (index == -1) return false;

    final notification = _pendingNotifications[index];
    try {
      var expense = notification.toExpenseModel();

      // Handle Internal Transfer: Amount = 0
      if (notification.linkedTransactionId != null) {
        expense = expense.copyWith(
          amount: 0,
          type: TransactionType.expense, // Or keep as is, effectively 0
          note:
              '${expense.note}\n(Chuyển khoản nội bộ: ${notification.amount.toCurrency})',
        );
      }

      await _expenseRepository.addExpense(expense);

      if (_storage != null) {
        double currentBalance = _storage!.getTotalBalance();
        double newBalance;

        if (notification.balance != null) {
          // Trust SMS balance if available
          newBalance = notification.balance!;
        } else {
          // If internal transfer -> No change (amount 0 effect)
          if (notification.linkedTransactionId != null) {
            newBalance = currentBalance;
          } else {
            newBalance = notification.isIncoming
                ? currentBalance + notification.amount
                : currentBalance - notification.amount;
          }
        }
        await _storage!.setTotalBalance(newBalance);
      }

      _pendingNotifications[index] = notification.copyWith(
        isAutoRecorded: true,
      );
      _saveHistory();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to accept: $e');
      return false;
    }
  }

  /// User từ chối giao dịch → xóa khỏi danh sách
  void rejectTransaction(String id) {
    _pendingNotifications.removeWhere((n) => n.id == id);
    _saveHistory();
  }

  /// Xóa một notification khỏi lịch sử
  void removeNotification(String id) {
    _pendingNotifications.removeWhere((n) => n.id == id);
    _saveHistory();
  }

  /// Xóa toàn bộ lịch sử
  void clearHistory() {
    _pendingNotifications.clear();
    _saveHistory();
  }

  /// Lưu lịch sử vào SharedPreferences
  void _saveHistory() {
    final jsonList = _pendingNotifications.map((n) => n.toMap()).toList();
    _storage?.setAutoExpenseHistory(jsonEncode(jsonList));
  }

  /// Load lịch sử từ SharedPreferences
  void _loadHistory() {
    final historyJson = _storage?.getAutoExpenseHistory() ?? '[]';
    try {
      final List<dynamic> jsonList = jsonDecode(historyJson);
      _pendingNotifications = jsonList
          .map(
            (json) =>
                BankNotificationModel.fromMap(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading notification history: $e');
      _pendingNotifications = [];
    }
  }

  /// Generate mock data for testing UI
  void generateMockData() {
    final now = DateTime.now();
    final mocks = [
      BankNotificationModel(
        id: 'mock_${now.millisecondsSinceEpoch}_1',
        bankName: 'Vietcombank',
        packageName: 'com.VCB.MobileBanking',
        amount: 15500000,
        isIncoming: true,
        rawContent: 'NHAN LUONG THANG 01/2026',
        parsedTitle: 'Lương tháng 01/2026',
        category: ExpenseCategory.salary,
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
      BankNotificationModel(
        id: 'mock_${now.millisecondsSinceEpoch}_2',
        bankName: 'Techcombank',
        packageName: 'com.techcombank.mobile',
        amount: 55000,
        isIncoming: false,
        rawContent: 'Thanh toan HighLand Coffee Tai Ha Noi',
        parsedTitle: 'Cafe Highland',
        category: ExpenseCategory.food,
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
    ];

    _pendingNotifications.insertAll(0, mocks);
    _saveHistory();
    for (var mock in mocks) {
      _notificationStreamController.add(mock);
    }
  }

  /// Dispose resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopListening();
    _notificationStreamController.close();
  }
}
