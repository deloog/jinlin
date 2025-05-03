import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:jinlin_app/services/api/api_exception.dart';
import 'package:jinlin_app/services/cache/cache_manager.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// API客户端
///
/// 提供与服务器通信的统一接口，支持请求缓存和错误处理
class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final CacheManager _cacheManager;
  final LoggingService _logger = LoggingService();

  // 默认请求超时时间
  static const Duration _defaultTimeout = Duration(seconds: 15);

  // 默认缓存时间
  static const Duration _defaultCacheDuration = Duration(minutes: 5);

  // 默认重试次数
  static const int _defaultMaxRetries = 3;

  // 默认重试延迟
  static const Duration _defaultRetryDelay = Duration(seconds: 1);

  ApiClient({
    required this.baseUrl,
    required http.Client client,
    required CacheManager cacheManager,
  }) :
    _client = client,
    _cacheManager = cacheManager {
    _logger.info('初始化API客户端: $baseUrl');
    print('初始化API客户端: $baseUrl');
  }

  /// 发送GET请求
  Future<T> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic> json) fromJson,
    Duration timeout = _defaultTimeout,
    Duration cacheDuration = _defaultCacheDuration,
    bool forceRefresh = false,
    int maxRetries = _defaultMaxRetries,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    final cacheKey = uri.toString();

    // 检查缓存
    if (!forceRefresh) {
      final cachedData = await _cacheManager.getJson(cacheKey);
      if (cachedData != null) {
        _logger.debug('使用缓存数据: $cacheKey');
        return fromJson(cachedData);
      }
    }

    // 发送请求
    return _sendRequest<T>(
      uri: uri,
      method: 'GET',
      headers: headers,
      fromJson: fromJson,
      timeout: timeout,
      cacheDuration: cacheDuration,
      maxRetries: maxRetries,
    );
  }

  /// 发送POST请求
  Future<T> post<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Object? body,
    required T Function(Map<String, dynamic> json) fromJson,
    Duration timeout = _defaultTimeout,
    int maxRetries = _defaultMaxRetries,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    // 发送请求
    return _sendRequest<T>(
      uri: uri,
      method: 'POST',
      headers: headers,
      body: body,
      fromJson: fromJson,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }

  /// 发送PUT请求
  Future<T> put<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Object? body,
    required T Function(Map<String, dynamic> json) fromJson,
    Duration timeout = _defaultTimeout,
    int maxRetries = _defaultMaxRetries,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    // 发送请求
    return _sendRequest<T>(
      uri: uri,
      method: 'PUT',
      headers: headers,
      body: body,
      fromJson: fromJson,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }

  /// 发送DELETE请求
  Future<T> delete<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Object? body,
    required T Function(Map<String, dynamic> json) fromJson,
    Duration timeout = _defaultTimeout,
    int maxRetries = _defaultMaxRetries,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    // 发送请求
    return _sendRequest<T>(
      uri: uri,
      method: 'DELETE',
      headers: headers,
      body: body,
      fromJson: fromJson,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }

  /// 发送请求
  Future<T> _sendRequest<T>({
    required Uri uri,
    required String method,
    Map<String, String>? headers,
    Object? body,
    required T Function(Map<String, dynamic> json) fromJson,
    required Duration timeout,
    Duration? cacheDuration,
    int maxRetries = _defaultMaxRetries,
  }) async {
    // 准备请求头
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    // 准备请求体
    final requestBody = body != null ? jsonEncode(body) : null;

    // 记录请求信息
    _logger.debug('发送 $method 请求: $uri');
    print('发送 $method 请求: $uri');
    if (requestBody != null) {
      _logger.debug('请求体: $requestBody');
      print('请求体: $requestBody');
    }

    int retryCount = 0;
    while (true) {
      try {
        // 发送请求
        final http.Response response;
        switch (method) {
          case 'GET':
            response = await _client.get(
              uri,
              headers: requestHeaders,
            ).timeout(timeout);
            break;
          case 'POST':
            response = await _client.post(
              uri,
              headers: requestHeaders,
              body: requestBody,
            ).timeout(timeout);
            break;
          case 'PUT':
            response = await _client.put(
              uri,
              headers: requestHeaders,
              body: requestBody,
            ).timeout(timeout);
            break;
          case 'DELETE':
            response = await _client.delete(
              uri,
              headers: requestHeaders,
              body: requestBody,
            ).timeout(timeout);
            break;
          default:
            throw ApiException(
              statusCode: 0,
              message: '不支持的请求方法: $method',
            );
        }

        // 处理响应
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _logger.debug('请求成功: ${response.statusCode}');
          print('请求成功: ${response.statusCode}');
          print('响应体: ${response.body}');

          // 解析响应
          try {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            print('解析的数据: $data');

            // 缓存响应（仅GET请求）
            if (method == 'GET' && cacheDuration != null) {
              await _cacheManager.setJson(
                uri.toString(),
                data,
                expireTimeMs: cacheDuration.inMilliseconds,
              );
              print('响应已缓存');
            }

            return fromJson(data);
          } catch (e) {
            print('解析响应失败: $e');
            print('原始响应体: ${response.body}');
            rethrow;
          }
        } else {
          _logger.warning('请求失败: ${response.statusCode}, ${response.body}');
          print('请求失败: ${response.statusCode}');
          print('响应体: ${response.body}');

          // 处理特定状态码
          switch (response.statusCode) {
            case 401:
              throw ApiException(
                statusCode: response.statusCode,
                message: '未授权',
                body: response.body,
              );
            case 403:
              throw ApiException(
                statusCode: response.statusCode,
                message: '禁止访问',
                body: response.body,
              );
            case 404:
              throw ApiException(
                statusCode: response.statusCode,
                message: '资源不存在',
                body: response.body,
              );
            case 500:
              throw ApiException(
                statusCode: response.statusCode,
                message: '服务器错误',
                body: response.body,
              );
            default:
              throw ApiException(
                statusCode: response.statusCode,
                message: '请求失败',
                body: response.body,
              );
          }
        }
      } catch (e) {
        // 处理异常
        if (e is ApiException) {
          // 如果是API异常，直接抛出
          rethrow;
        } else if (e is SocketException) {
          // 网络连接异常
          _logger.error('网络连接异常: $e');
          if (retryCount < maxRetries) {
            retryCount++;
            _logger.debug('重试请求 ($retryCount/$maxRetries)...');
            await Future.delayed(_defaultRetryDelay * retryCount);
            continue;
          }
          throw ApiException(
            statusCode: 0,
            message: '网络连接异常',
            error: e,
          );
        } else if (e is TimeoutException) {
          // 请求超时
          _logger.error('请求超时: $e');
          if (retryCount < maxRetries) {
            retryCount++;
            _logger.debug('重试请求 ($retryCount/$maxRetries)...');
            await Future.delayed(_defaultRetryDelay * retryCount);
            continue;
          }
          throw ApiException(
            statusCode: 0,
            message: '请求超时',
            error: e,
          );
        } else {
          // 其他异常
          _logger.error('请求异常: $e');
          throw ApiException(
            statusCode: 0,
            message: '请求异常',
            error: e,
          );
        }
      }
    }
  }

  /// 检查服务器连接
  Future<bool> checkConnection() async {
    try {
      _logger.debug('检查服务器连接: $baseUrl');

      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      final isConnected = response.statusCode == 200;
      _logger.debug('服务器连接状态: ${isConnected ? '正常' : '异常'}');

      return isConnected;
    } catch (e) {
      _logger.error('检查服务器连接失败: $e');
      return false;
    }
  }
}
