// 文件： lib/services/cloud_sync_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    // 初始化Firebase Auth
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;

    // 监听登录状态变化
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      debugPrint('Firebase Auth状态变化: ${user != null ? "已登录" : "未登录"}');
    });
  }

  // Firebase服务
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 当前用户
  User? _currentUser;

  // 当前用户ID
  String? get currentUserId => _currentUser?.uid;

  // 是否已登录
  bool get isLoggedIn => _currentUser != null;

  // 登录状态监听器
  Stream<bool> get authStateChanges =>
      _auth.authStateChanges().map((user) => user != null);

  /// 检查登录状态
  Future<void> checkLoginStatus() async {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      debugPrint('用户已登录: ${_currentUser!.email}');
    } else {
      debugPrint('用户未登录');
    }
  }

  /// 使用电子邮件和密码注册
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 创建用户文档
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      debugPrint('注册失败: $e');
      rethrow;
    }
  }

  /// 使用电子邮件和密码登录
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('登录失败: $e');
      rethrow;
    }
  }

  /// 使用Google账号登录
  Future<UserCredential> signInWithGoogle() async {
    try {
      // 触发Google登录流程
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google登录被取消');
      }

      // 获取认证详情
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 创建Firebase凭证
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 使用凭证登录Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google登录失败: $e');
      rethrow;
    }
  }

  /// 退出登录
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // 确保Google登录也退出
      await _auth.signOut();
    } catch (e) {
      debugPrint('退出登录失败: $e');
      rethrow;
    }
  }

  /// 上传节日数据到云端
  Future<void> uploadHolidayData() async {
    if (!isLoggedIn) {
      throw Exception('用户未登录');
    }

    try {
      // 获取所有节日
      final holidays = HiveDatabaseService.getAllHolidays();

      // 获取用户文档引用
      final userDocRef = _firestore.collection('users').doc(_currentUser!.uid);

      // 创建批量写入对象
      final batch = _firestore.batch();

      // 获取用户的节日集合引用
      final holidaysCollectionRef = userDocRef.collection('holidays');

      // 批量上传节日数据
      for (final holiday in holidays) {
        final holidayDocRef = holidaysCollectionRef.doc(holiday.id);
        final holidayData = holiday.toJson();

        // 添加最后修改时间
        holidayData['lastSyncTime'] = FieldValue.serverTimestamp();

        batch.set(holidayDocRef, holidayData, SetOptions(merge: true));
      }

      // 提交批量写入
      await batch.commit();

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
    if (!isLoggedIn) {
      throw Exception('用户未登录');
    }

    try {
      // 获取用户文档引用
      final userDocRef = _firestore.collection('users').doc(_currentUser!.uid);

      // 获取用户的节日集合引用
      final holidaysCollectionRef = userDocRef.collection('holidays');

      // 获取所有节日数据
      final querySnapshot = await holidaysCollectionRef.get();

      // 如果没有数据，直接返回
      if (querySnapshot.docs.isEmpty) {
        debugPrint('云端没有节日数据');
        return 0;
      }

      // 初始化Hive数据库
      await HiveDatabaseService.initialize();

      // 获取本地节日数据，用于冲突检测
      final localHolidays = HiveDatabaseService.getAllHolidays();
      final Map<String, HolidayModel> localHolidaysMap = {
        for (var holiday in localHolidays) holiday.id: holiday
      };

      // 从云端获取的节日数据
      final List<HolidayModel> cloudHolidays = [];

      // 将Firestore文档转换为HolidayModel对象
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // 确保ID与文档ID一致
        data['id'] = doc.id;
        cloudHolidays.add(HolidayModel.fromJson(data));
      }

      // 导入节日，处理冲突
      int importCount = 0;
      int conflictCount = 0;
      List<HolidayModel> conflictedHolidays = [];

      for (final cloudHoliday in cloudHolidays) {
        // 检查是否存在冲突
        if (localHolidaysMap.containsKey(cloudHoliday.id)) {
          final localHoliday = localHolidaysMap[cloudHoliday.id]!;

          // 检查最后修改时间，如果云端更新则使用云端版本
          // 如果本地更新则保留本地版本并记录冲突
          if (cloudHoliday.lastModified != null &&
              localHoliday.lastModified != null) {
            if (cloudHoliday.lastModified!.isAfter(localHoliday.lastModified!)) {
              // 云端版本更新，使用云端版本
              await HiveDatabaseService.saveHoliday(cloudHoliday);
              importCount++;
            } else if (cloudHoliday.lastModified!.isBefore(localHoliday.lastModified!)) {
              // 本地版本更新，记录冲突但保留本地版本
              conflictedHolidays.add(localHoliday);
              conflictCount++;
            }
            // 如果时间相同，不做任何操作
          } else {
            // 如果没有时间戳，默认使用云端版本
            await HiveDatabaseService.saveHoliday(cloudHoliday);
            importCount++;
          }
        } else {
          // 本地不存在，直接导入
          await HiveDatabaseService.saveHoliday(cloudHoliday);
          importCount++;
        }
      }

      // 保存冲突信息
      if (conflictCount > 0) {
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
