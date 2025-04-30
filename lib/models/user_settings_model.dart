import 'package:hive/hive.dart';

// 这个文件将由build_runner生成
// 运行命令: flutter pub run build_runner build
part 'user_settings_model.g.dart';

/// 主题模式
@HiveType(typeId: 14)
enum AppThemeMode {
  @HiveField(0)
  system, // 跟随系统

  @HiveField(1)
  light, // 浅色主题

  @HiveField(2)
  dark // 深色主题
}

/// 提醒提前时间
@HiveType(typeId: 15)
enum ReminderAdvanceTime {
  @HiveField(0)
  sameDay, // 当天

  @HiveField(1)
  oneDay, // 提前1天

  @HiveField(2)
  threeDays, // 提前3天

  @HiveField(3)
  oneWeek, // 提前1周

  @HiveField(4)
  twoWeeks, // 提前2周

  @HiveField(5)
  oneMonth // 提前1个月
}

/// 用户设置模型
@HiveType(typeId: 16)
class UserSettingsModel extends HiveObject {
  // 基本信息
  @HiveField(0)
  String userId;

  @HiveField(1)
  String nickname;

  @HiveField(2)
  String? avatarUrl;

  // 语言和地区设置
  @HiveField(3)
  String languageCode; // 语言代码，如 'zh', 'en'

  @HiveField(4)
  String? countryCode; // 国家代码，如 'CN', 'US'

  @HiveField(5)
  bool showLunarCalendar; // 是否显示农历

  // 主题和外观设置
  @HiveField(6)
  AppThemeMode themeMode;

  @HiveField(7)
  String? primaryColor; // 主题颜色

  @HiveField(8)
  String? backgroundImageUrl; // 背景图片URL

  // 提醒设置
  @HiveField(9)
  bool enableNotifications;

  @HiveField(10)
  Map<String, ReminderAdvanceTime> defaultReminderTimes; // 不同类型节日的默认提醒提前时间

  @HiveField(11)
  bool enableSound;

  @HiveField(12)
  bool enableVibration;

  // 隐私和同步设置
  @HiveField(13)
  bool enableCloudSync;

  @HiveField(14)
  int syncFrequencyHours; // 同步频率（小时）

  @HiveField(15)
  DateTime? lastSyncTime; // 最后同步时间

  @HiveField(16)
  bool autoBackup;

  @HiveField(17)
  int backupFrequencyDays; // 备份频率（天）

  @HiveField(18)
  DateTime? lastBackupTime; // 最后备份时间

  // 高级设置
  @HiveField(19)
  bool showExpiredEvents;

  @HiveField(20)
  int expiredEventRetentionDays; // 过期事件保留天数

  @HiveField(21)
  bool enableAIFeatures;

  @HiveField(22)
  Map<String, bool> enabledAIFeatures; // 启用的AI功能

  @HiveField(23)
  DateTime lastModified;

  UserSettingsModel({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.languageCode,
    this.countryCode,
    this.showLunarCalendar = false,
    this.themeMode = AppThemeMode.system,
    this.primaryColor,
    this.backgroundImageUrl,
    this.enableNotifications = true,
    Map<String, ReminderAdvanceTime>? defaultReminderTimes,
    this.enableSound = true,
    this.enableVibration = true,
    this.enableCloudSync = false,
    this.syncFrequencyHours = 24,
    this.lastSyncTime,
    this.autoBackup = false,
    this.backupFrequencyDays = 7,
    this.lastBackupTime,
    this.showExpiredEvents = false,
    this.expiredEventRetentionDays = 30,
    this.enableAIFeatures = true,
    Map<String, bool>? enabledAIFeatures,
    DateTime? lastModified,
  }) :
    defaultReminderTimes = defaultReminderTimes ?? {
      'birthday': ReminderAdvanceTime.oneWeek,
      'anniversary': ReminderAdvanceTime.oneWeek,
      'memorial': ReminderAdvanceTime.threeDays,
      'holiday': ReminderAdvanceTime.oneDay,
      'other': ReminderAdvanceTime.oneDay,
    },
    enabledAIFeatures = enabledAIFeatures ?? {
      'description': true,
      'greeting': true,
      'gift': true,
      'tips': true,
    },
    lastModified = lastModified ?? DateTime.now();

