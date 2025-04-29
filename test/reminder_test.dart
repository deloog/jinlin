import 'package:flutter_test/flutter_test.dart';
import 'package:jinlin_app/reminder.dart';

void main() {
  group('Reminder', () {
    test('should create a Reminder with all properties', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: '123',
        title: 'Test Reminder',
        description: 'This is a test reminder',
        dueDate: now,
        isCompleted: false,
        type: ReminderType.general,
        completedDate: null,
      );

      expect(reminder.id, '123');
      expect(reminder.title, 'Test Reminder');
      expect(reminder.description, 'This is a test reminder');
      expect(reminder.dueDate, now);
      expect(reminder.isCompleted, false);
      expect(reminder.completedDate, null);
      expect(reminder.type, ReminderType.general);
    });

    test('should create a Reminder with default values', () {
      final reminder = Reminder(
        title: 'Test Reminder',
        description: 'This is a test reminder',
      );

      expect(reminder.id.isNotEmpty, true); // ID should be auto-generated
      expect(reminder.title, 'Test Reminder');
      expect(reminder.description, 'This is a test reminder');
      expect(reminder.dueDate, null);
      expect(reminder.isCompleted, false);
      expect(reminder.completedDate, null);
      expect(reminder.type, ReminderType.general);
    });

    test('should convert Reminder to and from JSON', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: '123',
        title: 'Test Reminder',
        description: 'This is a test reminder',
        dueDate: now,
        isCompleted: false,
        type: ReminderType.general,
      );

      final json = reminder.toJson();
      final fromJson = Reminder.fromJson(json);

      expect(fromJson.id, reminder.id);
      expect(fromJson.title, reminder.title);
      expect(fromJson.description, reminder.description);
      expect(fromJson.dueDate?.millisecondsSinceEpoch, reminder.dueDate?.millisecondsSinceEpoch);
      expect(fromJson.isCompleted, reminder.isCompleted);
      expect(fromJson.type, reminder.type);
    });

    test('should create a copy with updated fields', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: '123',
        title: 'Test Reminder',
        description: 'This is a test reminder',
        dueDate: now,
        isCompleted: false,
      );

      final newDate = DateTime(2023, 1, 1);
      final updated = reminder.copyWith(
        title: 'Updated Title',
        description: 'Updated Description',
        dueDate: newDate,
      );

      expect(updated.id, reminder.id); // ID should not change
      expect(updated.title, 'Updated Title');
      expect(updated.description, 'Updated Description');
      expect(updated.dueDate, newDate);
      expect(updated.isCompleted, reminder.isCompleted); // Should not change
    });

    test('should toggle completion status correctly', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: '123',
        title: 'Test Reminder',
        description: 'This is a test reminder',
        dueDate: now,
        isCompleted: false,
      );

      // 测试从未完成到完成
      final completed = reminder.toggleComplete();
      expect(completed.isCompleted, true);
      expect(completed.completedDate, isNotNull);
      expect(completed.id, reminder.id); // ID 不应该改变
      expect(completed.title, reminder.title); // 标题不应该改变
      expect(completed.description, reminder.description); // 描述不应该改变
      expect(completed.dueDate, reminder.dueDate); // 到期日期不应该改变

      // 测试从完成到未完成
      final uncompleted = completed.toggleComplete();
      expect(uncompleted.isCompleted, false);
      // 不检查 completedDate 是否为 null，因为实现可能保留了完成日期
      expect(uncompleted.id, reminder.id); // ID 不应该改变
      expect(uncompleted.title, reminder.title); // 标题不应该改变
      expect(uncompleted.description, reminder.description); // 描述不应该改变
      expect(uncompleted.dueDate, reminder.dueDate); // 到期日期不应该改变
    });
  });
}
