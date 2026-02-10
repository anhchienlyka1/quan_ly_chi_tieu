import 'package:dio/dio.dart';
import '../../core/constants/api_config.dart';

/// Singleton wrapper around Dio for handling HTTP requests.
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  late final Dio _dio;

  factory HttpClient() => _instance;

  HttpClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        responseType: ResponseType.json,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor (optional but recommended during dev)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
      logPrint: (obj) => print('🚀 [HTTP LOG] $obj'),
    ));
  }

  Dio get client => _dio;

  // Convenience methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) {
    return _dio.delete(path, data: data);
  }
}
