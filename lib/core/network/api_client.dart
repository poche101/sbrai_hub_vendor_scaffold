import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Thin wrapper around [Dio] shared by every service class.
/// Handles: base URL, bearer token injection, 401 handling hook,
/// and converting Laravel's standard error/validation shape into
/// a typed [ApiException].
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  /// Set by AuthProvider at startup so a 401 anywhere can trigger logout.
  void Function()? onUnauthorized;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _wrap(() => _dio.get<T>(path, queryParameters: query));

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _wrap(() => _dio.post<T>(path, data: data));

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _wrap(() => _dio.put<T>(path, data: data));

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _wrap(() => _dio.patch<T>(path, data: data));

  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      _wrap(() => _dio.delete<T>(path, data: data));

  /// Multipart upload helper, used for KYC document submission and
  /// product photo uploads.
  Future<Response<T>> postMultipart<T>(String path, FormData formData) =>
      _wrap(() => _dio.post<T>(path, data: formData));

  Future<Response<T>> _wrap<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException('Network error. Please check your connection.');
    }

    final data = response.data;
    String message = 'Something went wrong. Please try again.';
    Map<String, List<String>>? fieldErrors;

    if (data is Map) {
      if (data['message'] is String) message = data['message'];
      if (data['errors'] is Map) {
        fieldErrors = (data['errors'] as Map).map(
          (k, v) => MapEntry(k.toString(), List<String>.from(v as List)),
        );
      }
    }

    return ApiException(message, statusCode: response.statusCode, fieldErrors: fieldErrors);
  }
}
