import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/bank_notification_model.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import 'bank_notification_parser.dart';
import 'local_storage_service.dart';
import 'transaction_categorizer_service.dart';

/// Service tổng hợp: lắng nghe notification ngân hàng → parse → AI categorize → ghi chi tiêu.
/// Chỉ hoạt động trên Android (notification_listener_service không hỗ trợ iOS/Web).
class AutoExpenseService {
  static AutoExpenseService? _instance;
  
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  LocalStorageService? _storage;
  TransactionCategorizerService? _categorizer;
  StreamSubscription? _notificationSubscription;
  
  List<BankNotificationModel> _pendingNotifications = [];
  bool _isListening = false;

  // Stream controller to broadcast new notifications to UI
  final _notificationStreamController = StreamController<BankNotificationModel>.broadcast();
  Stream<BankNotificationModel> get notificationStream => _notificationStreamController.stream;
  
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
    _storage = await LocalStorageService.getInstance();
    _categorizer = await TransactionCategorizerService.getInstance();
    _loadHistory();

    // MOCK DATA: Generate sample data if empty to demonstrate UI
    if (_pendingNotifications.isEmpty) {
      _generateMockData();
    }

    // Auto-start if enabled (only on Android)
    if (!kIsWeb && _storage?.isAutoExpenseEnabled() == true) {
      await startListening();
    }
  }

  bool get isListening => _isListening;
  bool get isEnabled => _storage?.isAutoExpenseEnabled() ?? false;
  bool get isAIConfigured => _categorizer?.isConfigured ?? false;
  bool get isSupported => !kIsWeb; // Only Android supported
  List<BankNotificationModel> get pendingNotifications => List.unmodifiable(
    _pendingNotifications.where((n) => !n.isAutoRecorded).toList(),
  );
  List<BankNotificationModel> get allNotifications => List.unmodifiable(_pendingNotifications);

  /// Kiểm tra quyền notification access
  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    try {
      final notificationService = await _getNotificationService();
      if (notificationService == null) return false;
      return await notificationService.isPermissionGranted();
    } catch (e) {
      debugPrint('❌ Error checking notification permission: $e');
      return false;
    }
  }

  /// Yêu cầu cấp quyền notification access
  Future<void> requestPermission() async {
    if (kIsWeb) return;
    try {
      final notificationService = await _getNotificationService();
      await notificationService?.requestPermission();
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
    }
  }

  /// Bật tính năng và bắt đầu lắng nghe
  Future<bool> enable() async {
    if (kIsWeb) return false;
    
    // Check permission
    final hasAccess = await hasPermission();
    if (!hasAccess) {
      await requestPermission();
      // Check again after request
      final granted = await hasPermission();
      if (!granted) return false;
    }

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
    if (_isListening || kIsWeb) return;

    try {
      final notificationService = await _getNotificationService();
      if (notificationService == null) return;
      
      _notificationSubscription = notificationService.notificationsStream.listen(
        (event) => _onNotificationReceived(event),
        onError: (e) {
          debugPrint('❌ Notification stream error: $e');
        },
      );
      _isListening = true;
      debugPrint('✅ Auto-expense listener started');
    } catch (e) {
      debugPrint('❌ Failed to start notification listener: $e');
      _isListening = false;
    }
  }

  /// Dừng lắng nghe
  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _isListening = false;
    debugPrint('🛑 Auto-expense listener stopped');
  }

  /// Helper: lazy import notification_listener_service to avoid web build issues
  Future<_NotificationServiceWrapper?> _getNotificationService() async {
    try {
      return _NotificationServiceWrapper();
    } catch (e) {
      debugPrint('❌ notification_listener_service not available: $e');
      return null;
    }
  }

  /// Xử lý notification nhận được
  Future<void> _onNotificationReceived(dynamic event) async {
    final String packageName = event.packageName ?? '';
    final String title = event.title ?? '';
    final String content = event.content ?? '';
    
    // Bỏ qua nếu notification bị remove
    if (event.hasRemoved == true) return;

    // Chỉ xử lý notification từ app ngân hàng
    if (!BankNotificationParser.isBankNotification(packageName)) return;

    debugPrint('🏦 Bank notification detected: $packageName');
    debugPrint('   Title: $title');
    debugPrint('   Content: $content');

    // Parse notification
    final parsed = BankNotificationParser.parseNotification(
      packageName: packageName,
      title: title,
      content: content,
    );

    if (parsed == null) {
      debugPrint('⚠️ Could not parse bank notification');
      return;
    }

    // AI categorize
    try {
      final result = await _categorizer!.categorize(
        parsed.rawContent,
        isIncoming: parsed.isIncoming,
      );

      final categoryStr = result['category'] ?? 'other';
      final parsedTitle = result['title'] ?? parsed.rawContent;

      final categorized = parsed.copyWith(
        parsedTitle: parsedTitle,
        category: TransactionCategorizerService.mapCategory(
          categoryStr,
          parsed.isIncoming,
        ),
      );

      // Thêm vào danh sách chờ duyệt (KHÔNG tự động lưu)
      _addToPending(categorized);
    } catch (e) {
      debugPrint('❌ Error processing bank notification: $e');
      // Still add to pending with basic info
      final basicCategorized = parsed.copyWith(
        parsedTitle: parsed.rawContent,
      );
      _addToPending(basicCategorized);
    }
  }

  /// Thêm vào danh sách chờ duyệt
  void _addToPending(BankNotificationModel notification) {
    // Thêm vào đầu danh sách (isAutoRecorded = false = chờ duyệt)
    _pendingNotifications.insert(0, notification);
    
    // Giữ tối đa 50 giao dịch
    if (_pendingNotifications.length > 50) {
      _pendingNotifications = _pendingNotifications.sublist(0, 50);
    }

    // Lưu history
    _saveHistory();

    // Broadcast to UI
    _notificationStreamController.add(notification);

    debugPrint('📋 Added to pending: ${notification.parsedTitle} - ${notification.amount}');
  }

  /// User chấp nhận giao dịch → lưu vào chi tiêu
  Future<bool> acceptTransaction(String id) async {
    final index = _pendingNotifications.indexWhere((n) => n.id == id);
    if (index == -1) return false;

    final notification = _pendingNotifications[index];
    try {
      // Tạo expense model và lưu vào repository
      final expense = notification.toExpenseModel();
      await _expenseRepository.addExpense(expense);

      // --- Sync Balance ---
      if (_storage != null) {
        double currentBalance = _storage!.getTotalBalance();
        double newBalance;

        if (notification.balance != null) {
          newBalance = notification.balance!;
          debugPrint('🏦 Synced balance from notification: ${newBalance.toInt()}');
        } else {
          if (notification.isIncoming) {
            newBalance = currentBalance + notification.amount;
          } else {
            newBalance = currentBalance - notification.amount;
          }
          debugPrint('💰 Updated balance: ${newBalance.toInt()}');
        }
        await _storage!.setTotalBalance(newBalance);
      }

      // Đánh dấu đã duyệt
      _pendingNotifications[index] = notification.copyWith(isAutoRecorded: true);
      _saveHistory();

      debugPrint('✅ Accepted: ${notification.parsedTitle} - ${notification.amount}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to accept transaction: $e');
      return false;
    }
  }

  /// User từ chối giao dịch → xóa khỏi danh sách
  void rejectTransaction(String id) {
    _pendingNotifications.removeWhere((n) => n.id == id);
    _saveHistory();
    debugPrint('🗑️ Rejected transaction: $id');
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
          .map((json) => BankNotificationModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error loading notification history: $e');
      _pendingNotifications = [];
    }
  }

  /// Generate mock data for demonstration
  void _generateMockData() {
    _pendingNotifications = [
      // Pending 1: Salary
      BankNotificationModel(
        id: 'mock_1',
        bankName: 'Techcombank',
        packageName: 'com.techcombank.mobile',
        amount: 35000000,
        isIncoming: true,
        rawContent: 'LUONG THANG 01', // Parsed content
        parsedTitle: 'Lương tháng 1',
        category: ExpenseCategory.salary,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isAutoRecorded: false,
      ),
      // Pending 2: Dinner
      BankNotificationModel(
        id: 'mock_2',
        bankName: 'Vietcombank',
        packageName: 'com.vietcombank.mobile',
        amount: 1250000,
        isIncoming: false,
        rawContent: 'HAIDILAO HOTPOT',
        parsedTitle: 'Haidilao Hotpot',
        category: ExpenseCategory.food,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isAutoRecorded: false,
        balance: 5432000, // Simulate bank balance sync
      ),
      // Pending 3: Grab
      BankNotificationModel(
        id: 'mock_3',
        bankName: 'Momo',
        packageName: 'com.mservice.momotransfer',
        amount: 85000,
        isIncoming: false,
        rawContent: 'Thanh toan Grab chuyen 123',
        parsedTitle: 'Grab Car',
        category: ExpenseCategory.transport,
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        isAutoRecorded: false,
      ),
      // Pending 4: Unknown
      BankNotificationModel(
        id: 'mock_unknown',
        bankName: 'VietinBank',
        packageName: 'com.vietinbank.ipay',
        amount: 500000,
        isIncoming: true,
        rawContent: 'Nguoi giau giau ten chuyen khoan',
        parsedTitle: 'Giao dịch không xác định',
        category: ExpenseCategory.other,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isAutoRecorded: false,
      ),
      // Recorded 1: Coffee
      BankNotificationModel(
        id: 'mock_4',
        bankName: 'TPBank',
        packageName: 'com.tpb.mobile',
        amount: 55000,
        isIncoming: false,
        rawContent: 'HIGHLANDS COFFEE',
        parsedTitle: 'Highlands Coffee',
        category: ExpenseCategory.food,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isAutoRecorded: true,
      ),
      // Recorded 2: Electricity Bill
      BankNotificationModel(
        id: 'mock_5',
        bankName: 'MB Bank',
        packageName: 'com.mbmobile',
        amount: 780000,
        isIncoming: false,
        rawContent: 'Tien dien thang 1',
        parsedTitle: 'Tiền điện tháng 1',
        category: ExpenseCategory.bills,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isAutoRecorded: true,
      ),
    ];
    _notificationStreamController.add(_pendingNotifications.first); // Trigger UI update
    debugPrint('✅ Mock data generated: ${_pendingNotifications.length} items');
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _notificationStreamController.close();
  }
}

/// Wrapper to isolate notification_listener_service import
/// so it doesn't break web compilation
class _NotificationServiceWrapper {
  Future<bool> isPermissionGranted() async {
    // Dynamic import approach - only works on Android
    try {
      final result = await _invokeMethod('isPermissionGranted');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final result = await _invokeMethod('requestPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Stream<dynamic> get notificationsStream {
    final eventChannel = EventChannel('x-slayer/notifications_event');
    return eventChannel.receiveBroadcastStream().map((event) => _NotificationEvent.fromMap(event));
  }

  Future<bool?> _invokeMethod(String method) async {
    final channel = MethodChannel('x-slayer/notifications_channel');
    return await channel.invokeMethod<bool>(method);
  }
}

/// Lightweight notification event model to avoid direct dependency on the plugin's type
class _NotificationEvent {
  final String? packageName;
  final String? title;
  final String? content;
  final bool? hasRemoved;

  _NotificationEvent({this.packageName, this.title, this.content, this.hasRemoved});

  factory _NotificationEvent.fromMap(dynamic map) {
    return _NotificationEvent(
      packageName: map['packageName'] as String?,
      title: map['title'] as String?,
      content: map['content'] as String?,
      hasRemoved: map['hasRemoved'] as bool?,
    );
  }
}
