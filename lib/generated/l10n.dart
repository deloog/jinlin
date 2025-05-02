// 临时本地化文件，用于解决编译错误
// 这个文件应该由 Flutter 的本地化工具自动生成
// 请运行 flutter pub run intl_generator:generate_from_arb --output-dir=lib/generated --no-use-deferred-loading lib/l10n/app_localizations_*.arb

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class S {
  final String localeName;

  S(this.localeName);

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S) ?? S('en');
  }

  static const delegate = _AppLocalizationsDelegate();

  // 通用设置
  String get settings => 'Settings';
  String get generalSettings => 'General Settings';
  String get language => 'Language';
  String get currentLanguage => 'English';
  String get theme => 'Theme';
  String get currentTheme => 'Light';
  String get notifications => 'Notifications';
  String get notificationSettings => 'Notification Settings';

  // 数据设置
  String get dataSettings => 'Data Settings';
  String get backupAndRestore => 'Backup & Restore';
  String get backupAndRestoreDescription => 'Backup and restore your data';
  String get dataManagement => 'Data Management';
  String get dataManagementDescription => 'Manage your data';
  String get importExport => 'Import & Export';
  String get importExportDescription => 'Import and export your data';

  // 同步设置
  String get syncSettings => 'Sync Settings';
  String get cloudSync => 'Cloud Sync';
  String get syncStatus => 'Sync Status';
  String get syncManagement => 'Sync Management';
  String get lastSync => 'Last Sync';
  String get never => 'Never';
  String get syncNow => 'Sync Now';
  String get syncOperations => 'Sync Operations';
  String get syncConflicts => 'Sync Conflicts';
  String get viewAll => 'View All';
  String get sync => 'Sync';
  String get autoSync => 'Auto Sync';
  String get autoSyncDescription => 'Automatically sync data';
  String get syncManagementDescription => 'Manage sync settings';
  String get syncing => 'Syncing';
  String get lastSyncTimeAgo => 'Last sync time';
  String get neverSynced => 'Never synced';
  String get lastSyncTime => 'Last Sync Time';
  String get idle => 'Idle';
  String get lastSyncError => 'Last Sync Error';
  String get pending => 'Pending';
  String get synced => 'Synced';
  String get failed => 'Failed';
  String get conflicts => 'Conflicts';
  String get retry => 'Retry';
  String get cancel => 'Cancel';
  String get syncInterval => 'Sync Interval';
  String syncIntervalMinutes(int minutes) => 'Sync every $minutes minutes';
  String get syncOnlyOnWifi => 'Sync only on Wi-Fi';
  String get syncOnlyOnWifiDescription => 'Only sync when connected to Wi-Fi';
  String get incrementalSync => 'Incremental Sync';
  String get incrementalSyncDescription => 'Only sync changed data';
  String get conflictResolution => 'Conflict Resolution';
  String get selectConflictResolution => 'Select conflict resolution strategy';
  String get syncDeletedData => 'Sync Deleted Data';
  String get syncDeletedDataDescription => 'Sync data that has been deleted';
  String get enableEncryption => 'Enable Encryption';
  String get enableEncryptionDescription => 'Encrypt data during sync';
  String get enableCompression => 'Enable Compression';
  String get enableCompressionDescription => 'Compress data during sync';
  String get clearSyncData => 'Clear Sync Data';
  String get useLocalData => 'Use Local Data';
  String get useServerData => 'Use Server Data';
  String get mergeData => 'Merge Data';
  String get manualResolution => 'Manual Resolution';
  String get selectSyncInterval => 'Select sync interval';
  String get save => 'Save';
  String get hour1 => '1 hour';
  String get day1 => '1 day';
  String get useLocalDataDescription => 'Use local data when conflicts occur';
  String get useServerDataDescription => 'Use server data when conflicts occur';
  String get mergeDataDescription => 'Merge local and server data when conflicts occur';
  String get manualResolutionDescription => 'Manually resolve conflicts';
  String get clearSyncDataConfirmation => 'Are you sure you want to clear all sync data?';
  String get clear => 'Clear';
  String get noSyncOperations => 'No sync operations';
  String get create => 'Create';
  String get update => 'Update';
  String get delete => 'Delete';
  String get softDelete => 'Soft Delete';
  String get restore => 'Restore';
  String get conflict => 'Conflict';
  String get noSyncConflicts => 'No sync conflicts';
  String get resolveConflict => 'Resolve Conflict';
  String get skip => 'Skip';
  String get resolve => 'Resolve';

  // 关于
  String get about => 'About';
  String get appInfo => 'App Info';
  String get help => 'Help';
  String get privacyPolicy => 'Privacy Policy';
  String get termsOfService => 'Terms of Service';

  // 提醒详情
  String get reminderDetailTitle => 'Reminder Details';
  String get deleteConfirmationTitle => 'Delete Confirmation';
  String get deleteConfirmationContent => 'Are you sure you want to delete this reminder?';
  String get cancelButton => 'Cancel';
  String get deleteButtonTooltip => 'Delete';
  String get editButtonTooltip => 'Edit';
  String get dateNotSet => 'Date not set';
  String get descriptionSectionTitle => 'Description';

  // AI 功能
  String get aiAssistantSectionTitle => 'AI Assistant';
  String get aiBlessingSectionTitle => 'AI Blessing';
  String get aiBlessingsPlaceholder => 'AI generated blessings will appear here';
  String get swapBlessingsButton => 'Swap Blessings';
  String get aiGiftSectionTitle => 'Gift Recommendations';
  String get aiGiftsPlaceholder => 'AI gift recommendations will appear here';
  String get smartTipsSectionTitle => 'Smart Tips';
  String get aiTipsPlaceholder => 'AI tips will appear here';

  // 时间格式化
  String minutesCount(int count) => '$count minutes';
  String hoursCount(int count) => '$count hours';
  String daysCount(int count) => '$count days';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<S> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh', 'ja', 'ko', 'fr', 'de'].contains(locale.languageCode);
  }

  @override
  Future<S> load(Locale locale) {
    return Future.value(S(locale.languageCode));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
