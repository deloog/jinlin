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

        // 春节
        HolidayModelExtended(
          id: 'chinese_spring_festival',
          name: '春节',
          nameEn: 'Spring Festival',
          type: HolidayType.traditional,
          regions: ['CN', 'HK', 'TW', 'SG'],
          calculationType: DateCalculationType.fixedLunar,
          calculationRule: '01-01L',
          description: '春节是中国最重要的传统节日，庆祝农历新年的开始。',
          descriptionEn: 'Spring Festival is the most important traditional festival in China, celebrating the beginning of the lunar new year.',
          importanceLevel: ImportanceLevel.high,
          customs: '贴春联、放鞭炮、给红包',
          foods: '饺子、年糕、鱼',
          greetings: '新年快乐！恭喜发财！',
          activities: '家庭团聚、看春晚、拜年',
          history: '春节有超过4000年的历史，起源于中国古代的祭祀活动。',
          imageUrl: 'assets/images/holidays/spring_festival.jpg',
          userImportance: 2,
          names: {
            'zh': '春节',
            'en': 'Spring Festival',
            'ja': '春節',
            'ko': '춘절',
            'fr': 'Fête du Printemps',
            'de': 'Frühlingsfest',
          },
          descriptions: {
            'zh': '春节是中国最重要的传统节日，庆祝农历新年的开始。',
            'en': 'Spring Festival is the most important traditional festival in China, celebrating the beginning of the lunar new year.',
            'ja': '春節は中国で最も重要な伝統的な祭りであり、旧正月の始まりを祝います。',
            'ko': '춘절은 중국에서 가장 중요한 전통 축제로, 음력 새해의 시작을 축하합니다.',
            'fr': 'La Fête du Printemps est la fête traditionnelle la plus importante en Chine, célébrant le début de la nouvelle année lunaire.',
            'de': 'Das Frühlingsfest ist das wichtigste traditionelle Fest in China, das den Beginn des neuen Mondjahres feiert.',
          },
        ),

        // 情人节
        HolidayModelExtended(
          id: 'INTL_ValentinesDay',
          name: '情人节',
          nameEn: 'Valentine\'s Day',
          type: HolidayType.international,
          regions: ['INTL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '02-14',
          description: '情人节是一个庆祝爱情和浪漫的节日，通常在2月14日。',
          descriptionEn: 'Valentine\'s Day is a festival celebrating love and romance, typically observed on February 14.',
          importanceLevel: ImportanceLevel.medium,
          customs: '送花、送巧克力、送贺卡',
          foods: '巧克力、甜点',
          greetings: '情人节快乐！',
          activities: '浪漫晚餐、约会',
          history: '情人节的起源可以追溯到古罗马的节日和基督教的圣瓦伦丁。',
          imageUrl: 'assets/images/holidays/valentines_day.jpg',
          userImportance: 1,
          names: {
            'zh': '情人节',
            'en': 'Valentine\'s Day',
            'ja': 'バレンタインデー',
            'ko': '발렌타인 데이',
            'fr': 'Saint-Valentin',
            'de': 'Valentinstag',
          },
          descriptions: {
            'zh': '情人节是一个庆祝爱情和浪漫的节日，通常在2月14日。',
            'en': 'Valentine\'s Day is a festival celebrating love and romance, typically observed on February 14.',
            'ja': 'バレンタインデーは、通常2月14日に行われる、愛とロマンスを祝う祭りです。',
            'ko': '발렌타인 데이는 일반적으로 2월 14일에 관찰되는 사랑과 로맨스를 축하하는 축제입니다.',
            'fr': 'La Saint-Valentin est une fête célébrant l\'amour et la romance, généralement observée le 14 février.',
            'de': 'Der Valentinstag ist ein Fest, das Liebe und Romantik feiert und typischerweise am 14. Februar begangen wird.',
          },
        ),

        // 清明节
        HolidayModelExtended(
          id: 'chinese_qingming_festival',
          name: '清明节',
          nameEn: 'Qingming Festival',
          type: HolidayType.traditional,
          regions: ['CN', 'HK', 'TW'],
          calculationType: DateCalculationType.solarTermBased,
          calculationRule: 'QingMing',
          description: '清明节是中国传统节日，用于扫墓和缅怀逝者。',
          descriptionEn: 'Qingming Festival is a traditional Chinese festival for tomb sweeping and remembering the deceased.',
          importanceLevel: ImportanceLevel.medium,
          customs: '扫墓、祭祖、放风筝',
          foods: '青团、寒食',
          greetings: '清明节安康',
          activities: '踏青、植树',
          history: '清明节源于古代的寒食节，距今已有2500多年的历史。',
          imageUrl: 'assets/images/holidays/qingming_festival.jpg',
          userImportance: 1,
          names: {
            'zh': '清明节',
            'en': 'Qingming Festival',
            'ja': '清明節',
            'ko': '청명절',
            'fr': 'Fête de Qingming',
            'de': 'Qingming-Fest',
          },
          descriptions: {
            'zh': '清明节是中国传统节日，用于扫墓和缅怀逝者。',
            'en': 'Qingming Festival is a traditional Chinese festival for tomb sweeping and remembering the deceased.',
            'ja': '清明節は墓掃除と故人を偲ぶための中国の伝統的な祭りです。',
            'ko': '청명절은 묘소를 청소하고 고인을 기억하기 위한 중국 전통 축제입니다.',
            'fr': 'La Fête de Qingming est une fête traditionnelle chinoise pour le balayage des tombes et le souvenir des défunts.',
            'de': 'Das Qingming-Fest ist ein traditionelles chinesisches Fest zum Grabfegen und zum Gedenken an die Verstorbenen.',
          },
        ),

        // 劳动节
        HolidayModelExtended(
          id: 'INTL_LabourDay',
          name: '劳动节',
          nameEn: 'Labour Day',
          type: HolidayType.statutory,
          regions: ['INTL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '05-01',
          description: '劳动节是庆祝工人阶级贡献的国际性节日，通常在5月1日。',
          descriptionEn: 'Labour Day is an international celebration of the contributions of workers, typically observed on May 1.',
          importanceLevel: ImportanceLevel.medium,
          customs: '游行、集会',
          foods: '野餐食品',
          greetings: '劳动节快乐！',
          activities: '户外活动、旅游',
          history: '劳动节起源于19世纪美国工人争取八小时工作制的运动。',
          imageUrl: 'assets/images/holidays/labour_day.jpg',
          userImportance: 1,
          names: {
            'zh': '劳动节',
            'en': 'Labour Day',
            'ja': '労働節',
            'ko': '노동절',
            'fr': 'Fête du Travail',
            'de': 'Tag der Arbeit',
          },
          descriptions: {
            'zh': '劳动节是庆祝工人阶级贡献的国际性节日，通常在5月1日。',
            'en': 'Labour Day is an international celebration of the contributions of workers, typically observed on May 1.',
            'ja': '労働節は、通常5月1日に行われる、労働者の貢献を祝う国際的な祝日です。',
            'ko': '노동절은 일반적으로 5월 1일에 관찰되는 노동자의 공헌을 축하하는 국제적인 축하 행사입니다.',
            'fr': 'La Fête du Travail est une célébration internationale des contributions des travailleurs, généralement observée le 1er mai.',
            'de': 'Der Tag der Arbeit ist eine internationale Feier der Beiträge der Arbeiter, die typischerweise am 1. Mai begangen wird.',
          },
        ),
      ];

      // 保存示例节日
      await _dbService.saveHolidays(holidays);

      debugPrint('成功创建 ${holidays.length} 个示例节日');
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
