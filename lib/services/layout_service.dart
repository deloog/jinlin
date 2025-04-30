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

  // 卡片图标形状
  static const String _iconShapeTypeKey = 'iconShapeType';

  // 卡片图标大小
  static const String _iconSizeKey = 'iconSize';

  // 卡片颜色饱和度
  static const String _colorSaturationKey = 'colorSaturation';

  // 首页布局类型
  HomeLayoutType _homeLayoutType = HomeLayoutType.timeline;

  // 卡片样式类型
  CardStyleType _cardStyleType = CardStyleType.standard;

  // 提醒优先级设置
  ReminderPriority _reminderPriority = ReminderPriority.dateOrder;

  // 卡片图标形状
  IconShapeType _iconShapeType = IconShapeType.square;

  // 卡片图标大小
  double _iconSize = 40.0;

  // 卡片颜色饱和度
  double _colorSaturation = 1.0;

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

    // 加载卡片图标形状
    final iconShapeTypeIndex = prefs.getInt(_iconShapeTypeKey) ?? 0;
    _iconShapeType = IconShapeType.values[iconShapeTypeIndex];

    // 加载卡片图标大小
    _iconSize = prefs.getDouble(_iconSizeKey) ?? 40.0;

    // 加载卡片颜色饱和度
    _colorSaturation = prefs.getDouble(_colorSaturationKey) ?? 1.0;
  }

  // 获取首页布局类型
  HomeLayoutType get homeLayoutType => _homeLayoutType;

  // 获取卡片样式类型
  CardStyleType get cardStyleType => _cardStyleType;

  // 获取提醒优先级设置
  ReminderPriority get reminderPriority => _reminderPriority;

  // 获取卡片图标形状
  IconShapeType get iconShapeType => _iconShapeType;

  // 获取卡片图标大小
  double get iconSize => _iconSize;

  // 获取卡片颜色饱和度
  double get colorSaturation => _colorSaturation;

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

  // 设置卡片图标形状
  Future<void> setIconShapeType(IconShapeType type) async {
    if (_iconShapeType == type) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_iconShapeTypeKey, type.index);
    _iconShapeType = type;
  }

  // 设置卡片图标大小
  Future<void> setIconSize(double size) async {
    if (_iconSize == size) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_iconSizeKey, size);
    _iconSize = size;
  }

  // 设置卡片颜色饱和度
  Future<void> setColorSaturation(double saturation) async {
    if (_colorSaturation == saturation) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_colorSaturationKey, saturation);
    _colorSaturation = saturation;
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

  // 获取卡片图标形状名称
  String getIconShapeTypeName(BuildContext context, bool isChinese) {
    switch (_iconShapeType) {
      case IconShapeType.square:
        return isChinese ? '方形图标' : 'Square Icons';
      case IconShapeType.circle:
        return isChinese ? '圆形图标' : 'Circle Icons';
    }
  }

  // 获取卡片图标形状图标
  IconData getIconShapeTypeIcon() {
    switch (_iconShapeType) {
      case IconShapeType.square:
        return Icons.crop_square;
      case IconShapeType.circle:
        return Icons.circle_outlined;
    }
  }

  // 获取卡片图标大小名称
  String getIconSizeName(BuildContext context, bool isChinese, double size) {
    if (size <= 32.0) {
      return isChinese ? '小图标' : 'Small Icons';
    } else if (size <= 40.0) {
      return isChinese ? '中等图标' : 'Medium Icons';
    } else {
      return isChinese ? '大图标' : 'Large Icons';
    }
  }

  // 获取卡片颜色饱和度名称
  String getColorSaturationName(BuildContext context, bool isChinese, double saturation) {
    if (saturation <= 0.5) {
      return isChinese ? '低饱和度' : 'Low Saturation';
    } else if (saturation <= 0.8) {
      return isChinese ? '中等饱和度' : 'Medium Saturation';
    } else {
      return isChinese ? '高饱和度' : 'High Saturation';
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

/// 卡片图标形状
enum IconShapeType {
  square, // 方形
  circle, // 圆形
}
