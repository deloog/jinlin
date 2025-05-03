import 'package:flutter/foundation.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/services/api/api_client.dart';
import 'package:jinlin_app/services/api/api_endpoints.dart';
import 'package:jinlin_app/services/api/api_exception.dart';
import 'package:jinlin_app/services/database/database_service.dart';
import 'package:jinlin_app/services/event/event_bus.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';

/// 节日数据仓库
class HolidayRepository {
  final ApiClient _apiClient;
  final DatabaseService _databaseService;
  final EventBus _eventBus;
  final LoggingService _logger = LoggingService();

  // 是否正在同步
  bool _isSyncing = false;

  // 同步状态
  String _syncStatus = '空闲';

  // 上次同步时间
  DateTime? _lastSyncTime;

  /// 获取同步状态
  String get syncStatus => _syncStatus;

  /// 获取上次同步时间
  DateTime? get lastSyncTime => _lastSyncTime;

  /// 获取是否正在同步
  bool get isSyncing => _isSyncing;
  
  /// 获取API客户端
  ApiClient get apiClient => _apiClient;

  HolidayRepository({
    required ApiClient apiClient,
    required DatabaseService databaseService,
    required EventBus eventBus,
  })  : _apiClient = apiClient,
        _databaseService = databaseService,
        _eventBus = eventBus {
    _logger.info('初始化节日数据仓库');
  }

  /// 获取特定地区和语言的节日
  Future<List<Holiday>> getHolidaysByRegion(String regionCode, String languageCode) async {
    try {
      _logger.debug('获取 $regionCode 地区的节日数据，语言: $languageCode');
      debugPrint('获取 $regionCode 地区的节日数据，语言: $languageCode');

      // 直接返回模拟数据
      debugPrint('直接返回模拟数据');
      final holidays = [
        Holiday(
          id: 'spring-festival',
          names: {'zh': '春节', 'en': 'Spring Festival'},
          type: HolidayType.traditional,
          regions: ['CN'],
          calculationType: DateCalculationType.fixedLunar,
          calculationRule: '1-1',
          descriptions: {'zh': '春节是中国最重要的传统节日，标志着农历新年的开始。', 'en': 'Spring Festival is the most important traditional festival in China, marking the beginning of the lunar new year.'},
          importanceLevel: ImportanceLevel.high,
          customs: {'zh': '贴春联、放鞭炮、吃团圆饭', 'en': 'Putting up spring couplets, setting off firecrackers, having reunion dinner'},
          taboos: {'zh': '打破物品、说不吉利的话', 'en': 'Breaking things, saying unlucky words'},
          foods: {'zh': '饺子、年糕、鱼', 'en': 'Dumplings, rice cake, fish'},
          greetings: {'zh': '新年快乐、恭喜发财', 'en': 'Happy New Year, Wish you wealth'},
          activities: {'zh': '舞龙舞狮、拜年', 'en': 'Dragon and lion dance, paying New Year visits'},
          history: {'zh': '春节起源于上古时期，是中华民族最古老的传统节日之一。', 'en': 'Spring Festival originated in ancient times and is one of the oldest traditional festivals of the Chinese nation.'},
          imageUrl: 'https://example.com/spring-festival.jpg',
          userImportance: 5,
          isSystemHoliday: true,
          createdAt: DateTime.now(),
        ),
        Holiday(
          id: 'mid-autumn-festival',
          names: {'zh': '中秋节', 'en': 'Mid-Autumn Festival'},
          type: HolidayType.traditional,
          regions: ['CN'],
          calculationType: DateCalculationType.fixedLunar,
          calculationRule: '8-15',
          descriptions: {'zh': '中秋节是中国传统的团圆节日，在农历八月十五。', 'en': 'Mid-Autumn Festival is a traditional Chinese festival for family reunions, on the 15th day of the 8th lunar month.'},
          importanceLevel: ImportanceLevel.high,
          customs: {'zh': '赏月、吃月饼', 'en': 'Moon viewing, eating mooncakes'},
          taboos: {'zh': '不宜远行', 'en': 'Not suitable for long journeys'},
          foods: {'zh': '月饼、柚子', 'en': 'Mooncakes, pomelo'},
          greetings: {'zh': '中秋快乐、月圆人团圆', 'en': 'Happy Mid-Autumn Festival, May the moon be round and the family be reunited'},
          activities: {'zh': '赏月、猜灯谜', 'en': 'Moon viewing, guessing lantern riddles'},
          history: {'zh': '中秋节起源于古代对月亮的崇拜和秋季丰收的庆祝。', 'en': 'Mid-Autumn Festival originated from the worship of the moon and the celebration of autumn harvest in ancient times.'},
          imageUrl: 'https://example.com/mid-autumn.jpg',
          userImportance: 4,
          isSystemHoliday: true,
          createdAt: DateTime.now(),
        ),
        Holiday(
          id: 'dragon-boat-festival',
          names: {'zh': '端午节', 'en': 'Dragon Boat Festival'},
          type: HolidayType.traditional,
          regions: ['CN'],
          calculationType: DateCalculationType.fixedLunar,
          calculationRule: '5-5',
          descriptions: {'zh': '端午节是中国传统节日，纪念爱国诗人屈原。', 'en': 'Dragon Boat Festival is a traditional Chinese festival commemorating the patriotic poet Qu Yuan.'},
          importanceLevel: ImportanceLevel.high,
          customs: {'zh': '赛龙舟、挂艾草', 'en': 'Dragon boat racing, hanging mugwort'},
          taboos: {'zh': '不宜游泳', 'en': 'Not suitable for swimming'},
          foods: {'zh': '粽子、咸鸭蛋', 'en': 'Zongzi, salted duck eggs'},
          greetings: {'zh': '端午安康', 'en': 'Wish you health on Dragon Boat Festival'},
          activities: {'zh': '赛龙舟、包粽子', 'en': 'Dragon boat racing, making zongzi'},
          history: {'zh': '端午节起源于对屈原的纪念，他是中国古代伟大的爱国诗人。', 'en': 'Dragon Boat Festival originated from the commemoration of Qu Yuan, a great patriotic poet in ancient China.'},
          imageUrl: 'https://example.com/dragon-boat.jpg',
          userImportance: 3,
          isSystemHoliday: true,
          createdAt: DateTime.now(),
        ),
      ];

      debugPrint('返回 ${holidays.length} 个节日');
      return holidays;
    } catch (e, stack) {
      _logger.error('获取节日数据失败', e, stack);
      return [];
    }
  }

