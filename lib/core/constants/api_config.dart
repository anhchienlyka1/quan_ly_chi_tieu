import 'dart:io';
import 'package:flutter/foundation.dart';
import 'env_config.dart';

/// Configuration for API endpoints and network settings.
/// Automatically handles localhost variations between iOS Simulator and Android Emulator.
class ApiConfig {
  ApiConfig._();

  // Port of your local server — loaded from .env (API_PORT)
  static int get _port => EnvConfig.apiPort;

  // LAN IP for physical device testing — loaded from .env (LAN_IP)
  static String get _lanIp => EnvConfig.lanIp;

  /// Base URL that adapts to the platform.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_port';
    } else if (Platform.isAndroid) {
      // Android Emulator uses 10.0.2.2 to access host localhost
      return 'http://10.0.2.2:$_port';
    } else if (Platform.isIOS) {
      // iOS Simulator uses localhost
      return 'http://localhost:$_port';
    } else {
      // Fallback or physical device via LAN
      return 'http://$_lanIp:$_port';
    }
  }

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Endpoints
  static const String expenses = '/expenses';
  static const String categories = '/categories';
  static const String users = '/users';
}
