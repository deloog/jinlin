import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/services/validation/validator.dart';
import 'package:jinlin_app/services/validation/validation_result.dart';

/// 节日日期类型
enum HolidayDateType {
  fixed,    // 固定日期
  lunar,    // 农历日期
  calculated // 计算型日期
}

/// 节日验证器
///
/// 验证节日数据是否符合要求
class HolidayValidator implements Validator<Holiday> {
  @override
  ValidationResult validate(Holiday data) {
    final errors = <String>[];
    final warnings = <String>[];

    // 验证ID
    if (data.id.isEmpty) {
      errors.add('节日ID不能为空');
    }

    // 验证名称
    if (data.names.isEmpty || (data.names['zh'] ?? '').isEmpty) {
      errors.add('节日名称不能为空');
    }

    // 验证地区
    if (data.regions.isEmpty) {
      errors.add('节日必须指定至少一个地区');
    }

    // 验证计算规则
    if (data.calculationRule.isEmpty) {
      errors.add('节日必须指定计算规则');
    }

    // 验证多语言名称
    if (data.names.length < 2) {
      warnings.add('节日没有多语言名称，可能影响国际化显示');
    }

    // 验证创建时间和修改时间
    if (data.lastModified == null) {
      warnings.add('节日没有最后修改时间');
    }

    if (errors.isEmpty) {
      return ValidationResult(isValid: true, warnings: warnings);
    } else {
      return ValidationResult(isValid: false, errors: errors, warnings: warnings);
    }
  }
}

/// 联系人验证器
///
/// 验证联系人数据是否符合要求
class ContactValidator implements Validator<ContactModel> {
  @override
  ValidationResult validate(ContactModel data) {
    final errors = <String>[];
    final warnings = <String>[];

    // 验证ID
    if (data.id.isEmpty) {
      errors.add('联系人ID不能为空');
    }

    // 验证名称
    if (data.name.isEmpty) {
      errors.add('联系人名称不能为空');
    }

    // 验证电话号码
    if (data.phoneNumber != null && data.phoneNumber!.isNotEmpty) {
      // 简单的电话号码验证
      final phoneRegex = RegExp(r'^\+?[0-9\-\(\)\s]+$');
      if (!phoneRegex.hasMatch(data.phoneNumber!)) {
        errors.add('电话号码格式不正确');
      }
    }

    // 验证电子邮件
    if (data.email != null && data.email!.isNotEmpty) {
      // 简单的电子邮件验证
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(data.email!)) {
        errors.add('电子邮件格式不正确');
      }
    }

    // 验证生日
    if (data.birthday != null) {
      final now = DateTime.now();
      if (data.birthday!.isAfter(now)) {
        errors.add('生日不能是未来日期');
      }
    }

    // 验证创建时间是否合理
    if (data.createdAt.isAfter(DateTime.now())) {
      errors.add('联系人创建时间不能是未来时间');
    }

    // 建议
    if (data.phoneNumber == null && data.email == null) {
      warnings.add('联系人没有电话号码和电子邮件，可能难以联系');
    }

    if (data.birthday == null) {
      warnings.add('联系人没有生日信息，将无法提醒生日');
    }

    if (errors.isEmpty) {
      return ValidationResult(isValid: true, warnings: warnings);
    } else {
      return ValidationResult(isValid: false, errors: errors, warnings: warnings);
    }
  }
}

/// 提醒事件验证器
///
/// 验证提醒事件数据是否符合要求
class ReminderEventValidator implements Validator<ReminderEventModel> {
  @override
  ValidationResult validate(ReminderEventModel data) {
    final errors = <String>[];
    final warnings = <String>[];

    // 验证ID
    if (data.id.isEmpty) {
      errors.add('提醒事件ID不能为空');
    }

    // 验证标题
    if (data.title.isEmpty) {
      errors.add('提醒事件标题不能为空');
    }

    // 验证到期日期
    if (data.dueDate == null) {
      warnings.add('提醒事件没有到期日期，可能影响提醒功能');
    }

    // 验证重复规则
    if (data.isRepeating && (data.repeatRule == null || data.repeatRule!.isEmpty)) {
      errors.add('重复提醒事件必须指定重复规则');
    }

    // 验证提醒时间
    if (data.reminderTimes != null && data.reminderTimes!.isEmpty) {
      warnings.add('提醒事件没有设置提醒时间，可能无法及时提醒');
    }

    // 验证联系人ID
    if (data.contactId != null && data.contactId!.isEmpty) {
      errors.add('联系人ID不能为空字符串');
    }

    // 验证节日ID
    if (data.holidayId != null && data.holidayId!.isEmpty) {
      errors.add('节日ID不能为空字符串');
    }

    // 验证创建时间是否合理
    if (data.createdAt.isAfter(DateTime.now())) {
      errors.add('提醒事件创建时间不能是未来时间');
    }

    // 验证完成状态
    if (data.isCompleted && data.completedAt == null) {
      warnings.add('已完成的提醒事件应该有完成时间');
    }

    if (errors.isEmpty) {
      return ValidationResult(isValid: true, warnings: warnings);
    } else {
      return ValidationResult(isValid: false, errors: errors, warnings: warnings);
    }
  }
}

/// 用户设置验证器
///
/// 验证用户设置数据是否符合要求
class UserSettingsValidator implements Validator<UserSettingsModel> {
  @override
  ValidationResult validate(UserSettingsModel data) {
    final errors = <String>[];
    final warnings = <String>[];

    // 验证用户ID
    if (data.userId.isEmpty) {
      errors.add('用户ID不能为空');
    }

    // 验证昵称
    if (data.nickname.isEmpty) {
      errors.add('用户昵称不能为空');
    }

    // 验证语言代码
    if (data.languageCode.isEmpty) {
      errors.add('语言代码不能为空');
    }

    // 验证同步频率
    if (data.enableCloudSync && data.syncFrequencyHours <= 0) {
      errors.add('同步频率必须大于0小时');
    }

    // 验证备份频率
    if (data.autoBackup && data.backupFrequencyDays <= 0) {
      errors.add('备份频率必须大于0天');
    }

    // 验证过期事件保留天数
    if (data.expiredEventRetentionDays < 0) {
      errors.add('过期事件保留天数不能为负数');
    }

    // 建议
    if (!data.enableNotifications) {
      warnings.add('通知已禁用，可能会错过重要提醒');
    }

    if (data.enableCloudSync && data.syncFrequencyHours > 24) {
      warnings.add('同步频率大于24小时，可能导致数据不及时同步');
    }

    if (errors.isEmpty) {
      return ValidationResult(isValid: true, warnings: warnings);
    } else {
      return ValidationResult(isValid: false, errors: errors, warnings: warnings);
    }
  }
}