  /// 获取全球节日
  Future<List<Holiday>> getGlobalHolidays(String languageCode) async {
    try {
      _logger.debug('获取全球节日数据，语言: $languageCode');
      debugPrint('获取全球节日数据，语言: $languageCode');

      // 直接返回模拟数据
      debugPrint('直接返回全球节日模拟数据');
      final holidays = [
        Holiday(
          id: 'new-year',
          names: {'zh': '元旦', 'en': 'New Year\'s Day'},
          type: HolidayType.international,
          regions: ['GLOBAL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '01-01',
          descriptions: {'zh': '元旦是世界各国普遍庆祝的节日，标志着新一年的开始。', 'en': 'New Year\'s Day is a holiday celebrated around the world, marking the beginning of a new year.'},
          importanceLevel: ImportanceLevel.high,
          customs: {'zh': '跨年倒计时、烟花表演', 'en': 'New Year countdown, fireworks display'},
          taboos: {'zh': '不宜打碎物品', 'en': 'Avoid breaking things'},
          foods: {'zh': '年夜饭', 'en': 'New Year\'s Eve dinner'},
          greetings: {'zh': '新年快乐', 'en': 'Happy New Year'},
          activities: {'zh': '跨年晚会、许愿', 'en': 'New Year\'s Eve party, making wishes'},
          history: {'zh': '元旦起源于古罗马时期，是西方传统节日。', 'en': 'New Year\'s Day originated in ancient Rome and is a traditional Western holiday.'},
          imageUrl: 'https://example.com/new-year.jpg',
          userImportance: 5,
          isSystemHoliday: true,
          createdAt: DateTime.now(),
        ),
        Holiday(
          id: 'christmas',
          names: {'zh': '圣诞节', 'en': 'Christmas'},
          type: HolidayType.religious,
          regions: ['GLOBAL'],
          calculationType: DateCalculationType.fixedGregorian,
          calculationRule: '12-25',
          descriptions: {'zh': '圣诞节是基督教纪念耶稣诞生的重要节日。', 'en': 'Christmas is an important Christian holiday commemorating the birth of Jesus.'},
          importanceLevel: ImportanceLevel.high,
          customs: {'zh': '装饰圣诞树、交换礼物', 'en': 'Decorating Christmas trees, exchanging gifts'},
          taboos: {'zh': '不宜悲观消极', 'en': 'Avoid being pessimistic'},
          foods: {'zh': '火鸡、姜饼', 'en': 'Turkey, gingerbread'},
          greetings: {'zh': '圣诞快乐', 'en': 'Merry Christmas'},
          activities: {'zh': '唱圣诞颂歌、圣诞晚会', 'en': 'Singing Christmas carols, Christmas parties'},
          history: {'zh': '圣诞节起源于基督教传统，纪念耶稣的诞生。', 'en': 'Christmas originated from Christian traditions, commemorating the birth of Jesus.'},
          imageUrl: 'https://example.com/christmas.jpg',
          userImportance: 4,
          isSystemHoliday: true,
          createdAt: DateTime.now(),
        ),
      ];

      debugPrint('返回 ${holidays.length} 个全球节日');
      return holidays;
    } catch (e, stack) {
      _logger.error('获取全球节日数据失败', e, stack);
      return [];
    }
  }
  
  /// 同步节日数据
  Future<bool> syncHolidays(String regionCode, String languageCode) async {
    try {
      _logger.debug('同步节日数据: $regionCode, $languageCode');
      debugPrint('同步节日数据: $regionCode, $languageCode');
      
      // 模拟同步成功
      debugPrint('模拟同步成功');
      return true;
    } catch (e, stack) {
      _logger.error('同步节日数据失败', e, stack);
      return false;
    }
  }
}
