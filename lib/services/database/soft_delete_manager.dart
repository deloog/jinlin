import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/services/database/database_interface_enhanced.dart';
import 'package:jinlin_app/utils/logger.dart';

/// 软删除管理器
///
/// 提供软删除和恢复功能
class SoftDeleteManager {
  // 日志标签
  static const String _tag = 'SoftDeleteManager';
  
  // 数据库接口
  final DatabaseInterfaceEnhanced _db;
  
  /// 构造函数
  SoftDeleteManager(this._db);
  
  /// 软删除节日
  Future<void> softDeleteHoliday(String id, {String? reason}) async {
    try {
      logger.i(_tag, '软删除节日: $id, 原因: $reason');
      
      // 获取节日
      final holiday = await _db.getHolidayById(id);
      if (holiday == null) {
        logger.w(_tag, '节日不存在: $id');
        return;
      }
      
      // 标记为已删除
      final updatedHoliday = holiday.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
        deletionReason: reason,
      );
      
      // 保存更新后的节日
      await _db.saveHoliday(updatedHoliday);
      
      logger.i(_tag, '节日已软删除: $id');
    } catch (e, stackTrace) {
      logger.e(_tag, '软删除节日失败: $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 软删除联系人
  Future<void> softDeleteContact(String id, {String? reason}) async {
    try {
      logger.i(_tag, '软删除联系人: $id, 原因: $reason');
      
      // 获取联系人
      final contact = await _db.getContactById(id);
      if (contact == null) {
        logger.w(_tag, '联系人不存在: $id');
        return;
      }
      
      // 标记为已删除
      final updatedContact = contact.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
        deletionReason: reason,
      );
      
      // 保存更新后的联系人
      await _db.saveContact(updatedContact);
      
      logger.i(_tag, '联系人已软删除: $id');
    } catch (e, stackTrace) {
      logger.e(_tag, '软删除联系人失败: $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 软删除提醒事件
  Future<void> softDeleteReminderEvent(String id, {String? reason}) async {
    try {
      logger.i(_tag, '软删除提醒事件: $id, 原因: $reason');
      
      // 获取提醒事件
      final event = await _db.getReminderEventById(id);
      if (event == null) {
        logger.w(_tag, '提醒事件不存在: $id');
        return;
      }
      
      // 标记为已删除
      final updatedEvent = event.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
        deletionReason: reason,
      );
      
      // 保存更新后的提醒事件
      await _db.saveReminderEvent(updatedEvent);
      
      logger.i(_tag, '提醒事件已软删除: $id');
    } catch (e, stackTrace) {
      logger.e(_tag, '软删除提醒事件失败: $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 恢复节日
  Future<void> restoreHoliday(String id) async {
    try {
      logger.i(_tag, '恢复节日: $id');
      
      // 获取节日
      final holiday = await _db.getHolidayById(id);
      if (holiday == null) {
        logger.w(_tag, '节日不存在: $id');
        return;
      }
      
      // 检查是否已删除
      if (!holiday.isDeleted) {
        logger.w(_tag, '节日未被删除: $id');
        return;
      }
      
      // 标记为未删除
      final updatedHoliday = holiday.copyWith(
        isDeleted: false,
        deletedAt: null,
        deletionReason: null,
      );
      
      // 保存更新后的节日
      await _db.saveHoliday(updatedHoliday);
      
      logger.i(_tag, '节日已恢复: $id');
    } catch (e, stackTrace) {
      logger.e(_tag, '恢复节日失败: $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 恢复联系人
  Future<void> restoreContact(String id) async {
    try {
      logger.i(_tag, '恢复联系人: $id');
      
      // 获取联系人
      final contact = await _db.getContactById(id);
      if (contact == null) {
        logger.w(_tag, '联系人不存在: $id');
        return;
      }
      
      // 检查是否已删除
      if (!contact.isDeleted) {
        logger.w(_tag, '联系人未被删除: $id');
        return;
      }
      
      // 标记为未删除
      final updatedContact = contact.copyWith(
        isDeleted: false,
        deletedAt: null,
        deletionReason: null,
      );
      
      // 保存更新后的联系人
      await _db.saveContact(updatedContact);
      
      logger.i(_tag, '联系人已恢复: $id');
    } catch (e, stackTrace) {
      logger.e(_tag, '恢复联系人失败: $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 恢复提醒事件
  Future<void> restoreReminderEvent(String id) async {
    try {
      logger.i(_tag, '恢复提醒事件: $id');
      
      // 获取提醒事件
      final event = await _db.getReminderEventById(id);
      if (event == null) {
        logger.w(_tag, '提醒事件不存在: $id');
        return;
      }
      
      // 检查是否已删除
      if (!event.isDeleted) {
        logger.w(_tag, '提醒事件未被删除: $id');
        return;
      }
      
      // 标记为未删除
      final updatedEvent = event.copyWith(
        isDeleted: false,
        deletedAt: null,
        deletionReason: null,
      );
      
      // 保存更新后的提醒事件
      await _db.saveReminderEvent(updatedEvent);
      
      logger.i(_tag, '提醒事件已恢复: $id');
    } catch (e, stackTrace) {
      logger.e(_tag, '恢复提醒事件失败: $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 获取已删除的节日
  Future<List<Holiday>> getDeletedHolidays() async {
    try {
      logger.i(_tag, '获取已删除的节日');
      
      // 获取所有节日
      final holidays = await _db.getAllHolidays();
      
      // 过滤出已删除的节日
      final deletedHolidays = holidays.where((holiday) => holiday.isDeleted).toList();
      
      logger.i(_tag, '已删除的节日数量: ${deletedHolidays.length}');
      return deletedHolidays;
    } catch (e, stackTrace) {
      logger.e(_tag, '获取已删除的节日失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 获取已删除的联系人
  Future<List<ContactModel>> getDeletedContacts() async {
    try {
      logger.i(_tag, '获取已删除的联系人');
      
      // 获取所有联系人
      final contacts = await _db.getAllContacts();
      
      // 过滤出已删除的联系人
      final deletedContacts = contacts.where((contact) => contact.isDeleted).toList();
      
      logger.i(_tag, '已删除的联系人数量: ${deletedContacts.length}');
      return deletedContacts;
    } catch (e, stackTrace) {
      logger.e(_tag, '获取已删除的联系人失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 获取已删除的提醒事件
  Future<List<ReminderEventModel>> getDeletedReminderEvents() async {
    try {
      logger.i(_tag, '获取已删除的提醒事件');
      
      // 获取所有提醒事件
      final events = await _db.getAllReminderEvents();
      
      // 过滤出已删除的提醒事件
      final deletedEvents = events.where((event) => event.isDeleted).toList();
      
      logger.i(_tag, '已删除的提醒事件数量: ${deletedEvents.length}');
      return deletedEvents;
    } catch (e, stackTrace) {
      logger.e(_tag, '获取已删除的提醒事件失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 永久删除节日
  Future<void> permanentlyDeleteHoliday(String id) async {
    try {
      logger.i(_tag, '永久删除节日: $id');
      
      // 直接删除节日
      await _db.deleteHoliday(id);
      
      logger.i(_tag, '节日已永久删除: $id');
    } catch (e, stackTrace) {
      logger.e(_tag, '永久删除节日失败: $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 永久删除联系人
  Future<void> permanentlyDeleteContact(String id) async {
    try {
      logger.i(_tag, '永久删除联系人: $id');
      
      // 直接删除联系人
      await _db.deleteContact(id);
      
      logger.i(_tag, '联系人已永久删除: $id');
    } catch (e, stackTrace) {
      logger.e(_tag, '永久删除联系人失败: $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 永久删除提醒事件
  Future<void> permanentlyDeleteReminderEvent(String id) async {
    try {
      logger.i(_tag, '永久删除提醒事件: $id');
      
      // 直接删除提醒事件
      await _db.deleteReminderEvent(id);
      
      logger.i(_tag, '提醒事件已永久删除: $id');
    } catch (e, stackTrace) {
      logger.e(_tag, '永久删除提醒事件失败: $id', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 清空回收站（永久删除所有已删除的数据）
  Future<void> emptyTrash() async {
    try {
      logger.i(_tag, '清空回收站');
      
      // 获取所有已删除的数据
      final deletedHolidays = await getDeletedHolidays();
      final deletedContacts = await getDeletedContacts();
      final deletedEvents = await getDeletedReminderEvents();
      
      // 永久删除所有已删除的节日
      for (final holiday in deletedHolidays) {
        await permanentlyDeleteHoliday(holiday.id);
      }
      
      // 永久删除所有已删除的联系人
      for (final contact in deletedContacts) {
        await permanentlyDeleteContact(contact.id);
      }
      
      // 永久删除所有已删除的提醒事件
      for (final event in deletedEvents) {
        await permanentlyDeleteReminderEvent(event.id);
      }
      
      logger.i(_tag, '回收站已清空');
    } catch (e, stackTrace) {
      logger.e(_tag, '清空回收站失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// 清理过期的已删除数据
  Future<void> cleanupExpiredDeletedData(int retentionDays) async {
    try {
      logger.i(_tag, '清理过期的已删除数据 (保留天数: $retentionDays)');
      
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: retentionDays));
      
      // 获取所有已删除的数据
      final deletedHolidays = await getDeletedHolidays();
      final deletedContacts = await getDeletedContacts();
      final deletedEvents = await getDeletedReminderEvents();
      
      // 过滤出过期的已删除节日
      final expiredHolidays = deletedHolidays.where((holiday) {
        return holiday.deletedAt != null && holiday.deletedAt!.isBefore(cutoffDate);
      }).toList();
      
      // 过滤出过期的已删除联系人
      final expiredContacts = deletedContacts.where((contact) {
        return contact.deletedAt != null && contact.deletedAt!.isBefore(cutoffDate);
      }).toList();
      
      // 过滤出过期的已删除提醒事件
      final expiredEvents = deletedEvents.where((event) {
        return event.deletedAt != null && event.deletedAt!.isBefore(cutoffDate);
      }).toList();
      
      // 永久删除过期的已删除节日
      for (final holiday in expiredHolidays) {
        await permanentlyDeleteHoliday(holiday.id);
      }
      
      // 永久删除过期的已删除联系人
      for (final contact in expiredContacts) {
        await permanentlyDeleteContact(contact.id);
      }
      
      // 永久删除过期的已删除提醒事件
      for (final event in expiredEvents) {
        await permanentlyDeleteReminderEvent(event.id);
      }
      
      logger.i(_tag, '已清理过期的已删除数据: ${expiredHolidays.length} 个节日, ${expiredContacts.length} 个联系人, ${expiredEvents.length} 个提醒事件');
    } catch (e, stackTrace) {
      logger.e(_tag, '清理过期的已删除数据失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
