import 'package:flutter_test/flutter_test.dart';
import 'package:jinlin_app/timeline_item.dart';
import 'package:jinlin_app/reminder.dart';
import 'package:jinlin_app/special_date.dart';

void main() {
  group('TimelineItem', () {
    test('should create a TimelineItem with a Reminder', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: '123',
        title: 'Test Reminder',
        description: 'Test Description',
        dueDate: now,
      );

      final timelineItem = TimelineItem(
        displayDate: now,
        itemType: TimelineItemType.reminder,
        originalObject: reminder,
      );

      expect(timelineItem.displayDate, now);
      expect(timelineItem.itemType, TimelineItemType.reminder);
      expect(timelineItem.originalObject, reminder);
    });

    test('should create a TimelineItem with a SpecialDate', () {
      final now = DateTime.now();
      final specialDate = SpecialDate(
        id: '123',
        name: 'Test Holiday',
        type: SpecialDateType.statutory,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '${now.month}-${now.day}',
      );

      final timelineItem = TimelineItem(
        displayDate: now,
        itemType: TimelineItemType.holiday,
        originalObject: specialDate,
      );

      expect(timelineItem.displayDate, now);
      expect(timelineItem.itemType, TimelineItemType.holiday);
      expect(timelineItem.originalObject, specialDate);
    });

    test('should compare TimelineItems correctly', () {
      final date1 = DateTime(2023, 1, 1);
      final date2 = DateTime(2023, 1, 2);
      final date3 = DateTime(2023, 1, 3);

      final reminder1 = Reminder(
        id: '1',
        title: 'Reminder 1',
        description: 'Description 1',
        dueDate: date1
      );

      final reminder2 = Reminder(
        id: '2',
        title: 'Reminder 2',
        description: 'Description 2',
        dueDate: date2
      );

      final reminder3 = Reminder(
        id: '3',
        title: 'Reminder 3',
        description: 'Description 3',
        dueDate: null
      ); // No date

      final holiday1 = SpecialDate(
        id: '4',
        name: 'Holiday 1',
        type: SpecialDateType.statutory,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '1-1',
      );

      final holiday2 = SpecialDate(
        id: '5',
        name: 'Holiday 2',
        type: SpecialDateType.statutory,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '1-3',
      );

      final item1 = TimelineItem(
        displayDate: date1,
        itemType: TimelineItemType.reminder,
        originalObject: reminder1,
      );

      final item2 = TimelineItem(
        displayDate: date2,
        itemType: TimelineItemType.reminder,
        originalObject: reminder2,
      );

      final item3 = TimelineItem(
        displayDate: null,
        itemType: TimelineItemType.reminder,
        originalObject: reminder3,
      );

      final item4 = TimelineItem(
        displayDate: date1,
        itemType: TimelineItemType.holiday,
        originalObject: holiday1,
      );

      final item5 = TimelineItem(
        displayDate: date3,
        itemType: TimelineItemType.holiday,
        originalObject: holiday2,
      );

      // Test sorting by date
      final items = [item3, item5, item2, item4, item1];
      items.sort();

      // Expected order: items with dates first (by date), then items without dates
      expect(items[0].displayDate, date1);
      expect(items[1].displayDate, date1);
      expect(items[2].displayDate, date2);
      expect(items[3].displayDate, date3);
      expect(items[4].displayDate, null);
    });
  });
}
