import 'package:flutter_test/flutter_test.dart';
import 'package:jinlin_app/reminder.dart';

void main() {
  group('Reminder Tests', () {
    test('Reminder creation test', () {
      final reminder = Reminder(
        title: 'Test Reminder',
        description: 'Test Description',
      );

      expect(reminder.title, 'Test Reminder');
      expect(reminder.description, 'Test Description');
      expect(reminder.isCompleted, false);
    });

    test('Reminder toggle complete test', () {
      final reminder = Reminder(
        title: 'Test Reminder',
        description: 'Test Description',
      );

      final completed = reminder.toggleComplete();
      expect(completed.isCompleted, true);
      expect(completed.completedDate, isNotNull);

      final uncompleted = completed.toggleComplete();
      expect(uncompleted.isCompleted, false);
    });
  });
}
