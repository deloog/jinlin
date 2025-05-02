import 'package:jinlin_app/models/unified/holiday.dart';
import 'package:jinlin_app/models/contact_model.dart';
import 'package:jinlin_app/models/user_settings_model.dart';
import 'package:jinlin_app/models/reminder_event_model.dart';
import 'package:jinlin_app/services/validation/model_validators.dart';
import 'package:jinlin_app/services/validation/validation_result.dart';
import 'package:jinlin_app/services/validation/validator.dart';
import 'package:jinlin_app/utils/logger.dart';

/// 验证异常
///
/// 当验证失败时抛出
class ValidationException implements Exception {
  /// 验证结果
  final ValidationResult result;
  
  /// 构造函数
  ValidationException(this.result);
  
  @override
  String toString() {
    return '验证失败: ${result.errors.join(', ')}';
  }
}

/// 验证服务
///
/// 提供数据验证功能
class ValidationService {
  // 单例模式
  static final ValidationService _instance = ValidationService._internal();
  
  factory ValidationService() {
    return _instance;
  }
  
  ValidationService._internal();
  
  // 日志标签
  static const String _tag = 'ValidationService';
  
  // 验证器
  final HolidayValidator _holidayValidator = HolidayValidator();
  final ContactValidator _contactValidator = ContactValidator();
  final ReminderEventValidator _reminderEventValidator = ReminderEventValidator();
  final UserSettingsValidator _userSettingsValidator = UserSettingsValidator();
  
  // 是否启用验证
  bool _validationEnabled = true;
  
  // 是否抛出异常
  bool _throwExceptions = false;
  
  /// 启用验证
  void enableValidation() {
    _validationEnabled = true;
    logger.i(_tag, '验证已启用');
  }
  
  /// 禁用验证
  void disableValidation() {
    _validationEnabled = false;
    logger.i(_tag, '验证已禁用');
  }
  
  /// 启用异常
  void enableExceptions() {
    _throwExceptions = true;
    logger.i(_tag, '验证异常已启用');
  }
  
  /// 禁用异常
  void disableExceptions() {
    _throwExceptions = false;
    logger.i(_tag, '验证异常已禁用');
  }
  
  /// 验证节日
  ValidationResult validateHoliday(Holiday holiday) {
    if (!_validationEnabled) {
      return ValidationResult.valid();
    }
    
    logger.d(_tag, '验证节日: ${holiday.id}');
    final result = _holidayValidator.validate(holiday);
    
    if (!result.isValid) {
      logger.w(_tag, '节日验证失败: ${holiday.id}, ${result.errors.join(', ')}');
      
      if (_throwExceptions) {
        throw ValidationException(result);
      }
    } else if (result.warnings.isNotEmpty) {
      logger.w(_tag, '节日验证警告: ${holiday.id}, ${result.warnings.join(', ')}');
    }
    
    return result;
  }
  
  /// 验证联系人
  ValidationResult validateContact(ContactModel contact) {
    if (!_validationEnabled) {
      return ValidationResult.valid();
    }
    
    logger.d(_tag, '验证联系人: ${contact.id}');
    final result = _contactValidator.validate(contact);
    
    if (!result.isValid) {
      logger.w(_tag, '联系人验证失败: ${contact.id}, ${result.errors.join(', ')}');
      
      if (_throwExceptions) {
        throw ValidationException(result);
      }
    } else if (result.warnings.isNotEmpty) {
      logger.w(_tag, '联系人验证警告: ${contact.id}, ${result.warnings.join(', ')}');
    }
    
    return result;
  }
  
  /// 验证提醒事件
  ValidationResult validateReminderEvent(ReminderEventModel event) {
    if (!_validationEnabled) {
      return ValidationResult.valid();
    }
    
    logger.d(_tag, '验证提醒事件: ${event.id}');
    final result = _reminderEventValidator.validate(event);
    
    if (!result.isValid) {
      logger.w(_tag, '提醒事件验证失败: ${event.id}, ${result.errors.join(', ')}');
      
      if (_throwExceptions) {
        throw ValidationException(result);
      }
    } else if (result.warnings.isNotEmpty) {
      logger.w(_tag, '提醒事件验证警告: ${event.id}, ${result.warnings.join(', ')}');
    }
    
    return result;
  }
  
  /// 验证用户设置
  ValidationResult validateUserSettings(UserSettingsModel settings) {
    if (!_validationEnabled) {
      return ValidationResult.valid();
    }
    
    logger.d(_tag, '验证用户设置');
    final result = _userSettingsValidator.validate(settings);
    
    if (!result.isValid) {
      logger.w(_tag, '用户设置验证失败: ${result.errors.join(', ')}');
      
      if (_throwExceptions) {
        throw ValidationException(result);
      }
    } else if (result.warnings.isNotEmpty) {
      logger.w(_tag, '用户设置验证警告: ${result.warnings.join(', ')}');
    }
    
    return result;
  }
  
  /// 验证数据
  ValidationResult validate<T>(T data, Validator<T> validator) {
    if (!_validationEnabled) {
      return ValidationResult.valid();
    }
    
    logger.d(_tag, '验证数据: ${data.runtimeType}');
    final result = validator.validate(data);
    
    if (!result.isValid) {
      logger.w(_tag, '数据验证失败: ${data.runtimeType}, ${result.errors.join(', ')}');
      
      if (_throwExceptions) {
        throw ValidationException(result);
      }
    } else if (result.warnings.isNotEmpty) {
      logger.w(_tag, '数据验证警告: ${data.runtimeType}, ${result.warnings.join(', ')}');
    }
    
    return result;
  }
}

/// 全局验证服务实例
final validationService = ValidationService();
