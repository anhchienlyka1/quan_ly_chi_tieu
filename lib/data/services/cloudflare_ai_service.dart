import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/env_config.dart';

/// Cloudflare Workers AI — wrapper tương thích định dạng OpenAI Chat Completion.
///
/// Endpoint: https://api.cloudflare.com/client/v4/accounts/{account_id}/ai/run/{model}
/// Docs: https://developers.cloudflare.com/workers-ai/
///
/// Model mặc định: @cf/meta/llama-3.1-8b-instruct (miễn phí, nhanh)
/// Các model khác phổ biến:
///   - @cf/meta/llama-3.3-70b-instruct-fp8-fast  (thông minh hơn, vẫn miễn phí)
///   - @cf/mistral/mistral-7b-instruct-v0.2
///   - @cf/google/gemma-7b-it
class CloudflareAIService {
  static const String _baseUrl =
      'https://api.cloudflare.com/client/v4/accounts';

  final Dio _dio;
  final String _apiToken;
  final String _accountId;
  final String _model;

  /// [apiToken] — Cloudflare API Token. Nếu null, lấy từ EnvConfig.
  /// [accountId] — Cloudflare Account ID. Nếu null, lấy từ EnvConfig.
  /// [model]     — Model name. Mặc định từ EnvConfig.
  CloudflareAIService({String? apiToken, String? accountId, String? model})
    : _apiToken = apiToken ?? EnvConfig.cloudflareApiToken,
      _accountId = accountId ?? EnvConfig.cloudflareAccountId,
      _model = model ?? EnvConfig.cloudflareModel,
      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

  bool get isConfigured =>
      _apiToken.isNotEmpty && _accountId.isNotEmpty;

  String get _endpoint => '$_baseUrl/$_accountId/ai/run/$_model';

  /// Gửi danh sách messages và nhận phản hồi (không stream).
  ///
  /// [messages] — List các messages theo format OpenAI:
  ///   [{'role': 'system', 'content': '...'}, {'role': 'user', 'content': '...'}]
  /// [temperature] — Độ sáng tạo (0.0 – 1.0). Mặc định 0.7.
  /// [maxTokens] — Số token tối đa trong response.
  Future<String> chat(
    List<Map<String, String>> messages, {
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Cloudflare AI chưa được cấu hình. '
        'Vui lòng kiểm tra CLOUDFLARE_API_TOKEN và CLOUDFLARE_ACCOUNT_ID trong .env',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(
          headers: {'Authorization': 'Bearer $_apiToken'},
        ),
        data: {
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': false,
        },
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Cloudflare AI: Phản hồi trống');
      }

      // Cloudflare trả về: {"result": {"response": "..."}, "success": true}
      final success = data['success'] as bool? ?? false;
      if (!success) {
        final errors = data['errors'] as List<dynamic>? ?? [];
        final errorMsg = errors.isNotEmpty ? errors.first.toString() : 'Unknown';
        throw Exception('Cloudflare AI Error: $errorMsg');
      }

      final result = data['result'] as Map<String, dynamic>?;
      final content = result?['response'] as String?;

      if (content == null || content.isEmpty) {
        throw Exception('Cloudflare AI: Nội dung phản hồi trống');
      }

      return content.trim();
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Stream phản hồi từ AI theo từng chunk (SSE).
  ///
  /// Trả về [Stream<String>] — mỗi phần tử là đoạn text mới từ AI.
  Stream<String> chatStream(
    List<Map<String, String>> messages, {
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    if (!isConfigured) {
      yield '⚠️ Cloudflare AI chưa được cấu hình. Vui lòng kiểm tra cài đặt.';
      return;
    }

    try {
      final response = await _dio.post<ResponseBody>(
        _endpoint,
        options: Options(
          headers: {'Authorization': 'Bearer $_apiToken'},
          responseType: ResponseType.stream,
        ),
        data: {
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': true,
        },
      );

      final stream = response.data?.stream;
      if (stream == null) return;

      // Buffer để ghép các chunk bị tách giữa chừng
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);

        // Tách từng dòng SSE
        final lines = buffer.split('\n');
        // Giữ lại dòng cuối (có thể chưa hoàn chỉnh)
        buffer = lines.last;

        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty || !line.startsWith('data:')) continue;

          final jsonStr = line.substring(5).trim();
          if (jsonStr == '[DONE]') return;

          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;

            // Cloudflare SSE format: {"response": "..."} hoặc OpenAI format
            final delta = json['response'] as String? ??
                ((json['choices'] as List<dynamic>?)
                    ?.first['delta']?['content'] as String?);

            if (delta != null && delta.isNotEmpty) {
              yield delta;
            }
          } catch (_) {
            // Bỏ qua chunk lỗi parse
          }
        }
      }

      // Xử lý phần còn lại trong buffer
      if (buffer.trim().isNotEmpty && buffer.startsWith('data:')) {
        final jsonStr = buffer.substring(5).trim();
        if (jsonStr != '[DONE]') {
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            final delta = json['response'] as String? ??
                ((json['choices'] as List<dynamic>?)
                    ?.first['delta']?['content'] as String?);
            if (delta != null && delta.isNotEmpty) {
              yield delta;
            }
          } catch (_) {}
        }
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      yield '\n⚠️ Lỗi kết nối AI. Vui lòng thử lại.';
    }
  }

  void _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      throw Exception(
        'Cloudflare AI: API Token không hợp lệ hoặc không có quyền ($statusCode). '
        'Vui lòng kiểm tra CLOUDFLARE_API_TOKEN trong Cài đặt.',
      );
    } else if (statusCode == 400) {
      final data = e.response?.data;
      throw Exception('Cloudflare AI: Request không hợp lệ — $data');
    } else if (statusCode == 429) {
      throw Exception(
        'Cloudflare AI: Đã đạt giới hạn request. Vui lòng thử lại sau.',
      );
    } else if (statusCode == 500 || statusCode == 503) {
      throw Exception('Cloudflare AI: Server đang bận. Vui lòng thử lại sau.');
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw Exception(
        'Cloudflare AI: Timeout kết nối. Kiểm tra mạng và thử lại.',
      );
    } else if (e.type == DioExceptionType.connectionError) {
      throw Exception('Cloudflare AI: Không có kết nối mạng.');
    }
    throw Exception('Cloudflare AI: Lỗi không xác định — ${e.message}');
  }
}
