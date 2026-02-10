import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration for API endpoints and network settings.
/// Automatically handles localhost variations between iOS Simulator and Android Emulator.
class ApiConfig {
  ApiConfig._();

  // Port of your local server (e.g., Node.js, JSON Server, Python)
  static const int _port = 3000; 

  // For physical device testing, replace this with your computer's LAN IP
  // e.g., '192.168.1.5'
  static const String _lanIp = '192.168.1.5'; 

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
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Endpoints
  static const String expenses = '/expenses';
  static const String categories = '/categories';
  static const String users = '/users';
}
