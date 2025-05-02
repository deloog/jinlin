import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/database/database_interface.dart';
import 'package:jinlin_app/services/database/database_factory.dart';
import 'package:jinlin_app/services/localization_service.dart';

/// 节日数据初始化服务
///
/// 负责初始化系统预设节日数据，只在首次启动或数据版本更新时执行
class HolidayInitServiceUnified {
  static final HolidayInitServiceUnified _instance = HolidayInitServiceUnified._internal();

  factory HolidayInitServiceUnified() {
    return _instance;
  }

  HolidayInitServiceUnified._internal();

  // 数据库服务
  final DatabaseInterface _db = kIsWeb
      ? DatabaseFactory.create(DatabaseType.hive)
      : DatabaseFactory.create(DatabaseType.sqlite);

  // UUID生成器 - 在将来的功能中会使用
  // final Uuid _uuid = Uuid();

  /// 当前数据版本
  /// 每次更新节日数据时递增
  static const int currentDataVersion = 1;

  /// 初始化节日数据
  ///
  /// 只在首次启动或数据版本更新时执行
  Future<void> initializeHolidayData(BuildContext? context) async {
    try {
      // 初始化数据库
      await _db.initialize();

      // 检查是否是首次启动
      final isFirstLaunch = await _db.isFirstLaunch();

      // 获取当前数据版本
      final dataVersion = await _db.getDataVersion();

      // 首次启动或数据版本更新时初始化/更新系统节日
      if (isFirstLaunch || dataVersion < currentDataVersion) {
        debugPrint('首次启动或数据版本更新，初始化系统节日数据');

        // 获取用户地区
        final String userRegion;
        if (context != null && context.mounted) {
          userRegion = LocalizationService.getUserRegion(context);
        } else {
          userRegion = 'CN'; // 默认使用中国地区
          debugPrint('警告：BuildContext为null或已失效，使用默认地区(CN)');
        }

        // 加载适合该地区的系统节日
        final systemHolidays = _getSystemHolidays(userRegion);

        // 保存系统节日到数据库
        await _db.saveHolidays(systemHolidays);

        // 标记首次启动完成
        if (isFirstLaunch) {
          await _db.markFirstLaunchComplete();
        }

        // 更新数据版本
        if (dataVersion < currentDataVersion) {
          await _db.updateDataVersion(currentDataVersion);
        }

        debugPrint('系统节日数据初始化完成');
      } else {
        debugPrint('非首次启动且数据版本最新，跳过系统节日数据初始化');
      }
    } catch (e) {
      debugPrint('初始化节日数据失败: $e');
      rethrow;
    }
  }

  /// 获取系统预设节日
  ///
  /// 根据用户地区返回适合的系统预设节日
  List<Holiday> _getSystemHolidays(String region) {
    // 全球通用节日
    final globalHolidays = _getGlobalHolidays();

    // 地区特定节日
    final regionHolidays = _getRegionHolidays(region);

    // 合并节日列表
    return [...globalHolidays, ...regionHolidays];
  }

