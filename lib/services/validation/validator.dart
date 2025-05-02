import 'package:jinlin_app/services/validation/validation_result.dart';

/// 验证器接口
///
/// 定义验证器的基本接口
abstract class Validator<T> {
  /// 验证数据
  ValidationResult validate(T data);
}

/// 复合验证器
///
/// 组合多个验证器，按顺序执行验证
class CompositeValidator<T> implements Validator<T> {
  /// 验证器列表
  final List<Validator<T>> validators;
  
  /// 构造函数
  CompositeValidator(this.validators);
  
  @override
  ValidationResult validate(T data) {
    // 初始验证结果
    ValidationResult result = ValidationResult.valid();
    
    // 依次执行所有验证器
    for (final validator in validators) {
      final validationResult = validator.validate(data);
      result = result.merge(validationResult);
      
      // 如果验证失败，可以选择提前返回
      // 这里选择继续验证，收集所有错误
    }
    
    return result;
  }
}

/// 条件验证器
///
/// 根据条件决定是否执行验证
class ConditionalValidator<T> implements Validator<T> {
  /// 条件函数
  final bool Function(T data) condition;
  
  /// 验证器
  final Validator<T> validator;
  
  /// 构造函数
  ConditionalValidator(this.condition, this.validator);
  
  @override
  ValidationResult validate(T data) {
    // 如果条件满足，执行验证
    if (condition(data)) {
      return validator.validate(data);
    }
    
    // 否则，返回有效结果
    return ValidationResult.valid();
  }
}

/// 非空验证器
///
/// 验证数据是否为空
class NotNullValidator<T> implements Validator<T> {
  /// 错误消息
  final String errorMessage;
  
  /// 构造函数
  NotNullValidator({this.errorMessage = '数据不能为空'});
  
  @override
  ValidationResult validate(T? data) {
    if (data == null) {
      return ValidationResult.invalid([errorMessage]);
    }
    
    return ValidationResult.valid();
  }
}

/// 字符串验证器
///
/// 验证字符串是否符合要求
class StringValidator implements Validator<String> {
  /// 最小长度
  final int? minLength;
  
  /// 最大长度
  final int? maxLength;
  
  /// 正则表达式
  final String? pattern;
  
  /// 错误消息
  final String? minLengthError;
  final String? maxLengthError;
  final String? patternError;
  
  /// 构造函数
  StringValidator({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.minLengthError,
    this.maxLengthError,
    this.patternError,
  });
  
  @override
  ValidationResult validate(String data) {
    final errors = <String>[];
    
    // 验证最小长度
    if (minLength != null && data.length < minLength!) {
      errors.add(minLengthError ?? '字符串长度不能小于 $minLength');
    }
    
    // 验证最大长度
    if (maxLength != null && data.length > maxLength!) {
      errors.add(maxLengthError ?? '字符串长度不能大于 $maxLength');
    }
    
    // 验证正则表达式
    if (pattern != null && !RegExp(pattern!).hasMatch(data)) {
      errors.add(patternError ?? '字符串不符合要求的格式');
    }
    
    if (errors.isEmpty) {
      return ValidationResult.valid();
    } else {
      return ValidationResult.invalid(errors);
    }
  }
}

/// 数值验证器
///
/// 验证数值是否符合要求
class NumberValidator implements Validator<num> {
  /// 最小值
  final num? min;
  
  /// 最大值
  final num? max;
  
  /// 错误消息
  final String? minError;
  final String? maxError;
  
  /// 构造函数
  NumberValidator({
    this.min,
    this.max,
    this.minError,
    this.maxError,
  });
  
  @override
  ValidationResult validate(num data) {
    final errors = <String>[];
    
    // 验证最小值
    if (min != null && data < min!) {
      errors.add(minError ?? '数值不能小于 $min');
    }
    
    // 验证最大值
    if (max != null && data > max!) {
      errors.add(maxError ?? '数值不能大于 $max');
    }
    
    if (errors.isEmpty) {
      return ValidationResult.valid();
    } else {
      return ValidationResult.invalid(errors);
    }
  }
}

/// 列表验证器
///
/// 验证列表是否符合要求
class ListValidator<T> implements Validator<List<T>> {
  /// 最小长度
  final int? minLength;
  
  /// 最大长度
  final int? maxLength;
  
  /// 元素验证器
  final Validator<T>? elementValidator;
  
  /// 错误消息
  final String? minLengthError;
  final String? maxLengthError;
  
  /// 构造函数
  ListValidator({
    this.minLength,
    this.maxLength,
    this.elementValidator,
    this.minLengthError,
    this.maxLengthError,
  });
  
