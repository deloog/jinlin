import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jinlin_app/models/timeline_item.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/unified/reminder.dart';
import 'package:jinlin_app/routes/app_router.dart';
import 'package:jinlin_app/services/event/event_bus.dart';
import 'package:jinlin_app/services/holiday/holiday_repository.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/services/reminder/reminder_repository.dart';
import 'package:jinlin_app/utils/date_utils.dart';

/// 主屏幕业务逻辑
///
/// 管理主屏幕的数据和状态
class HomeBloc extends ChangeNotifier {
  final HolidayRepository _holidayRepository;
  final ReminderRepository _reminderRepository;
  final LoggingService _logger;

  // 时间线项目
  List<TimelineItem> _timelineItems = [];

  // 加载状态
  bool _isLoading = false;

  // 同步状态
  bool _isSyncing = false;

  // 错误状态
  bool _hasError = false;
  String? _errorMessage;

  // 事件订阅
  late StreamSubscription<HolidayDataUpdatedEvent> _holidayUpdateSubscription;
  late StreamSubscription<ReminderUpdatedEvent> _reminderUpdateSubscription;

  /// 获取时间线项目
  List<TimelineItem> get timelineItems => _timelineItems;

  /// 获取是否正在加载
  bool get isLoading => _isLoading;

  /// 获取是否正在同步
  bool get isSyncing => _isSyncing;

  /// 获取是否有错误
  bool get hasError => _hasError;

  /// 获取错误消息
  String? get errorMessage => _errorMessage;

  HomeBloc({
    required HolidayRepository holidayRepository,
    required ReminderRepository reminderRepository,
    required LoggingService logger,
  }) :
    _holidayRepository = holidayRepository,
    _reminderRepository = reminderRepository,
    _logger = logger {
    _logger.debug('初始化HomeBloc');

    // 订阅事件
    _holidayUpdateSubscription = eventBus.on<HolidayDataUpdatedEvent>().listen(_onHolidayDataUpdated);
    _reminderUpdateSubscription = eventBus.on<ReminderUpdatedEvent>().listen(_onReminderUpdated);
  }

  @override
  void dispose() {
    _logger.debug('销毁HomeBloc');

    // 取消事件订阅
    _holidayUpdateSubscription.cancel();
    _reminderUpdateSubscription.cancel();

    super.dispose();
  }

  /// 加载数据
  Future<void> loadData() async {
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _logger.debug('加载数据');
      debugPrint('开始加载数据');

      try {
        // 加载提醒事项
        debugPrint('开始加载提醒事项');
        final reminders = await _reminderRepository.getReminders();
        _logger.debug('加载了 ${reminders.length} 个提醒事项');
        debugPrint('加载了 ${reminders.length} 个提醒事项');

        // 加载节日
        debugPrint('开始加载节日');
        List<Holiday> holidays = [];
        try {
          debugPrint('使用Repository获取节日数据');
          holidays = await _holidayRepository.getHolidaysByRegion('CN', 'zh');
          _logger.debug('从Repository加载了 ${holidays.length} 个节日');
          debugPrint('从Repository加载了 ${holidays.length} 个节日');
        } catch (e, stack) {
          debugPrint('加载节日失败: $e');
          debugPrint('堆栈: $stack');

          // 如果Repository请求失败，使用模拟数据
          debugPrint('使用模拟数据');
          holidays = [
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
          ];
          _logger.debug('使用模拟数据，加载了 ${holidays.length} 个节日');
          debugPrint('使用模拟数据，加载了 ${holidays.length} 个节日');
        }

        // 加载全球节日
        debugPrint('开始加载全球节日');
        List<Holiday> globalHolidays = [];
        try {
          debugPrint('使用Repository获取全球节日数据');
          globalHolidays = await _holidayRepository.getGlobalHolidays('zh');
          _logger.debug('从Repository加载了 ${globalHolidays.length} 个全球节日');
          debugPrint('从Repository加载了 ${globalHolidays.length} 个全球节日');
        } catch (e, stack) {
          debugPrint('加载全球节日失败: $e');
          debugPrint('堆栈: $stack');

          // 如果Repository请求失败，使用模拟数据
          debugPrint('使用模拟数据');
          globalHolidays = [
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
          _logger.debug('使用模拟数据，加载了 ${globalHolidays.length} 个全球节日');
          debugPrint('使用模拟数据，加载了 ${globalHolidays.length} 个全球节日');
        }

        // 合并节日
        final allHolidays = [...holidays, ...globalHolidays];

        // 计算节日发生日期
        debugPrint('开始计算节日发生日期');
        final holidayOccurrences = _calculateHolidayOccurrences(allHolidays);
        _logger.debug('计算了 ${holidayOccurrences.length} 个节日发生日期');
        debugPrint('计算了 ${holidayOccurrences.length} 个节日发生日期');

        // 合并提醒事项和节日，并按日期排序
        debugPrint('开始合并时间线项目');
        _timelineItems = _mergeAndSortItems(reminders, holidayOccurrences);
        _logger.debug('合并了 ${_timelineItems.length} 个时间线项目');
        debugPrint('合并了 ${_timelineItems.length} 个时间线项目');
      } catch (innerError, innerStack) {
        debugPrint('加载数据内部错误: $innerError');
        debugPrint('内部堆栈: $innerStack');
        rethrow;
      }

      _isLoading = false;
      notifyListeners();
      debugPrint('数据加载完成');
    } catch (e, stack) {
      _logger.error('加载数据失败', e, stack);
      debugPrint('加载数据失败: $e');
      debugPrint('堆栈: $stack');

      _isLoading = false;
      _hasError = true;
      _errorMessage = '加载数据失败: $e';
      notifyListeners();
    }
  }

