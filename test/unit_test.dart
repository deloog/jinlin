import 'package:flutter_test/flutter_test.dart';
import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/unified/reminder.dart';
import 'package:jinlin_app/utils/date_utils.dart';
import 'package:jinlin_app/utils/string_utils.dart';

void main() {
  group('Holiday Model Tests', () {
    test('Holiday creation and serialization', () {
      final holiday = Holiday(
        id: '1',
        names: {'zh': 'Test Holiday'},
        type: HolidayType.traditional,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '01-01',
        descriptions: {'zh': 'Test Description'},
      );

      // 测试属性
      expect(holiday.id, equals('1'));
      expect(holiday.names['zh'], equals('Test Holiday'));
      expect(holiday.descriptions['zh'], equals('Test Description'));
      expect(holiday.type, equals(HolidayType.traditional));
      expect(holiday.regions, contains('CN'));
      expect(holiday.calculationType, equals(DateCalculationType.fixedGregorian));
      expect(holiday.calculationRule, equals('01-01'));

      // 测试Map转换
      final map = holiday.toMap();
      expect(map['id'], equals('1'));
      expect(map['type_id'], equals(HolidayType.traditional.index));
      expect(map['calculation_type_id'], equals(DateCalculationType.fixedGregorian.index));
      expect(map['calculation_rule'], equals('01-01'));

      // 测试从Map创建
      final deserializedHoliday = Holiday.fromMap(map);
      expect(deserializedHoliday.id, equals('1'));
      expect(deserializedHoliday.type, equals(HolidayType.traditional));
      expect(deserializedHoliday.calculationType, equals(DateCalculationType.fixedGregorian));
      expect(deserializedHoliday.calculationRule, equals('01-01'));
    });

    test('Holiday getLocalizedName method', () {
      final holiday = Holiday(
        id: '1',
        names: {'zh': '中文节日', 'en': 'English Holiday'},
        type: HolidayType.traditional,
        regions: ['CN', 'US'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '01-01',
      );

      // 测试本地化名称
      expect(holiday.getLocalizedName('zh'), equals('中文节日'));
      expect(holiday.getLocalizedName('en'), equals('English Holiday'));
      expect(holiday.getLocalizedName('fr'), equals('English Holiday')); // 回退到英文

      // 测试简化方法
      expect(holiday.getName('zh'), equals('中文节日'));
      expect(holiday.getName('en'), equals('English Holiday'));
    });
  });

  group('Reminder Model Tests', () {
    test('Reminder creation and serialization', () {
      final reminder = Reminder(
        id: '1',
        title: 'Test Reminder',
        description: 'Test Description',
        date: '2023-01-01',
        time: '12:00',
        isCompleted: false,
        isRecurring: false,
        importance: 2,
      );

      // 测试属性
      expect(reminder.id, equals('1'));
      expect(reminder.title, equals('Test Reminder'));
      expect(reminder.description, equals('Test Description'));
      expect(reminder.date, equals('2023-01-01'));
      expect(reminder.time, equals('12:00'));
      expect(reminder.importance, equals(2));
      expect(reminder.isCompleted, equals(false));
      expect(reminder.isRecurring, equals(false));

      // 测试JSON序列化
      final json = reminder.toJson();
      expect(json['id'], equals('1'));
      expect(json['title'], equals('Test Reminder'));
      expect(json['description'], equals('Test Description'));
      expect(json['date'], equals('2023-01-01'));
      expect(json['time'], equals('12:00'));
      expect(json['importance'], equals(2));
      expect(json['is_completed'], equals(false));
      expect(json['is_recurring'], equals(false));

      // 测试JSON反序列化
      final deserializedReminder = Reminder.fromJson(json);
      expect(deserializedReminder.id, equals('1'));
      expect(deserializedReminder.title, equals('Test Reminder'));
      expect(deserializedReminder.description, equals('Test Description'));
      expect(deserializedReminder.date, equals('2023-01-01'));
      expect(deserializedReminder.time, equals('12:00'));
      expect(deserializedReminder.importance, equals(2));
      expect(deserializedReminder.isCompleted, equals(false));
      expect(deserializedReminder.isRecurring, equals(false));
    });

    test('Reminder copyWith method', () {
      final reminder = Reminder(
        id: '1',
        title: 'Test Reminder',
        description: 'Test Description',
        date: '2023-01-01',
        time: '12:00',
        importance: 1,
        isCompleted: false,
        isRecurring: false,
      );

      final updatedReminder = reminder.copyWith(
        title: 'Updated Reminder',
        description: 'Updated Description',
        importance: 2,
        isCompleted: true,
      );

      // 测试更新的属性
      expect(updatedReminder.id, equals('1')); // 未更改
      expect(updatedReminder.title, equals('Updated Reminder')); // 已更改
      expect(updatedReminder.description, equals('Updated Description')); // 已更改
      expect(updatedReminder.date, equals('2023-01-01')); // 未更改
      expect(updatedReminder.time, equals('12:00')); // 未更改
      expect(updatedReminder.importance, equals(2)); // 已更改
      expect(updatedReminder.isCompleted, equals(true)); // 已更改
      expect(updatedReminder.isRecurring, equals(false)); // 未更改
    });

    test('Reminder markAsCompleted method', () {
      final reminder = Reminder(
        id: '1',
        title: 'Test Reminder',
        description: 'Test Description',
        date: '2023-01-01',
        time: '12:00',
        importance: 1,
        isCompleted: false,
        isRecurring: false,
      );

      final completedReminder = reminder.markAsCompleted();

      // 测试更新的属性
      expect(completedReminder.isCompleted, equals(true));
    });

    test('Reminder markAsIncomplete method', () {
      final reminder = Reminder(
        id: '1',
        title: 'Test Reminder',
        description: 'Test Description',
        date: '2023-01-01',
        time: '12:00',
        importance: 1,
        isCompleted: true,
        isRecurring: false,
      );

      final incompleteReminder = reminder.markAsIncomplete();

      // 测试更新的属性
      expect(incompleteReminder.isCompleted, equals(false));
    });
  });

  group('DateUtils Tests', () {
    test('formatDate method', () {
      final date = DateTime(2023, 1, 1);
      expect(AppDateUtils.formatDate(date), equals('2023-01-01'));
    });

    test('formatTime method', () {
      final time = DateTime(2023, 1, 1, 12, 30);
      expect(AppDateUtils.formatTime(time), equals('12:30'));
    });

    test('formatDateTime method', () {
      final dateTime = DateTime(2023, 1, 1, 12, 30);
      expect(AppDateUtils.formatDateTime(dateTime), equals('2023-01-01 12:30'));
    });

    test('today method', () {
      final now = DateTime.now();
      final today = AppDateUtils.today();
      expect(today.year, equals(now.year));
      expect(today.month, equals(now.month));
      expect(today.day, equals(now.day));
      expect(today.hour, equals(0));
      expect(today.minute, equals(0));
      expect(today.second, equals(0));
      expect(today.millisecond, equals(0));
    });

    test('tomorrow method', () {
      final now = DateTime.now();
      final tomorrow = AppDateUtils.tomorrow();
      final expectedTomorrow = DateTime(now.year, now.month, now.day + 1);
      expect(tomorrow.year, equals(expectedTomorrow.year));
      expect(tomorrow.month, equals(expectedTomorrow.month));
      expect(tomorrow.day, equals(expectedTomorrow.day));
      expect(tomorrow.hour, equals(0));
      expect(tomorrow.minute, equals(0));
      expect(tomorrow.second, equals(0));
      expect(tomorrow.millisecond, equals(0));
    });

    test('yesterday method', () {
      final now = DateTime.now();
      final yesterday = AppDateUtils.yesterday();
      final expectedYesterday = DateTime(now.year, now.month, now.day - 1);
      expect(yesterday.year, equals(expectedYesterday.year));
      expect(yesterday.month, equals(expectedYesterday.month));
      expect(yesterday.day, equals(expectedYesterday.day));
      expect(yesterday.hour, equals(0));
      expect(yesterday.minute, equals(0));
      expect(yesterday.second, equals(0));
      expect(yesterday.millisecond, equals(0));
    });

    test('daysBetween method', () {
      final date1 = DateTime(2023, 1, 1);
      final date2 = DateTime(2023, 1, 10);
      expect(AppDateUtils.daysBetween(date1, date2), equals(9));
      expect(AppDateUtils.daysBetween(date2, date1), equals(-9));
    });
  });

  group('StringUtils Tests', () {
    test('isNullOrEmpty method', () {
      expect(StringUtils.isNullOrEmpty(null), isTrue);
      expect(StringUtils.isNullOrEmpty(''), isTrue);
      expect(StringUtils.isNullOrEmpty(' '), isTrue);
      expect(StringUtils.isNullOrEmpty('test'), isFalse);
    });

    test('isNotNullOrEmpty method', () {
      expect(StringUtils.isNotNullOrEmpty(null), isFalse);
      expect(StringUtils.isNotNullOrEmpty(''), isFalse);
      expect(StringUtils.isNotNullOrEmpty(' '), isFalse);
      expect(StringUtils.isNotNullOrEmpty('test'), isTrue);
    });

    test('getFirstChar method', () {
      expect(StringUtils.getFirstChar(null), isNull);
      expect(StringUtils.getFirstChar(''), isNull);
      expect(StringUtils.getFirstChar('test'), equals('t'));
    });

    test('getLastChar method', () {
      expect(StringUtils.getLastChar(null), isNull);
      expect(StringUtils.getLastChar(''), isNull);
      expect(StringUtils.getLastChar('test'), equals('t'));
    });

    test('truncate method', () {
      expect(StringUtils.truncate('test', 10), equals('test'));
      expect(StringUtils.truncate('test', 2), equals('te...'));
      expect(StringUtils.truncate('test', 2, ellipsis: '..'), equals('te..'));
    });

    test('capitalize method', () {
      expect(StringUtils.capitalize('test'), equals('Test'));
      expect(StringUtils.capitalize('Test'), equals('Test'));
      expect(StringUtils.capitalize(''), equals(''));
    });

    test('decapitalize method', () {
      expect(StringUtils.decapitalize('Test'), equals('test'));
      expect(StringUtils.decapitalize('test'), equals('test'));
      expect(StringUtils.decapitalize(''), equals(''));
    });

    test('camelToSnake method', () {
      expect(StringUtils.camelToSnake('testString'), equals('test_string'));
      expect(StringUtils.camelToSnake('TestString'), equals('_test_string'));
      expect(StringUtils.camelToSnake('test'), equals('test'));
    });

    test('snakeToCamel method', () {
      expect(StringUtils.snakeToCamel('test_string'), equals('testString'));
      expect(StringUtils.snakeToCamel('test'), equals('test'));
    });
  });
}
