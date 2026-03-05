import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment configuration values.
///
/// All config values are loaded from the `.env` file at app startup.
/// Usage: `EnvConfig.geminiApiKey`, `EnvConfig.geminiModel`, etc.
class EnvConfig {
  EnvConfig._();

  /// Load the .env file. Must be called before accessing any config values.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
      print('✅ .env loaded successfully. Keys: ${dotenv.env.keys.toList()}');
      print(
        '✅ GEMINI_API_KEY present: ${dotenv.env.containsKey('GEMINI_API_KEY')}',
      );
      print(
        '✅ GEMINI_API_KEY value: ${(dotenv.env['GEMINI_API_KEY'] ?? '').isNotEmpty ? 'set (${dotenv.env['GEMINI_API_KEY']!.substring(0, 8)}...)' : 'EMPTY'}',
      );
    } catch (e) {
      print('❌ .env load FAILED: $e');
    }
  }

  // ─── Gemini AI ──────────────────────────────────────────────────────────────

  /// Default Gemini API key from .env file.
  /// Users can override this via SharedPreferences ('gemini_api_key').
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Gemini model name (e.g., 'gemini-2.0-flash').
  static String get geminiModel =>
      dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.0-flash';

  // ─── Local Server ───────────────────────────────────────────────────────────

  /// Port number for the local API server.
  static int get apiPort => int.tryParse(dotenv.env['API_PORT'] ?? '') ?? 3000;

  /// LAN IP address for physical device testing.
  static String get lanIp => dotenv.env['LAN_IP'] ?? '192.168.1.5';
}