  @override
  ValidationResult validate(List<T> data) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // 验证最小长度
    if (minLength != null && data.length < minLength!) {
      errors.add(minLengthError ?? '列表长度不能小于 $minLength');
    }
    
    // 验证最大长度
    if (maxLength != null && data.length > maxLength!) {
      errors.add(maxLengthError ?? '列表长度不能大于 $maxLength');
    }
    
    // 验证元素
    if (elementValidator != null) {
      for (int i = 0; i < data.length; i++) {
        final elementResult = elementValidator!.validate(data[i]);
        
        if (!elementResult.isValid) {
          errors.add('列表元素 #$i 验证失败: ${elementResult.errors.join(', ')}');
        }
        
        if (elementResult.warnings.isNotEmpty) {
          warnings.add('列表元素 #$i 有警告: ${elementResult.warnings.join(', ')}');
        }
      }
    }
    
    if (errors.isEmpty) {
      return ValidationResult(isValid: true, warnings: warnings);
    } else {
      return ValidationResult(isValid: false, errors: errors, warnings: warnings);
    }
  }
}

/// 映射验证器
///
/// 验证映射是否符合要求
class MapValidator<K, V> implements Validator<Map<K, V>> {
  /// 必需的键
  final List<K>? requiredKeys;
  
  /// 键验证器
  final Validator<K>? keyValidator;
  
  /// 值验证器
  final Validator<V>? valueValidator;
  
  /// 错误消息
  final String? requiredKeysError;
  
  /// 构造函数
  MapValidator({
    this.requiredKeys,
    this.keyValidator,
    this.valueValidator,
    this.requiredKeysError,
  });
  
  @override
  ValidationResult validate(Map<K, V> data) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // 验证必需的键
    if (requiredKeys != null) {
      for (final key in requiredKeys!) {
        if (!data.containsKey(key)) {
          errors.add(requiredKeysError ?? '缺少必需的键: $key');
        }
      }
    }
    
    // 验证键
    if (keyValidator != null) {
      for (final key in data.keys) {
        final keyResult = keyValidator!.validate(key);
        
        if (!keyResult.isValid) {
          errors.add('键 $key 验证失败: ${keyResult.errors.join(', ')}');
        }
        
        if (keyResult.warnings.isNotEmpty) {
          warnings.add('键 $key 有警告: ${keyResult.warnings.join(', ')}');
        }
      }
    }
    
    // 验证值
    if (valueValidator != null) {
      for (final entry in data.entries) {
        final valueResult = valueValidator!.validate(entry.value);
        
        if (!valueResult.isValid) {
          errors.add('键 ${entry.key} 的值验证失败: ${valueResult.errors.join(', ')}');
        }
        
        if (valueResult.warnings.isNotEmpty) {
          warnings.add('键 ${entry.key} 的值有警告: ${valueResult.warnings.join(', ')}');
        }
      }
    }
    
    if (errors.isEmpty) {
      return ValidationResult(isValid: true, warnings: warnings);
    } else {
      return ValidationResult(isValid: false, errors: errors, warnings: warnings);
    }
  }
}

/// 日期验证器
///
/// 验证日期是否符合要求
class DateValidator implements Validator<DateTime> {
  /// 最小日期
  final DateTime? minDate;
  
  /// 最大日期
  final DateTime? maxDate;
  
  /// 错误消息
  final String? minDateError;
  final String? maxDateError;
  
  /// 构造函数
  DateValidator({
    this.minDate,
    this.maxDate,
    this.minDateError,
    this.maxDateError,
  });
  
  @override
  ValidationResult validate(DateTime data) {
    final errors = <String>[];
    
    // 验证最小日期
    if (minDate != null && data.isBefore(minDate!)) {
      errors.add(minDateError ?? '日期不能早于 ${minDate!.toIso8601String()}');
    }
    
    // 验证最大日期
    if (maxDate != null && data.isAfter(maxDate!)) {
      errors.add(maxDateError ?? '日期不能晚于 ${maxDate!.toIso8601String()}');
    }
    
    if (errors.isEmpty) {
      return ValidationResult.valid();
    } else {
      return ValidationResult.invalid(errors);
    }
  }
}

/// 自定义验证器
///
/// 使用自定义函数验证数据
class CustomValidator<T> implements Validator<T> {
  /// 验证函数
  final ValidationResult Function(T data) validateFunction;
  
  /// 构造函数
  CustomValidator(this.validateFunction);
  
  @override
  ValidationResult validate(T data) {
    return validateFunction(data);
  }
}
