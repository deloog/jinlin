import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jinlin_app/services/api_service.dart';
import 'package:jinlin_app/services/mock_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API服务提供者
///
/// 负责创建和提供API服务实例
class ApiServiceProvider {
  // 单例模式
  static final ApiServiceProvider _instance = ApiServiceProvider._internal();

  factory ApiServiceProvider() {
    return _instance;
  }

  ApiServiceProvider._internal() {
    // 初始化时尝试加载保存的设置
    _loadSettings();
  }

  // API服务实例
  ApiService? _apiService;

  // 服务器URL
  String _serverUrl = 'http://localhost:3000';

  // 是否使用模拟数据
  bool _useMock = false;

  // 初始化状态标志（目前未使用，但保留以便将来扩展）

  /// 获取是否使用模拟数据
  bool get useMock => _useMock;

  /// 获取服务器URL
  String get serverUrl => _serverUrl;

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _serverUrl = prefs.getString('api_server_url') ?? 'http://localhost:3000';
      _useMock = prefs.getBool('api_use_mock') ?? false;
      debugPrint('ApiServiceProvider: 加载设置完成，服务器URL: $_serverUrl，使用模拟数据: $_useMock');
    } catch (e) {
      debugPrint('ApiServiceProvider: 加载设置失败: $e');
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_server_url', _serverUrl);
      await prefs.setBool('api_use_mock', _useMock);
      debugPrint('ApiServiceProvider: 保存设置完成');
    } catch (e) {
      debugPrint('ApiServiceProvider: 保存设置失败: $e');
    }
  }

  /// 获取API服务实例
  ApiService getApiService({bool? useMock}) {
    // 如果传入了useMock参数，则使用传入的值
    final shouldUseMock = useMock ?? _useMock;

    // 如果已经创建了API服务实例，且使用模拟数据的设置没有变化，则直接返回
    if (_apiService != null) {
      if ((shouldUseMock && _apiService is MockApiService) ||
          (!shouldUseMock && _apiService is! MockApiService)) {
        return _apiService!;
      }
      // 否则清空实例，重新创建
      _apiService = null;
    }

    // 根据环境和参数创建不同的API服务
    if (kReleaseMode) {
      // 生产环境使用真实API服务
      _apiService = ApiService(_serverUrl, http.Client());
      debugPrint('ApiServiceProvider: 创建生产环境API服务，服务器URL: $_serverUrl');
    } else if (shouldUseMock) {
      // 开发环境使用模拟API服务
      _apiService = MockApiService();
      debugPrint('ApiServiceProvider: 创建开发环境模拟API服务');
    } else {
      // 开发环境使用本地服务器
      _apiService = ApiService(_serverUrl, http.Client());
      debugPrint('ApiServiceProvider: 创建开发环境API服务，连接本地服务器: $_serverUrl');
    }

    return _apiService!;
  }

  /// 设置是否使用模拟数据
  Future<void> setUseMock(bool useMock) async {
    if (_useMock != useMock) {
      _useMock = useMock;
      _apiService = null; // 清空实例，下次获取时重新创建
      await _saveSettings();
      debugPrint('ApiServiceProvider: 设置使用模拟数据: $useMock');
    }
  }

  /// 设置服务器URL
  Future<void> setServerUrl(String url) async {
    // 只有在非生产环境下才允许修改服务器URL
    if (!kReleaseMode) {
      if (_serverUrl != url) {
        _serverUrl = url;
        if (!_useMock) {
          _apiService = null; // 只有在不使用模拟数据时才需要清空实例
        }
        await _saveSettings();
        debugPrint('ApiServiceProvider: 设置服务器URL: $url');
      }
    }
  }

  /// 检查服务器连接
  Future<bool> checkServerConnection() async {
    try {
      final apiService = getApiService(useMock: false);
      return await apiService.checkConnection();
    } catch (e) {
      debugPrint('ApiServiceProvider: 检查服务器连接失败: $e');
      return false;
    }
  }
}
