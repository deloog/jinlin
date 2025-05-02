/// 验证结果
///
/// 表示数据验证的结果，包括是否有效和错误信息
class ValidationResult {
  /// 是否有效
  final bool isValid;
  
  /// 错误信息
  final List<String> errors;
  
  /// 警告信息
  final List<String> warnings;
  
  /// 构造函数
  ValidationResult({
    required this.isValid,
    List<String>? errors,
    List<String>? warnings,
  }) : 
    errors = errors ?? [],
    warnings = warnings ?? [];
  
  /// 创建有效的验证结果
  factory ValidationResult.valid() {
    return ValidationResult(isValid: true);
  }
  
  /// 创建无效的验证结果
  factory ValidationResult.invalid(List<String> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }
  
  /// 创建带有警告的验证结果
  factory ValidationResult.withWarnings(List<String> warnings) {
    return ValidationResult(isValid: true, warnings: warnings);
  }
  
  /// 合并两个验证结果
  ValidationResult merge(ValidationResult other) {
    return ValidationResult(
      isValid: isValid && other.isValid,
      errors: [...errors, ...other.errors],
      warnings: [...warnings, ...other.warnings],
    );
  }
  
  /// 添加错误
  ValidationResult addError(String error) {
    return ValidationResult(
      isValid: false,
      errors: [...errors, error],
      warnings: warnings,
    );
  }
  
  /// 添加警告
  ValidationResult addWarning(String warning) {
    return ValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: [...warnings, warning],
    );
  }
  
  @override
  String toString() {
    if (isValid && warnings.isEmpty) {
      return '验证通过';
    } else if (isValid) {
      return '验证通过，但有警告：${warnings.join(', ')}';
    } else {
      return '验证失败：${errors.join(', ')}';
    }
  }
}