  /// 同步数据
  Future<void> syncData() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      _logger.debug('同步数据');

      // 同步节日
      final holidaySyncResult = await _holidayRepository.syncHolidays('CN', 'zh');
      _logger.debug('节日同步结果: $holidaySyncResult');

      // 同步提醒事项
      final reminderSyncResult = await _reminderRepository.syncReminders();
      _logger.debug('提醒事项同步结果: $reminderSyncResult');

      _isSyncing = false;
      notifyListeners();

      // 重新加载数据
      await loadData();
    } catch (e, stack) {
      _logger.error('同步数据失败', e, stack);

      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 计算节日发生日期
  List<HolidayOccurrence> _calculateHolidayOccurrences(List<Holiday> holidays) {
    final occurrences = <HolidayOccurrence>[];
    final now = DateTime.now();
    final startDate = DateTime(now.year, 1, 1);
    final endDate = DateTime(now.year + 1, 12, 31);

    for (final holiday in holidays) {
      try {
        final dates = AppDateUtils.calculateHolidayDates(
          holiday,
          startDate,
          endDate,
        );

        for (final date in dates) {
          occurrences.add(HolidayOccurrence(
            holiday: holiday,
            date: date,
          ));
        }
      } catch (e, stack) {
        _logger.error('计算节日日期失败: ${holiday.id}', e, stack);
      }
    }

    return occurrences;
  }

  /// 合并提醒事项和节日，并按日期排序
  List<TimelineItem> _mergeAndSortItems(
    List<Reminder> reminders,
    List<HolidayOccurrence> holidayOccurrences,
  ) {
    final items = <TimelineItem>[];

    // 添加提醒事项
    for (final reminder in reminders) {
      if (!reminder.isDeleted) {
        items.add(TimelineItem.reminder(
          date: reminder.getDateTime(),
          reminder: reminder,
        ));
      }
    }

    // 添加节日
    for (final occurrence in holidayOccurrences) {
      items.add(TimelineItem.holiday(
        date: occurrence.date,
        holiday: occurrence.holiday,
      ));
    }

    // 按日期排序
    items.sort((a, b) => a.date.compareTo(b.date));

    return items;
  }

  /// 导航到添加提醒页面
  void navigateToAddReminder(BuildContext context) {
    AppRouter.navigateToReminderDetail();
  }

  /// 显示节日过滤对话框
  void showHolidayFilter(BuildContext context) {
    // TODO: 实现节日过滤功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('节日过滤功能尚未实现'),
      ),
    );
  }

  /// 处理时间线项目点击事件
  void onTimelineItemTap(BuildContext context, TimelineItem item) {
    if (item.isHoliday) {
      AppRouter.navigateToHolidayDetail(
        item.holiday!,
        occurrenceDate: item.date,
      );
    } else if (item.isReminder) {
      AppRouter.navigateToReminderDetail(
        reminder: item.reminder,
        isEditing: true,
      );
    }
  }

  /// 处理节日数据更新事件
  void _onHolidayDataUpdated(HolidayDataUpdatedEvent event) {
    _logger.debug('收到节日数据更新事件: ${event.regionCode}, ${event.itemCount}');

    // 重新加载数据
    loadData();
  }

  /// 处理提醒事项更新事件
  void _onReminderUpdated(ReminderUpdatedEvent event) {
    _logger.debug('收到提醒事项更新事件: ${event.reminderId}');

    // 重新加载数据
    loadData();
  }
}
