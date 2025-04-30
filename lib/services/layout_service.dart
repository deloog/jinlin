// 文件： lib/services/layout_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 布局服务
///
/// 用于管理应用程序的布局设置
class LayoutService {
  // 单例模式
  static final LayoutService _instance = LayoutService._internal();
  
  factory LayoutService() {
    return _instance;
  }
  
  LayoutService._internal();
  
  // 首页布局类型
  static const String _homeLayoutTypeKey = 'homeLayoutType';
  
  // 卡片样式类型
  static const String _cardStyleTypeKey = 'cardStyleType';
  
  // 提醒优先级设置
  static const String _reminderPriorityKey = 'reminderPriority';
  
  // 首页布局类型
  HomeLayoutType _homeLayoutType = HomeLayoutType.timeline;
  
  // 卡片样式类型
  CardStyleType _cardStyleType = CardStyleType.standard;
  
  // 提醒优先级设置
  ReminderPriority _reminderPriority = ReminderPriority.dateOrder;
  
  // 初始化
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载首页布局类型
    final homeLayoutTypeIndex = prefs.getInt(_homeLayoutTypeKey) ?? 0;
    _homeLayoutType = HomeLayoutType.values[homeLayoutTypeIndex];
    
    // 加载卡片样式类型
    final cardStyleTypeIndex = prefs.getInt(_cardStyleTypeKey) ?? 0;
    _cardStyleType = CardStyleType.values[cardStyleTypeIndex];
    
    // 加载提醒优先级设置
    final reminderPriorityIndex = prefs.getInt(_reminderPriorityKey) ?? 0;
    _reminderPriority = ReminderPriority.values[reminderPriorityIndex];
  }
  
  // 获取首页布局类型
  HomeLayoutType get homeLayoutType => _homeLayoutType;
  
  // 获取卡片样式类型
  CardStyleType get cardStyleType => _cardStyleType;
  
  // 获取提醒优先级设置
  ReminderPriority get reminderPriority => _reminderPriority;
  
  // 设置首页布局类型
  Future<void> setHomeLayoutType(HomeLayoutType type) async {
    if (_homeLayoutType == type) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_homeLayoutTypeKey, type.index);
    _homeLayoutType = type;
  }
  
  // 设置卡片样式类型
  Future<void> setCardStyleType(CardStyleType type) async {
    if (_cardStyleType == type) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cardStyleTypeKey, type.index);
    _cardStyleType = type;
  }
  
  // 设置提醒优先级设置
  Future<void> setReminderPriority(ReminderPriority priority) async {
    if (_reminderPriority == priority) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderPriorityKey, priority.index);
    _reminderPriority = priority;
  }
  
  // 获取首页布局类型名称
  String getHomeLayoutTypeName(BuildContext context, bool isChinese) {
    switch (_homeLayoutType) {
      case HomeLayoutType.timeline:
        return isChinese ? '时间线视图' : 'Timeline View';
      case HomeLayoutType.calendar:
        return isChinese ? '日历视图' : 'Calendar View';
      case HomeLayoutType.list:
        return isChinese ? '列表视图' : 'List View';
    }
  }
  
  // 获取卡片样式类型名称
  String getCardStyleTypeName(BuildContext context, bool isChinese) {
    switch (_cardStyleType) {
      case CardStyleType.standard:
        return isChinese ? '标准样式' : 'Standard Style';
      case CardStyleType.compact:
        return isChinese ? '紧凑样式' : 'Compact Style';
      case CardStyleType.expanded:
        return isChinese ? '展开样式' : 'Expanded Style';
    }
  }
  
  // 获取提醒优先级设置名称
  String getReminderPriorityName(BuildContext context, bool isChinese) {
    switch (_reminderPriority) {
      case ReminderPriority.dateOrder:
        return isChinese ? '按日期排序' : 'Date Order';
      case ReminderPriority.importanceFirst:
        return isChinese ? '重要性优先' : 'Importance First';
      case ReminderPriority.typeGrouped:
        return isChinese ? '按类型分组' : 'Type Grouped';
    }
  }
  
  // 获取首页布局类型图标
  IconData getHomeLayoutTypeIcon() {
    switch (_homeLayoutType) {
      case HomeLayoutType.timeline:
        return Icons.timeline;
      case HomeLayoutType.calendar:
        return Icons.calendar_month;
      case HomeLayoutType.list:
        return Icons.list;
    }
  }
  
  // 获取卡片样式类型图标
  IconData getCardStyleTypeIcon() {
    switch (_cardStyleType) {
      case CardStyleType.standard:
        return Icons.crop_square;
      case CardStyleType.compact:
        return Icons.crop_7_5;
      case CardStyleType.expanded:
        return Icons.crop_16_9;
    }
  }
  
  // 获取提醒优先级设置图标
  IconData getReminderPriorityIcon() {
    switch (_reminderPriority) {
      case ReminderPriority.dateOrder:
        return Icons.date_range;
      case ReminderPriority.importanceFirst:
        return Icons.priority_high;
      case ReminderPriority.typeGrouped:
        return Icons.category;
    }
  }
}

/// 首页布局类型
enum HomeLayoutType {
  timeline, // 时间线视图
  calendar, // 日历视图
  list, // 列表视图
}

/// 卡片样式类型
enum CardStyleType {
  standard, // 标准样式
  compact, // 紧凑样式
  expanded, // 展开样式
}

/// 提醒优先级设置
enum ReminderPriority {
  dateOrder, // 按日期排序
  importanceFirst, // 重要性优先
  typeGrouped, // 按类型分组
}
