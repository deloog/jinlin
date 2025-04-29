import 'package:flutter_test/flutter_test.dart';
import 'package:jinlin_app/special_date.dart';
import 'package:flutter/material.dart';

void main() {
  group('SpecialDate', () {
    test('should create a SpecialDate with fixed Gregorian date', () {
      final specialDate = SpecialDate(
        id: '1',
        name: 'New Year',
        type: SpecialDateType.statutory,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '1-1',
      );

      expect(specialDate.id, '1');
      expect(specialDate.name, 'New Year');
      expect(specialDate.type, SpecialDateType.statutory);
      expect(specialDate.regions, ['CN']);
      expect(specialDate.calculationType, DateCalculationType.fixedGregorian);
      expect(specialDate.calculationRule, '1-1');
      expect(specialDate.description, null);
    });

    test('should create a SpecialDate with fixed Lunar date', () {
      final specialDate = SpecialDate(
        id: '2',
        name: 'Chinese New Year',
        type: SpecialDateType.traditional,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedLunar,
        calculationRule: 'L1-1',
      );

      expect(specialDate.id, '2');
      expect(specialDate.name, 'Chinese New Year');
      expect(specialDate.type, SpecialDateType.traditional);
      expect(specialDate.regions, ['CN']);
      expect(specialDate.calculationType, DateCalculationType.fixedLunar);
      expect(specialDate.calculationRule, 'L1-1');
      expect(specialDate.description, null);
    });

    test('should get correct icon for different types', () {
      final statutoryDate = SpecialDate(
        id: '3',
        name: 'National Day',
        type: SpecialDateType.statutory,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '10-1',
      );

      final traditionalDate = SpecialDate(
        id: '4',
        name: 'Dragon Boat Festival',
        type: SpecialDateType.traditional,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedLunar,
        calculationRule: 'L5-5',
      );

      final customDate = SpecialDate(
        id: '5',
        name: 'Company Anniversary',
        type: SpecialDateType.custom,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '6-15',
      );

      expect(statutoryDate.typeIcon, Icons.flag_circle);
      expect(traditionalDate.typeIcon, Icons.cake);
      expect(customDate.typeIcon, Icons.person);
    });

    test('should get upcoming occurrence for Gregorian date', () {
      final today = DateTime(2023, 5, 15); // May 15, 2023

      // Test date in future this year
      final futureDate = SpecialDate(
        id: '6',
        name: 'Future Holiday',
        type: SpecialDateType.statutory,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '6-1',
      );

      final futureDateOccurrence = futureDate.getUpcomingOccurrence(today);
      expect(futureDateOccurrence, DateTime(2023, 6, 1));

      // Test date in past this year (should return next year)
      final pastDate = SpecialDate(
        id: '7',
        name: 'Past Holiday',
        type: SpecialDateType.statutory,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '1-1',
      );

      final pastDateOccurrence = pastDate.getUpcomingOccurrence(today);
      expect(pastDateOccurrence, DateTime(2024, 1, 1));

      // Test today's date (should return today)
      final todayDate = SpecialDate(
        id: '8',
        name: 'Today Holiday',
        type: SpecialDateType.statutory,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '5-15',
      );

      final todayDateOccurrence = todayDate.getUpcomingOccurrence(today);
      expect(todayDateOccurrence, DateTime(2023, 5, 15));
    });

    test('should format upcoming date correctly', () {
      final now = DateTime(2023, 5, 15);
      final upcomingDate = DateTime(2023, 6, 1);

      final specialDate = SpecialDate(
        id: '9',
        name: 'Test Holiday',
        type: SpecialDateType.statutory,
        regions: ['CN'],
        calculationType: DateCalculationType.fixedGregorian,
        calculationRule: '6-1',
      );

      final formatted = specialDate.formatUpcomingDate(upcomingDate, now);

      // Should contain the date and days remaining
      expect(formatted.contains('2023'), true);
      expect(formatted.contains('6'), true); // Month
      expect(formatted.contains('1'), true); // Day
      expect(formatted.contains('17'), true); // 17 days remaining
    });
  });
}
