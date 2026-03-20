import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment configuration values.
///
/// All config values are loaded from the `.env` file at app startup.
/// Usage: `EnvConfig.cloudflareApiToken`, `EnvConfig.cloudflareAccountId`, etc.
class EnvConfig {
  EnvConfig._();

  /// Load the .env file. Must be called before accessing any config values.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
      print('✅ .env loaded successfully. Keys: ${dotenv.env.keys.toList()}');
      print(
        '✅ CLOUDFLARE_API_TOKEN present: ${dotenv.env.containsKey('CLOUDFLARE_API_TOKEN')}',
      );
      print(
        '✅ CLOUDFLARE_ACCOUNT_ID present: ${dotenv.env.containsKey('CLOUDFLARE_ACCOUNT_ID')}',
      );
    } catch (e) {
      print('❌ .env load FAILED: $e');
    }
  }

  // ─── Cloudflare Workers AI ───────────────────────────────────────────────────

  /// Cloudflare API Token — tạo tại https://dash.cloudflare.com/profile/api-tokens
  /// Cần quyền: "Workers AI — Read" (hoặc "All")
  static String get cloudflareApiToken =>
      dotenv.env['CLOUDFLARE_API_TOKEN'] ?? '';

  /// Cloudflare Account ID — xem tại https://dash.cloudflare.com → sidebar phải
  static String get cloudflareAccountId =>
      dotenv.env['CLOUDFLARE_ACCOUNT_ID'] ?? '';

  /// Model name cho Cloudflare Workers AI.
  /// Mặc định: @cf/meta/llama-3.1-8b-instruct (miễn phí, hỗ trợ tiếng Việt tốt)
  /// Alternatives:
  ///   - @cf/meta/llama-3.3-70b-instruct-fp8-fast (thông minh hơn)
  ///   - @cf/mistral/mistral-7b-instruct-v0.2
  static String get cloudflareModel =>
      dotenv.env['CLOUDFLARE_MODEL'] ??
      '@cf/meta/llama-3.1-8b-instruct';

  // ─── Backward Compatibility (deprecated) ────────────────────────────────────
  @Deprecated('Use cloudflareApiToken instead')
  static String get deepseekApiKey => cloudflareApiToken;

  @Deprecated('Use cloudflareModel instead')
  static String get deepseekModel => cloudflareModel;

  @Deprecated('Use cloudflareApiToken instead')
  static String get geminiApiKey => cloudflareApiToken;

  @Deprecated('Use cloudflareModel instead')
  static String get geminiModel => cloudflareModel;

  // ─── Local Server ───────────────────────────────────────────────────────────

  /// Port number for the local API server.
  static int get apiPort =>
      int.tryParse(dotenv.env['API_PORT'] ?? '') ?? 3000;

  /// LAN IP address for physical device testing.
  static String get lanIp => dotenv.env['LAN_IP'] ?? '192.168.1.5';
}