  /// 从JSON创建用户设置模型
  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      userId: json['userId'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      languageCode: json['languageCode'] as String,
      countryCode: json['countryCode'] as String?,
      showLunarCalendar: json['showLunarCalendar'] as bool? ?? false,
      themeMode: _parseThemeMode(json['themeMode']),
      primaryColor: json['primaryColor'] as String?,
      backgroundImageUrl: json['backgroundImageUrl'] as String?,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      defaultReminderTimes: json['defaultReminderTimes'] != null
          ? (json['defaultReminderTimes'] as Map).map(
              (key, value) => MapEntry(
                key as String,
                _parseReminderAdvanceTime(value),
              ),
            )
          : null,
      enableSound: json['enableSound'] as bool? ?? true,
      enableVibration: json['enableVibration'] as bool? ?? true,
      enableCloudSync: json['enableCloudSync'] as bool? ?? false,
      syncFrequencyHours: json['syncFrequencyHours'] as int? ?? 24,
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'] as String)
          : null,
      autoBackup: json['autoBackup'] as bool? ?? false,
      backupFrequencyDays: json['backupFrequencyDays'] as int? ?? 7,
      lastBackupTime: json['lastBackupTime'] != null
          ? DateTime.parse(json['lastBackupTime'] as String)
          : null,
      showExpiredEvents: json['showExpiredEvents'] as bool? ?? false,
      expiredEventRetentionDays: json['expiredEventRetentionDays'] as int? ?? 30,
      enableAIFeatures: json['enableAIFeatures'] as bool? ?? true,
      enabledAIFeatures: json['enabledAIFeatures'] != null
          ? (json['enabledAIFeatures'] as Map).map(
              (key, value) => MapEntry(key as String, value as bool),
            )
          : null,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : DateTime.now(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'languageCode': languageCode,
      'countryCode': countryCode,
      'showLunarCalendar': showLunarCalendar,
      'themeMode': themeMode.toString().split('.').last,
      'primaryColor': primaryColor,
      'backgroundImageUrl': backgroundImageUrl,
      'enableNotifications': enableNotifications,
      'defaultReminderTimes': defaultReminderTimes.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'enableSound': enableSound,
      'enableVibration': enableVibration,
      'enableCloudSync': enableCloudSync,
      'syncFrequencyHours': syncFrequencyHours,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'autoBackup': autoBackup,
      'backupFrequencyDays': backupFrequencyDays,
      'lastBackupTime': lastBackupTime?.toIso8601String(),
      'showExpiredEvents': showExpiredEvents,
      'expiredEventRetentionDays': expiredEventRetentionDays,
      'enableAIFeatures': enableAIFeatures,
      'enabledAIFeatures': enabledAIFeatures,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  /// 创建带有更新时间的副本
  UserSettingsModel copyWithLastModified() {
    return UserSettingsModel(
      userId: userId,
      nickname: nickname,
      avatarUrl: avatarUrl,
      languageCode: languageCode,
      countryCode: countryCode,
      showLunarCalendar: showLunarCalendar,
      themeMode: themeMode,
      primaryColor: primaryColor,
      backgroundImageUrl: backgroundImageUrl,
      enableNotifications: enableNotifications,
      defaultReminderTimes: defaultReminderTimes,
      enableSound: enableSound,
      enableVibration: enableVibration,
      enableCloudSync: enableCloudSync,
      syncFrequencyHours: syncFrequencyHours,
      lastSyncTime: lastSyncTime,
      autoBackup: autoBackup,
      backupFrequencyDays: backupFrequencyDays,
      lastBackupTime: lastBackupTime,
      showExpiredEvents: showExpiredEvents,
      expiredEventRetentionDays: expiredEventRetentionDays,
      enableAIFeatures: enableAIFeatures,
      enabledAIFeatures: enabledAIFeatures,
      lastModified: DateTime.now(),
    );
  }

  /// 解析主题模式
  static AppThemeMode _parseThemeMode(dynamic value) {
    if (value is AppThemeMode) return value;
    if (value is String) {
      try {
        return AppThemeMode.values.firstWhere(
          (e) => e.toString().split('.').last == value,
        );
      } catch (_) {}
    }
    return AppThemeMode.system;
  }

  /// 解析提醒提前时间
  static ReminderAdvanceTime _parseReminderAdvanceTime(dynamic value) {
    if (value is ReminderAdvanceTime) return value;
    if (value is String) {
      try {
        return ReminderAdvanceTime.values.firstWhere(
          (e) => e.toString().split('.').last == value,
        );
      } catch (_) {}
    }
    return ReminderAdvanceTime.oneDay;
  }
}
