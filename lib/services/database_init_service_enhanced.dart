import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jinlin_app/models/holiday_model_extended.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/services/hive_database_service_enhanced.dart';
import 'package:jinlin_app/services/database_migration_manager.dart';
import 'package:jinlin_app/services/database_validator_service.dart';
import 'package:uuid/uuid.dart';

/// 增强版数据库初始化服务
///
/// 负责初始化数据库、迁移数据和创建示例数据
class DatabaseInitServiceEnhanced {
  // 单例模式
  static final DatabaseInitServiceEnhanced _instance = DatabaseInitServiceEnhanced._internal();
  factory DatabaseInitServiceEnhanced() => _instance;
  DatabaseInitServiceEnhanced._internal();

  // 数据库服务
  final _dbService = HiveDatabaseServiceEnhanced();

  // 数据库迁移管理器
  final _migrationManager = DatabaseMigrationManager();

  // 数据验证服务
  final _validatorService = DatabaseValidatorService();

  /// 检查数据库初始化状态
  Future<bool> checkInitializationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('database_initialized') ?? false;
    } catch (e) {
      debugPrint('检查数据库初始化状态失败: $e');
      return false;
    }
  }

  /// 初始化数据库
  Future<bool> initialize([BuildContext? context]) async {
    try {
      // 初始化数据库服务
      await _dbService.initialize();

      // 执行数据库迁移
      await _migrationManager.migrate();

      // 验证数据
      final issues = await _validatorService.validateAllData();
      if (issues.isNotEmpty) {
        debugPrint('数据验证发现问题: $issues');

        // 修复数据问题
        final fixResult = await _validatorService.fixAllDataIssues();
        debugPrint('数据修复结果: $fixResult');
      }

      // 检查是否需要创建示例数据
      final needSampleData = await _checkNeedSampleData();
      if (needSampleData) {
        await _createSampleData();
      }

      // 保存初始化状态
      await _saveInitializationState(true);

      debugPrint('数据库和节日数据初始化成功');
      return true;
    } catch (e) {
      debugPrint('数据库初始化失败: $e');
      return false;
    }
  }

  /// 重置数据库
  Future<bool> reset(BuildContext context) async {
    try {
      // 关闭数据库
      await _dbService.close();

      // 清除初始化状态
      await _saveInitializationState(false);

      // 重新初始化，不依赖于BuildContext
      return await initialize();
    } catch (e) {
      debugPrint('重置数据库失败: $e');
      return false;
    }
  }

  /// 保存初始化状态
  Future<void> _saveInitializationState(bool initialized) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('database_initialized', initialized);
    } catch (e) {
      debugPrint('保存数据库初始化状态失败: $e');
    }
  }

  /// 检查是否需要创建示例数据
  Future<bool> _checkNeedSampleData() async {
    try {
      // 检查节日数据
      final holidays = _dbService.getAllHolidays();
      if (holidays.isNotEmpty) {
        return false;
      }

      // 检查联系人数据
      final contacts = _dbService.getAllContacts();
      if (contacts.isNotEmpty) {
        return false;
      }

      // 检查用户设置
      final settings = _dbService.getUserSettings();
      if (settings != null) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('检查是否需要创建示例数据失败: $e');
      return true;
    }
  }

  /// 创建示例数据
  Future<void> _createSampleData() async {
    try {
      debugPrint('开始创建示例数据...');

      // 创建示例节日
      await _createSampleHolidays();

      // 创建示例联系人
      await _createSampleContacts();

      // 创建示例用户设置
      await _createSampleUserSettings();

      debugPrint('示例数据创建完成');
    } catch (e) {
      debugPrint('创建示例数据失败: $e');
    }
  }

  /// 创建示例节日
  Future<void> _createSampleHolidays() async {
    try {
      debugPrint('开始创建示例节假日数据...');

      // 创建示例节日列表
      final holidays = <HolidayModelExtended>[
        // 新年
        HolidayModelExtended(
          id: 'global_new_year',
          name: '新年',
          nameEn: 'New Year',
          type: HolidayType.statutory,
          regions: ['ALL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '01-01',
          description: '新年是世界各地庆祝新一年开始的节日，通常在1月1日。',
          descriptionEn: 'New Year is a festival observed in most of the world on January 1, the first day of the year in the modern Gregorian calendar.',
          importanceLevel: ImportanceLevel.high,
          customs: '放烟花、倒数计时、新年愿望',
          foods: '年夜饭、香槟',
          greetings: '新年快乐！',
          activities: '跨年晚会、家庭聚餐',
          history: '新年庆祝活动可以追溯到古罗马时期。',
          imageUrl: 'assets/images/holidays/new_year.jpg',
          userImportance: 2,
          names: {
            'zh': '新年',
            'en': 'New Year',
            'ja': '新年',
            'ko': '새해',
            'fr': 'Nouvel An',
            'de': 'Neujahr',
          },
          descriptions: {
            'zh': '新年是世界各地庆祝新一年开始的节日，通常在1月1日。',
            'en': 'New Year is a festival observed in most of the world on January 1, the first day of the year in the modern Gregorian calendar.',
            'ja': '新年は、現代のグレゴリオ暦で1年の最初の日である1月1日に世界のほとんどの地域で祝われる祭りです。',
            'ko': '새해는 현대 그레고리력에서 1년의 첫 날인 1월 1일에 세계 대부분의 지역에서 관찰되는 축제입니다.',
            'fr': 'Le Nouvel An est une fête observée dans la plupart du monde le 1er janvier, le premier jour de l\'année dans le calendrier grégorien moderne.',
            'de': 'Neujahr ist ein Fest, das in den meisten Teilen der Welt am 1. Januar, dem ersten Tag des Jahres im modernen gregorianischen Kalender, gefeiert wird.',
          },
        ),
      ];

      // 保存示例节日
      await _dbService.saveHolidays(holidays);

      debugPrint('成功创建 ${holidays.length} 个示例节日');

      // 提示用户使用JSON文件加载更多节日数据
      debugPrint('注意：建议使用JSON文件加载更多节日数据，而不是硬编码在代码中');
    } catch (e) {
      debugPrint('创建示例节假日数据失败: $e');
    }
  }

  /// 创建示例联系人
  Future<void> _createSampleContacts() async {
    try {
      debugPrint('开始创建示例联系人数据...');

      // 创建示例联系人列表
      final contacts = <ContactModel>[
        ContactModel(
          id: const Uuid().v4(),
          name: '张三',
          relationType: RelationType.family,
          specificRelation: '父亲',
          phoneNumber: '13800138000',
          email: 'zhangsan@example.com',
          birthday: DateTime(1970, 5, 15),
          isBirthdayLunar: false,
          names: {
            'zh': '张三',
            'en': 'Zhang San',
          },
          specificRelations: {
            'zh': '父亲',
            'en': 'Father',
          },
        ),
        ContactModel(
          id: const Uuid().v4(),
          name: '李四',
          relationType: RelationType.friend,
          specificRelation: '大学同学',
          phoneNumber: '13900139000',
          email: 'lisi@example.com',
          birthday: DateTime(1990, 8, 20),
          isBirthdayLunar: false,
          names: {
            'zh': '李四',
            'en': 'Li Si',
          },
          specificRelations: {
            'zh': '大学同学',
            'en': 'College Classmate',
          },
        ),
        ContactModel(
          id: const Uuid().v4(),
          name: '王五',
          relationType: RelationType.colleague,
          specificRelation: '项目经理',
          phoneNumber: '13700137000',
          email: 'wangwu@example.com',
          birthday: DateTime(1985, 12, 10),
          isBirthdayLunar: false,
          names: {
            'zh': '王五',
            'en': 'Wang Wu',
          },
          specificRelations: {
            'zh': '项目经理',
            'en': 'Project Manager',
          },
        ),
      ];

      // 保存示例联系人
      await _dbService.saveContacts(contacts);

      debugPrint('成功创建 ${contacts.length} 个示例联系人');
    } catch (e) {
      debugPrint('创建示例联系人数据失败: $e');
    }
  }

  /// 创建示例用户设置
  Future<void> _createSampleUserSettings() async {
    try {
      debugPrint('开始创建示例用户设置...');

      // 创建示例用户设置
      final settings = UserSettingsModel(
        userId: const Uuid().v4(),
        nickname: '用户',
        languageCode: 'zh',
        countryCode: 'CN',
        showLunarCalendar: true,
        themeMode: AppThemeMode.system,
        enableNotifications: true,
        enableSound: true,
        enableVibration: true,
        enableCloudSync: false,
        syncFrequencyHours: 24,
        autoBackup: true,
        backupFrequencyDays: 7,
        showExpiredEvents: false,
        expiredEventRetentionDays: 30,
        enableAIFeatures: true,
      );

      // 保存示例用户设置
      await _dbService.saveUserSettings(settings);

      debugPrint('成功创建示例用户设置');
    } catch (e) {
      debugPrint('创建示例用户设置失败: $e');
    }
  }
}
