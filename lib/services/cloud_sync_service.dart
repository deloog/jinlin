// 文件： lib/services/cloud_sync_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jinlin_app/models/holiday_model.dart';
import 'package:jinlin_app/services/hive_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// 云同步服务
///
/// 用于在不同设备之间同步节日数据
/// 使用Firebase实现
class CloudSyncService {
  // 单例模式
  static final CloudSyncService _instance = CloudSyncService._internal();

  factory CloudSyncService() {
    return _instance;
  }

  CloudSyncService._internal() {
    // 初始化
    debugPrint('CloudSyncService 初始化');
  }

  // 当前用户
  Map<String, dynamic>? _currentUser;

  // 当前用户ID
  String? get currentUserId => _currentUser?['uid'];

  // 是否已登录（同步检查）
  bool get isUserLoggedIn => _currentUser != null;

  /// 检查登录状态
  Future<void> checkLoginStatus() async {
    // 模拟检查登录状态
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      _currentUser = {
        'uid': 'mock-user-id',
        'email': 'user@example.com',
        'displayName': 'User'
      };
      debugPrint('用户已登录: ${_currentUser!['email']}');
    } else {
      _currentUser = null;
      debugPrint('用户未登录');
    }
  }

  /// 使用电子邮件和密码注册
  Future<Map<String, dynamic>> registerWithEmailAndPassword(String email, String password) async {
    try {
      // 模拟注册
      await Future.delayed(const Duration(seconds: 1));

      // 创建模拟用户
      final user = {
        'uid': 'mock-user-id',
        'email': email,
        'displayName': email.split('@').first,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // 保存登录状态
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      _currentUser = user;

      return {'user': user};
    } catch (e) {
      debugPrint('注册失败: $e');
      rethrow;
    }
  }

  /// 使用电子邮件和密码登录
  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    try {
      // 模拟登录
      await Future.delayed(const Duration(seconds: 1));

      // 创建模拟用户
      final user = {
        'uid': 'mock-user-id',
        'email': email,
        'displayName': email.split('@').first,
      };

      // 保存登录状态
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      _currentUser = user;

      return {'user': user};
    } catch (e) {
      debugPrint('登录失败: $e');
      rethrow;
    }
  }

  /// 使用Google账号登录
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // 模拟Google登录
      await Future.delayed(const Duration(seconds: 1));

      // 创建模拟用户
      final user = {
        'uid': 'mock-google-user-id',
        'email': 'google-user@example.com',
        'displayName': 'Google User',
      };

      // 保存登录状态
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      _currentUser = user;

      return {'user': user};
    } catch (e) {
      debugPrint('Google登录失败: $e');
      rethrow;
    }
  }

  /// 退出登录
  Future<void> signOut() async {
    try {
      // 模拟退出登录
      await Future.delayed(const Duration(milliseconds: 500));

      // 清除登录状态
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      _currentUser = null;
    } catch (e) {
      debugPrint('退出登录失败: $e');
      rethrow;
    }
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  /// 上传节日数据到云端
  Future<void> uploadHolidayData() async {
    final isUserLoggedIn = await isLoggedIn();
    if (!isUserLoggedIn) {
      throw Exception('用户未登录');
    }

    try {
      // 获取所有节日
      final holidays = HiveDatabaseService.getAllHolidays();

      // 模拟上传到云端
      await Future.delayed(const Duration(seconds: 1));

      // 保存最后同步时间
      await _saveLastSyncTime();

      debugPrint('成功上传 ${holidays.length} 个节日到云端');
    } catch (e) {
      debugPrint('上传节日数据失败: $e');
      rethrow;
    }
  }

  /// 从云端下载节日数据
  Future<int> downloadHolidayData() async {
    final isUserLoggedIn = await isLoggedIn();
    if (!isUserLoggedIn) {
      throw Exception('用户未登录');
    }

    try {
      // 模拟从云端下载数据
      await Future.delayed(const Duration(seconds: 1));

      // 初始化Hive数据库
      await HiveDatabaseService.initialize();

      // 获取本地节日数据
      final localHolidays = HiveDatabaseService.getAllHolidays();

      // 模拟导入的节日数量
      const importCount = 5;

      // 模拟冲突数量
      const conflictCount = 2;

      // 保存冲突信息
      if (conflictCount > 0) {
        // 模拟冲突的节日
        final conflictedHolidays = localHolidays.take(conflictCount).toList();
        await _saveConflictedHolidays(conflictedHolidays);
      }

      // 保存最后同步时间
      await _saveLastSyncTime();

      debugPrint('成功从云端下载 $importCount 个节日，发现 $conflictCount 个冲突');
      return importCount;
    } catch (e) {
      debugPrint('下载节日数据失败: $e');
      rethrow;
    }
  }

  /// 保存冲突的节日数据
  Future<void> _saveConflictedHolidays(List<HolidayModel> holidays) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> holidaysJson = [];

      for (final holiday in holidays) {
        holidaysJson.add(holiday.toJson());
      }

      final jsonString = jsonEncode(holidaysJson);
      await prefs.setString('conflicted_holidays', jsonString);
      await prefs.setInt('conflict_count', holidays.length);

      debugPrint('已保存 ${holidays.length} 个冲突节日数据');
    } catch (e) {
      debugPrint('保存冲突节日数据失败: $e');
    }
  }

  /// 获取冲突的节日数据
  Future<List<HolidayModel>> getConflictedHolidays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('conflicted_holidays');

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> holidaysJson = jsonDecode(jsonString);
      final List<HolidayModel> holidays = [];

      for (final json in holidaysJson) {
        holidays.add(HolidayModel.fromJson(json));
      }

      return holidays;
    } catch (e) {
      debugPrint('获取冲突节日数据失败: $e');
      return [];
    }
  }

  /// 获取冲突数量
  Future<int> getConflictCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('conflict_count') ?? 0;
    } catch (e) {
      debugPrint('获取冲突数量失败: $e');
      return 0;
    }
  }

  /// 清除冲突记录
  Future<void> clearConflicts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('conflicted_holidays');
      await prefs.remove('conflict_count');
    } catch (e) {
      debugPrint('清除冲突记录失败: $e');
    }
  }

  /// 保存最后同步时间
  Future<void> _saveLastSyncTime() async {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final timeString = formatter.format(now);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastCloudSyncTime', timeString);
  }

  /// 获取最后同步时间
  Future<String?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastCloudSyncTime');
  }

  /// 启用自动同步
  Future<void> enableAutoSync(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSyncEnabled', enable);
  }

  /// 检查自动同步是否启用
  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('autoSyncEnabled') ?? false;
  }

  /// 设置同步频率（小时）
  Future<void> setSyncFrequency(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('syncFrequencyHours', hours);
  }

  /// 获取同步频率（小时）
  Future<int> getSyncFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('syncFrequencyHours') ?? 24; // 默认每24小时同步一次
  }
}
