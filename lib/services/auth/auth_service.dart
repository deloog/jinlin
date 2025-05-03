import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jinlin_app/models/auth/auth_result.dart';
import 'package:jinlin_app/models/user/user.dart';
import 'package:jinlin_app/services/auth/auth_service_interface.dart';
import 'package:jinlin_app/services/auth/third_party_auth_service.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 认证服务
///
/// 提供用户认证和授权功能
class AuthService implements AuthServiceInterface {
  // 单例实例
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 日志服务
  final LoggingService _logger = LoggingService();

  // API基础URL
  final String _baseUrl = 'https://api.example.com';

  // HTTP客户端
  final http.Client _client = http.Client();

  // 当前用户
  User? _currentUser;

  // 访问令牌
  String? _accessToken;

  // 刷新令牌
  String? _refreshToken;

  // 令牌过期时间
  DateTime? _tokenExpiryTime;

  // 认证状态变化监听器
  final List<void Function(User?)> _authStateListeners = [];

  // 是否已初始化
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _logger.info('初始化认证服务...');

    try {
      // 从本地存储加载认证信息
      await _loadAuthInfo();

      // 如果有访问令牌，尝试获取当前用户信息
      if (_accessToken != null) {
        try {
          await _fetchCurrentUser();
        } catch (e) {
          _logger.warning('获取当前用户信息失败，尝试刷新令牌');

          // 尝试刷新令牌
          if (_refreshToken != null) {
            try {
              await refreshAccessToken();
              await _fetchCurrentUser();
            } catch (e) {
              _logger.warning('刷新令牌失败，清除认证信息');
              await _clearAuthInfo();
            }
          } else {
            await _clearAuthInfo();
          }
        }
      }

      _initialized = true;
      _logger.info('认证服务初始化完成');
    } catch (e, stack) {
      _logger.error('认证服务初始化失败', e, stack);
      await _clearAuthInfo();
    }
  }

  @override
  User? get currentUser => _currentUser;

  @override
  String? get currentUserId => _currentUser?.id;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  bool get isPremiumUser => _currentUser?.role == UserRole.premium || _currentUser?.role == UserRole.admin;

  @override
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    _logger.info('注册用户: $email');

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'display_name': displayName,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // 保存认证信息
        await _saveAuthInfo(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresIn: data['expires_in'],
        );

        // 创建用户对象
        _currentUser = User.fromJson(data['user']);

        // 通知监听器
        _notifyAuthStateListeners();

        return _currentUser!;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '注册失败');
      }
    } catch (e, stack) {
      _logger.error('注册失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    _logger.info('登录: $email');

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 保存认证信息
        await _saveAuthInfo(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresIn: data['expires_in'],
        );

        // 创建用户对象
        _currentUser = User.fromJson(data['user']);

        // 通知监听器
        _notifyAuthStateListeners();

        return _currentUser!;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '登录失败');
      }
    } catch (e, stack) {
      _logger.error('登录失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<User> loginWithProvider(String provider) async {
    _logger.info('使用第三方服务登录: $provider');

    try {
      // 获取第三方登录服务
      final thirdPartyAuthService = ThirdPartyAuthService();

      // 确保第三方登录服务已初始化
      await thirdPartyAuthService.initialize();

      // 根据提供者选择登录方法
      AuthResult result;

      final providerName = provider.toLowerCase().replaceAll('.com', '');
      switch (providerName) {
        case 'google':
          result = await thirdPartyAuthService.signInWithGoogle();
          break;
        case 'facebook':
          result = await thirdPartyAuthService.signInWithFacebook();
          break;
        case 'twitter':
          result = await thirdPartyAuthService.signInWithTwitter();
          break;
        case 'apple':
          result = await thirdPartyAuthService.signInWithApple();
          break;
        case 'wechat':
          result = await thirdPartyAuthService.signInWithWeChat();
          break;
        case 'qq':
          result = await thirdPartyAuthService.signInWithQQ();
          break;
        case 'weibo':
          result = await thirdPartyAuthService.signInWithWeibo();
          break;
        case 'tiktok':
          result = await thirdPartyAuthService.signInWithTikTok();
          break;
        default:
          throw Exception('不支持的第三方登录提供者: $provider');
      }

      if (!result.success) {
        throw Exception(result.errorMessage ?? '第三方登录失败');
      }

      if (result.user == null) {
        throw Exception('无法获取用户信息');
      }

      // 保存认证信息
      await _saveAuthInfo(
        accessToken: result.token,
        refreshToken: null, // 第三方登录通常没有刷新令牌
        expiresIn: 3600, // 默认1小时过期
      );

      // 设置当前用户
      _currentUser = result.user;

      // 通知监听器
      _notifyAuthStateListeners();

      return _currentUser!;
    } catch (e, stack) {
      _logger.error('第三方登录失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    _logger.info('登出');

    try {
      if (_accessToken != null) {
        await _client.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
        );
      }
    } catch (e, stack) {
      _logger.error('登出失败', e, stack);
    } finally {
      // 清除认证信息
      await _clearAuthInfo();

      // 通知监听器
      _notifyAuthStateListeners();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    _logger.info('发送密码重置邮件: $email');

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '发送密码重置邮件失败');
      }
    } catch (e, stack) {
      _logger.error('发送密码重置邮件失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _logger.info('重置密码');

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/reset-password/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'password': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '重置密码失败');
      }
    } catch (e, stack) {
      _logger.error('重置密码失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<User> updateUserInfo({
    String? displayName,
    String? avatarUrl,
  }) async {
    _logger.info('更新用户信息');

    if (_currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      final token = await getAccessToken();

      if (token == null) {
        throw Exception('无效的访问令牌');
      }

      final response = await _client.put(
        Uri.parse('$_baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'display_name': displayName,
          'avatar_url': avatarUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 更新当前用户
        _currentUser = User.fromJson(data);

        // 通知监听器
        _notifyAuthStateListeners();

        return _currentUser!;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '更新用户信息失败');
      }
    } catch (e, stack) {
      _logger.error('更新用户信息失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _logger.info('更新密码');

    if (_currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      final token = await getAccessToken();

      if (token == null) {
        throw Exception('无效的访问令牌');
      }

      final response = await _client.put(
        Uri.parse('$_baseUrl/auth/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '更新密码失败');
      }
    } catch (e, stack) {
      _logger.error('更新密码失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updateEmail({
    required String password,
    required String newEmail,
  }) async {
    _logger.info('更新电子邮件');

    if (_currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      final token = await getAccessToken();

      if (token == null) {
        throw Exception('无效的访问令牌');
      }

      final response = await _client.put(
        Uri.parse('$_baseUrl/auth/email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password': password,
          'new_email': newEmail,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '更新电子邮件失败');
      }
    } catch (e, stack) {
      _logger.error('更新电子邮件失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    _logger.info('发送电子邮件验证');

    if (_currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      final token = await getAccessToken();

      if (token == null) {
        throw Exception('无效的访问令牌');
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/email/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '发送电子邮件验证失败');
      }
    } catch (e, stack) {
      _logger.error('发送电子邮件验证失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> verifyEmail(String token) async {
    _logger.info('验证电子邮件');

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/email/verify/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        // 更新当前用户
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(isEmailVerified: true);

          // 通知监听器
          _notifyAuthStateListeners();
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '验证电子邮件失败');
      }
    } catch (e, stack) {
      _logger.error('验证电子邮件失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount(String password) async {
    _logger.info('删除账户');

    if (_currentUser == null) {
      throw Exception('用户未登录');
    }

    try {
      final token = await getAccessToken();

      if (token == null) {
        throw Exception('无效的访问令牌');
      }

      final response = await _client.delete(
        Uri.parse('$_baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        // 清除认证信息
        await _clearAuthInfo();

        // 通知监听器
        _notifyAuthStateListeners();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '删除账户失败');
      }
    } catch (e, stack) {
      _logger.error('删除账户失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    // 如果没有访问令牌，返回null
    if (_accessToken == null) return null;

    // 如果令牌已过期，尝试刷新
    if (_tokenExpiryTime != null && _tokenExpiryTime!.isBefore(DateTime.now())) {
      _logger.debug('访问令牌已过期，尝试刷新');
      return await refreshAccessToken();
    }

    return _accessToken;
  }

  @override
  Future<String?> refreshAccessToken() async {
    _logger.debug('刷新访问令牌');

    if (_refreshToken == null) {
      _logger.warning('没有刷新令牌');
      return null;
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 保存认证信息
        await _saveAuthInfo(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresIn: data['expires_in'],
        );

        return _accessToken;
      } else {
        _logger.warning('刷新访问令牌失败');
        await _clearAuthInfo();
        return null;
      }
    } catch (e, stack) {
      _logger.error('刷新访问令牌失败', e, stack);
      await _clearAuthInfo();
      return null;
    }
  }

  @override
  void addAuthStateListener(void Function(User?) listener) {
    _authStateListeners.add(listener);
  }

  @override
  void removeAuthStateListener(void Function(User?) listener) {
    _authStateListeners.remove(listener);
  }

  @override
  Future<void> close() async {
    _logger.debug('关闭认证服务');

    // 清空监听器
    _authStateListeners.clear();

    // 关闭HTTP客户端
    _client.close();

    _initialized = false;
  }

  /// 获取当前用户信息
  Future<void> _fetchCurrentUser() async {
    _logger.debug('获取当前用户信息');

    if (_accessToken == null) {
      throw Exception('无效的访问令牌');
    }

    final response = await _client.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _currentUser = User.fromJson(data);
    } else {
      throw Exception('获取当前用户信息失败');
    }
  }

  /// 保存认证信息
  Future<void> _saveAuthInfo({
    required String? accessToken,
    required String? refreshToken,
    required int expiresIn,
  }) async {
    _logger.debug('保存认证信息');

    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiryTime = DateTime.now().add(Duration(seconds: expiresIn));

    // 保存到本地存储
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) {
      await prefs.setString('access_token', accessToken);
    }
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
    await prefs.setInt('token_expiry_time', _tokenExpiryTime!.millisecondsSinceEpoch);
  }

  /// 加载认证信息
  Future<void> _loadAuthInfo() async {
    _logger.debug('加载认证信息');

    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');

    final expiryTime = prefs.getInt('token_expiry_time');
    if (expiryTime != null) {
      _tokenExpiryTime = DateTime.fromMillisecondsSinceEpoch(expiryTime);
    }
  }

  /// 清除认证信息
  Future<void> _clearAuthInfo() async {
    _logger.debug('清除认证信息');

    _accessToken = null;
    _refreshToken = null;
    _tokenExpiryTime = null;
    _currentUser = null;

    // 清除本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiry_time');
  }

  /// 通知认证状态变化监听器
  void _notifyAuthStateListeners() {
    for (final listener in _authStateListeners) {
      listener(_currentUser);
    }
  }
}
