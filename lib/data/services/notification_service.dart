import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    _initialized = true;
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'fin_budget_alerts',
          'Cảnh báo ngân sách',
          channelDescription:
              'Thông báo khi bạn tiêu gần hết hoặc vượt ngân sách',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> showBudgetOverAlert({
    required double spent,
    required double budget,
  }) async {
    await _showNotification(
      id: 1,
      title: '⚠️ Cảnh báo: Vượt ngân sách rồii!',
      body:
          'Bạn đã chi vượt mức ngân sách tuần này. Hãy cẩn thận túi tiền nhé! 😭',
    );
  }

  Future<void> showBudgetNearAlert({
    required int percentUsed,
    required int daysRemaining,
  }) async {
    await _showNotification(
      id: 2,
      title: '🟠 Cẩn thận: Sắp hết ngân sách!',
      body:
          'Bạn đã dùng $percentUsed% ngân sách tuần mà còn tận $daysRemaining ngày nữa.',
    );
  }

  Future<void> showSavingRewardAlert({required double saved}) async {
    await _showNotification(
      id: 3,
      title: '🎉 Tuyệt vời: Bạn đang tiết kiệm rất tốt!',
      body:
          'Tuần này bạn đã tiết kiệm được một khoản đáng kể. Giữ vững phong độ nhé!',
    );
  }

  void scheduleDailyCheck() {
    Workmanager().registerPeriodicTask(
      "fin_daily_budget_check",
      "budgetCheckTask",
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(hours: 1),
      constraints: Constraints(requiresBatteryNotLow: true),
    );
  }
}
