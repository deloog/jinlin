import 'package:flutter/material.dart';
import 'package:jinlin_app/special_date.dart';

/// 获取特殊日期列表
///
/// 这是一个临时的方法，用于在数据库迁移过程中提供数据
/// 实际应用中应该从数据库获取数据
List<SpecialDate> getSpecialDays(BuildContext context) {
  // 返回一个空列表，因为我们现在使用数据库存储节日数据
  // 这个方法只是为了兼容旧代码
  return [];
}

/// 获取默认特殊日期列表
///
/// 这是一个不需要BuildContext的版本，用于在无法获取BuildContext的情况下提供数据
/// 实际应用中应该从数据库获取数据
List<SpecialDate> getDefaultSpecialDays() {
  // 返回一个空列表，因为我们现在使用数据库存储节日数据
  // 这个方法只是为了兼容旧代码
  return [];
}