  /// 获取全球通用节日
  List<Holiday> _getGlobalHolidays() {
    return [
      // 新年
      Holiday(
        id: 'global_new_year',
        isSystemHoliday: true,
        names: {
          'zh': '新年',
          'en': 'New Year\'s Day',
          'ja': '元旦',
          'ko': '신정',
          'fr': 'Jour de l\'An',
          'de': 'Neujahr',
        },
        type: HolidayType.statutory,
        regions: ['ALL'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '01-01',
        descriptions: {
          'zh': '新年是世界各地普遍庆祝的节日，标志着新一年的开始。人们通常会举行各种庆祝活动，如烟花表演、家庭聚会等。',
          'en': 'New Year\'s Day is a global holiday celebrating the beginning of a new calendar year. People typically celebrate with fireworks, parties, and family gatherings.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '放烟花、倒数计时、新年愿望',
          'en': 'Fireworks, countdown, New Year resolutions',
        },
        foods: {
          'zh': '年夜饭、香槟',
          'en': 'New Year\'s Eve dinner, champagne',
        },
        greetings: {
          'zh': '新年快乐！',
          'en': 'Happy New Year!',
        },
        activities: {
          'zh': '跨年晚会、家庭聚餐',
          'en': 'New Year\'s Eve party, family gathering',
        },
        history: {
          'zh': '新年庆祝活动可以追溯到古罗马时期。',
          'en': 'New Year celebrations can be traced back to ancient Roman times.',
        },
        userImportance: 2,
      ),

      // 情人节
      Holiday(
        id: 'global_valentines_day',
        isSystemHoliday: true,
        names: {
          'zh': '情人节',
          'en': 'Valentine\'s Day',
          'ja': 'バレンタインデー',
          'ko': '발렌타인 데이',
          'fr': 'Saint-Valentin',
          'de': 'Valentinstag',
        },
        type: HolidayType.traditional,
        regions: ['ALL'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '02-14',
        descriptions: {
          'zh': '情人节是恋人之间互表爱意的节日，通常会赠送鲜花、巧克力和贺卡。',
          'en': 'Valentine\'s Day is a holiday when lovers express their affection with greetings and gifts. It is celebrated in many countries around the world.',
        },
        importanceLevel: ImportanceLevel.medium,
        customs: {
          'zh': '送花、送巧克力、送贺卡',
          'en': 'Giving flowers, chocolates, and cards',
        },
        userImportance: 1,
      ),

      // 国际劳动节
      Holiday(
        id: 'global_labor_day',
        isSystemHoliday: true,
        names: {
          'zh': '国际劳动节',
          'en': 'International Labor Day',
          'ja': '国際労働者の日',
          'ko': '국제 노동절',
          'fr': 'Fête du Travail',
          'de': 'Tag der Arbeit',
        },
        type: HolidayType.statutory,
        regions: ['ALL'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '05-01',
        descriptions: {
          'zh': '国际劳动节是世界上许多国家的法定假日，旨在庆祝工人阶级的贡献和成就。',
          'en': 'International Labor Day, also known as May Day, is a celebration of laborers and the working classes.',
        },
        importanceLevel: ImportanceLevel.high,
        userImportance: 2,
      ),

      // 圣诞节
      Holiday(
        id: 'global_christmas',
        isSystemHoliday: true,
        names: {
          'zh': '圣诞节',
          'en': 'Christmas',
          'ja': 'クリスマス',
          'ko': '크리스마스',
          'fr': 'Noël',
          'de': 'Weihnachten',
        },
        type: HolidayType.statutory,
        regions: ['ALL'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '12-25',
        descriptions: {
          'zh': '圣诞节是基督教纪念耶稣诞生的节日，现已成为全球性的文化节日，人们会交换礼物、装饰圣诞树，与家人团聚。',
          'en': 'Christmas is an annual festival commemorating the birth of Jesus Christ. It is widely celebrated around the world, both as a religious and cultural event.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '装饰圣诞树、交换礼物、唱圣诞歌',
          'en': 'Decorating Christmas tree, exchanging gifts, singing carols',
        },
        foods: {
          'zh': '火鸡、圣诞蛋糕',
          'en': 'Turkey, Christmas cake',
        },
        userImportance: 2,
      ),
    ];
  }

  /// 获取地区特定节日
  List<Holiday> _getRegionHolidays(String region) {
    switch (region) {
      case 'CN':
        return _getChineseHolidays();
      case 'US':
        return _getUSHolidays();
      case 'JP':
        return _getJapaneseHolidays();
      case 'KR':
        return _getKoreanHolidays();
      default:
        return [];
    }
  }

  /// 获取中国特定节日
  List<Holiday> _getChineseHolidays() {
    return [
      // 春节
      Holiday(
        id: 'cn_spring_festival',
        isSystemHoliday: true,
        names: {
          'zh': '春节',
          'en': 'Spring Festival',
          'ja': '春節',
          'ko': '춘절',
        },
        type: HolidayType.traditional,
        regions: ['CN', 'HK', 'TW', 'SG'],
        calculationType: DateCalculationType.fixedLunar,
        calculationRule: 'L01-01',
        descriptions: {
          'zh': '春节是中国最重要的传统节日，庆祝农历新年的开始。',
          'en': 'Spring Festival is the most important traditional festival in China, celebrating the beginning of the lunar new year.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '贴春联、放鞭炮、给红包',
          'en': 'Putting up spring couplets, setting off firecrackers, giving red envelopes',
        },
        foods: {
          'zh': '饺子、年糕、鱼',
          'en': 'Dumplings, rice cake, fish',
        },
        greetings: {
          'zh': '新年快乐！恭喜发财！',
          'en': 'Happy New Year! Wish you prosperity!',
        },
        activities: {
          'zh': '家庭团聚、看春晚、拜年',
          'en': 'Family reunion, watching Spring Festival Gala, paying New Year visits',
        },
        history: {
          'zh': '春节有超过4000年的历史，起源于中国古代的祭祀活动。',
          'en': 'Spring Festival has a history of over 4,000 years, originating from ancient Chinese sacrificial ceremonies.',
        },
        userImportance: 2,
      ),

      // 清明节
      Holiday(
        id: 'cn_qingming_festival',
        isSystemHoliday: true,
        names: {
          'zh': '清明节',
          'en': 'Qingming Festival',
          'ja': '清明節',
          'ko': '청명절',
        },
        type: HolidayType.traditional,
        regions: ['CN', 'HK', 'TW'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '04-05',
        descriptions: {
          'zh': '清明节是中国传统节日，人们在这一天扫墓祭祖，缅怀逝去的亲人。',
          'en': 'Qingming Festival is a traditional Chinese festival when people visit the graves of their ancestors to pay their respects.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '扫墓、祭祖、踏青',
          'en': 'Tomb sweeping, ancestor worship, spring outing',
        },
        userImportance: 2,
      ),

      // 端午节
      Holiday(
        id: 'cn_dragon_boat_festival',
        isSystemHoliday: true,
        names: {
          'zh': '端午节',
          'en': 'Dragon Boat Festival',
          'ja': '端午節',
          'ko': '단오절',
        },
        type: HolidayType.traditional,
        regions: ['CN', 'HK', 'TW'],
        calculationType: DateCalculationType.fixedLunar,
        calculationRule: 'L05-05',
        descriptions: {
          'zh': '端午节是中国传统节日，纪念爱国诗人屈原，人们会吃粽子、赛龙舟。',
          'en': 'Dragon Boat Festival is a traditional Chinese festival commemorating the patriotic poet Qu Yuan. People eat zongzi (rice dumplings) and hold dragon boat races.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '吃粽子、赛龙舟、挂艾草',
          'en': 'Eating zongzi, dragon boat racing, hanging mugwort',
        },
        userImportance: 2,
      ),

      // 中秋节
      Holiday(
        id: 'cn_mid_autumn_festival',
        isSystemHoliday: true,
        names: {
          'zh': '中秋节',
          'en': 'Mid-Autumn Festival',
          'ja': '中秋節',
          'ko': '추석',
        },
        type: HolidayType.traditional,
        regions: ['CN', 'HK', 'TW', 'SG'],
        calculationType: DateCalculationType.fixedLunar,
        calculationRule: 'L08-15',
        descriptions: {
          'zh': '中秋节是中国传统节日，象征着团圆和丰收，人们会赏月、吃月饼。',
          'en': 'Mid-Autumn Festival is a traditional Chinese festival symbolizing reunion and harvest. People admire the full moon and eat mooncakes.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '赏月、吃月饼、赏花灯',
          'en': 'Moon viewing, eating mooncakes, admiring lanterns',
        },
        userImportance: 2,
      ),

      // 国庆节
      Holiday(
        id: 'cn_national_day',
        isSystemHoliday: true,
        names: {
          'zh': '国庆节',
          'en': 'National Day',
          'ja': '国慶節',
          'ko': '국경절',
        },
        type: HolidayType.statutory,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '10-01',
        descriptions: {
          'zh': '国庆节是中华人民共和国成立的纪念日，是中国的法定假日。',
          'en': 'National Day is a statutory holiday in China commemorating the founding of the People\'s Republic of China.',
        },
        importanceLevel: ImportanceLevel.high,
        userImportance: 2,
      ),
    ];
  }

  /// 获取美国特定节日
  List<Holiday> _getUSHolidays() {
    return [
      // 独立日
      Holiday(
        id: 'us_independence_day',
        isSystemHoliday: true,
        names: {
          'zh': '美国独立日',
          'en': 'Independence Day',
        },
        type: HolidayType.statutory,
        regions: ['US'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '07-04',
        descriptions: {
          'zh': '独立日是美国的国庆节，纪念1776年7月4日《独立宣言》的签署。',
          'en': 'Independence Day is the national day of the United States, commemorating the signing of the Declaration of Independence on July 4, 1776.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '烟花表演、游行、烧烤',
          'en': 'Fireworks, parades, barbecues',
        },
        userImportance: 2,
      ),

      // 感恩节
      Holiday(
        id: 'us_thanksgiving',
        isSystemHoliday: true,
        names: {
          'zh': '感恩节',
          'en': 'Thanksgiving',
        },
        type: HolidayType.statutory,
        regions: ['US'],
        calculationType: DateCalculationType.variableRule,
        calculationRule: '11-4-4', // 11月第4个星期四
        descriptions: {
          'zh': '感恩节是美国和加拿大的重要节日，人们在这一天感谢生活中的美好事物，与家人团聚共进晚餐。',
          'en': 'Thanksgiving is an important holiday in the United States and Canada. People gather with family for a festive meal and give thanks for the blessings in their lives.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '家庭聚餐、感恩祈祷',
          'en': 'Family dinner, giving thanks',
        },
        foods: {
          'zh': '火鸡、南瓜派、蔓越莓酱',
          'en': 'Turkey, pumpkin pie, cranberry sauce',
        },
        userImportance: 2,
      ),

      // 纪念日
      Holiday(
        id: 'us_memorial_day',
        isSystemHoliday: true,
        names: {
          'zh': '阵亡将士纪念日',
          'en': 'Memorial Day',
        },
        type: HolidayType.memorial,
        regions: ['US'],
        calculationType: DateCalculationType.variableRule,
        calculationRule: '05-5-1', // 5月最后一个星期一
        descriptions: {
          'zh': '阵亡将士纪念日是美国的联邦假日，纪念为国牺牲的军人。',
          'en': 'Memorial Day is a federal holiday in the United States for honoring and mourning the military personnel who died while serving in the United States Armed Forces.',
        },
        importanceLevel: ImportanceLevel.high,
        userImportance: 2,
      ),
    ];
  }

  /// 获取日本特定节日
  List<Holiday> _getJapaneseHolidays() {
    return [
      // 黄金周
      Holiday(
        id: 'jp_golden_week',
        isSystemHoliday: true,
        names: {
          'zh': '黄金周',
          'en': 'Golden Week',
          'ja': 'ゴールデンウィーク',
        },
        type: HolidayType.statutory,
        regions: ['JP'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '04-29', // 开始日期
        descriptions: {
          'zh': '黄金周是日本的一系列连续假日，从4月29日持续到5月初。',
          'en': 'Golden Week is a series of consecutive holidays in Japan, starting from April 29 and lasting until early May.',
          'ja': 'ゴールデンウィークは4月29日から5月初めまで続く、日本の連休です。',
        },
        importanceLevel: ImportanceLevel.high,
        userImportance: 2,
      ),

      // 七夕
      Holiday(
        id: 'jp_tanabata',
        isSystemHoliday: true,
        names: {
          'zh': '七夕',
          'en': 'Tanabata',
          'ja': '七夕',
        },
        type: HolidayType.traditional,
        regions: ['JP'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '07-07',
        descriptions: {
          'zh': '七夕是日本的传统节日，源自中国，庆祝牛郎与织女一年一度的相会。',
          'en': 'Tanabata is a Japanese festival originating from China, celebrating the meeting of the deities Orihime and Hikoboshi.',
          'ja': '七夕は中国から伝わった日本の伝統的な祭りで、織姫と彦星の年に一度の出会いを祝います。',
        },
        importanceLevel: ImportanceLevel.medium,
        customs: {
          'zh': '写愿望、挂装饰',
          'en': 'Writing wishes, hanging decorations',
          'ja': '願い事を書く、飾りを吊るす',
        },
        userImportance: 1,
      ),

      // 成人节
      Holiday(
        id: 'jp_coming_of_age_day',
        isSystemHoliday: true,
        names: {
          'zh': '成人节',
          'en': 'Coming of Age Day',
          'ja': '成人の日',
        },
        type: HolidayType.statutory,
        regions: ['JP'],
        calculationType: DateCalculationType.variableRule,
        calculationRule: '01-2-1', // 1月第2个星期一
        descriptions: {
          'zh': '成人节是日本的法定假日，庆祝年满20岁的年轻人成年。',
          'en': 'Coming of Age Day is a Japanese holiday celebrating young people who have reached the age of 20.',
          'ja': '成人の日は20歳になった若者の成人を祝う日本の祝日です。',
        },
        importanceLevel: ImportanceLevel.medium,
        userImportance: 1,
      ),
    ];
  }

  /// 获取韩国特定节日
  List<Holiday> _getKoreanHolidays() {
    return [
      // 韩国春节（设尔节）
      Holiday(
        id: 'kr_seollal',
        isSystemHoliday: true,
        names: {
          'zh': '设尔节',
          'en': 'Seollal',
          'ko': '설날',
        },
        type: HolidayType.traditional,
        regions: ['KR'],
        calculationType: DateCalculationType.fixedLunar,
        calculationRule: 'L01-01',
        descriptions: {
          'zh': '设尔节是韩国的春节，是韩国最重要的传统节日之一。',
          'en': 'Seollal is Korean New Year and one of the most important traditional Korean holidays.',
          'ko': '설날은 한국의 새해맞이 명절로, 한국의 가장 중요한 전통 명절 중 하나입니다.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '祭祀祖先、穿韩服、玩民俗游戏',
          'en': 'Ancestral rites, wearing hanbok, playing traditional games',
          'ko': '차례, 한복 입기, 민속놀이',
        },
        userImportance: 2,
      ),

      // 中秋节（秋夕）
      Holiday(
        id: 'kr_chuseok',
        isSystemHoliday: true,
        names: {
          'zh': '秋夕',
          'en': 'Chuseok',
          'ko': '추석',
        },
        type: HolidayType.traditional,
        regions: ['KR'],
        calculationType: DateCalculationType.fixedLunar,
        calculationRule: 'L08-15',
        descriptions: {
          'zh': '秋夕是韩国的中秋节，是韩国三大传统节日之一，人们会祭祀祖先、团聚和享用传统食物。',
          'en': 'Chuseok is Korean Thanksgiving Day and one of the three major traditional holidays in Korea. People perform ancestral rites, gather with family, and enjoy traditional food.',
          'ko': '추석은 한국의 추수감사절이자 한국의 3대 명절 중 하나입니다. 사람들은 차례를 지내고, 가족과 모여 전통 음식을 즐깁니다.',
        },
        importanceLevel: ImportanceLevel.high,
        customs: {
          'zh': '祭祀祖先、访问祖坟、吃松糕',
          'en': 'Ancestral rites, visiting ancestral graves, eating songpyeon',
          'ko': '차례, 성묘, 송편 먹기',
        },
        userImportance: 2,
      ),
    ];
  }
}
