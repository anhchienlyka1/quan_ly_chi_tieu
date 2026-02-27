
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_chi_tieu/data/services/bank_notification_parser.dart';

void main() {
  group('BankNotificationParser Tests', () {
    test('TPBank incoming transaction', () {
      final notification = BankNotificationParser.parseNotification(
        packageName: 'com.tpb.mobile',
        title: 'TPBank',
        content: 'TK 1234: +500,000VND. SD: 10,000,000VND. ND: Chuyen khoan luong',
      );

      expect(notification, isNotNull);
      expect(notification?.bankName, 'TPBank');
      expect(notification?.packageName, 'com.tpb.mobile');
      expect(notification?.amount, 500000.0);
      expect(notification?.isIncoming, true);
      expect(notification?.balance, 10000000.0);
    });

    test('TPBank outgoing transaction', () {
      final notification = BankNotificationParser.parseNotification(
        packageName: 'com.tpb.mobile',
        title: 'TPBank',
        content: 'TK 1234: -200,000VND. SD: 9,800,000VND. ND: Thanh toan tien dien',
      );

      expect(notification, isNotNull);
      expect(notification?.bankName, 'TPBank');
      expect(notification?.amount, 200000.0);
      expect(notification?.isIncoming, false);
      expect(notification?.balance, 9800000.0);
    });

    test('Vietcombank incoming transaction', () {
      final notification = BankNotificationParser.parseNotification(
        packageName: 'com.VCB',
        title: 'Vietcombank',
        content: 'SD TK 0011...1234 +10,000,000VND luc 10:00 01/01/2024. SD: 20,000,000VND. Ref: Salary',
      );

      expect(notification, isNotNull);
      expect(notification?.bankName, 'Vietcombank');
      expect(notification?.amount, 10000000.0);
      expect(notification?.isIncoming, true);
    });

    test('Regex flexibility check', () {
      // Test without space between amount and currency
      final notification = BankNotificationParser.parseNotification(
        packageName: 'com.tpb.mobile',
        title: 'TPBank',
        content: 'TK 1234: +50,000VND',
      );
      expect(notification?.amount, 50000.0);
    });
    
    test('Unknown package name should return null', () {
      final notification = BankNotificationParser.parseNotification(
        packageName: 'com.unknown.app',
        title: 'Unknown',
        content: 'You received 100000 VND',
      );
      expect(notification, isNull);
    });
  });
}
