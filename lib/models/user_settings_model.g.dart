// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsModelAdapter extends TypeAdapter<UserSettingsModel> {
  @override
  final int typeId = 16;

  @override
  UserSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettingsModel(
      userId: fields[0] as String,
      nickname: fields[1] as String,
      avatarUrl: fields[2] as String?,
      languageCode: fields[3] as String,
      countryCode: fields[4] as String?,
      showLunarCalendar: fields[5] as bool,
      themeMode: fields[6] as AppThemeMode,
      primaryColor: fields[7] as String?,
      backgroundImageUrl: fields[8] as String?,
      enableNotifications: fields[9] as bool,
      defaultReminderTimes:
          (fields[10] as Map?)?.cast<String, ReminderAdvanceTime>(),
      enableSound: fields[11] as bool,
      enableVibration: fields[12] as bool,
      enableCloudSync: fields[13] as bool,
      syncFrequencyHours: fields[14] as int,
      lastSyncTime: fields[15] as DateTime?,
      autoBackup: fields[16] as bool,
      backupFrequencyDays: fields[17] as int,
      lastBackupTime: fields[18] as DateTime?,
      showExpiredEvents: fields[19] as bool,
      expiredEventRetentionDays: fields[20] as int,
      enableAIFeatures: fields[21] as bool,
      enabledAIFeatures: (fields[22] as Map?)?.cast<String, bool>(),
      lastModified: fields[23] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettingsModel obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.nickname)
      ..writeByte(2)
      ..write(obj.avatarUrl)
      ..writeByte(3)
      ..write(obj.languageCode)
      ..writeByte(4)
      ..write(obj.countryCode)
      ..writeByte(5)
      ..write(obj.showLunarCalendar)
      ..writeByte(6)
      ..write(obj.themeMode)
      ..writeByte(7)
      ..write(obj.primaryColor)
      ..writeByte(8)
      ..write(obj.backgroundImageUrl)
      ..writeByte(9)
      ..write(obj.enableNotifications)
      ..writeByte(10)
      ..write(obj.defaultReminderTimes)
      ..writeByte(11)
      ..write(obj.enableSound)
      ..writeByte(12)
      ..write(obj.enableVibration)
      ..writeByte(13)
      ..write(obj.enableCloudSync)
      ..writeByte(14)
      ..write(obj.syncFrequencyHours)
      ..writeByte(15)
      ..write(obj.lastSyncTime)
      ..writeByte(16)
      ..write(obj.autoBackup)
      ..writeByte(17)
      ..write(obj.backupFrequencyDays)
      ..writeByte(18)
      ..write(obj.lastBackupTime)
      ..writeByte(19)
      ..write(obj.showExpiredEvents)
      ..writeByte(20)
      ..write(obj.expiredEventRetentionDays)
      ..writeByte(21)
      ..write(obj.enableAIFeatures)
      ..writeByte(22)
      ..write(obj.enabledAIFeatures)
      ..writeByte(23)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppThemeModeAdapter extends TypeAdapter<AppThemeMode> {
  @override
  final int typeId = 14;

  @override
  AppThemeMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppThemeMode.system;
      case 1:
        return AppThemeMode.light;
      case 2:
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  @override
  void write(BinaryWriter writer, AppThemeMode obj) {
    switch (obj) {
      case AppThemeMode.system:
        writer.writeByte(0);
        break;
      case AppThemeMode.light:
        writer.writeByte(1);
        break;
      case AppThemeMode.dark:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderAdvanceTimeAdapter extends TypeAdapter<ReminderAdvanceTime> {
  @override
  final int typeId = 15;

  @override
  ReminderAdvanceTime read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderAdvanceTime.sameDay;
      case 1:
        return ReminderAdvanceTime.oneDay;
      case 2:
        return ReminderAdvanceTime.threeDays;
      case 3:
        return ReminderAdvanceTime.oneWeek;
      case 4:
        return ReminderAdvanceTime.twoWeeks;
      case 5:
        return ReminderAdvanceTime.oneMonth;
      default:
        return ReminderAdvanceTime.sameDay;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderAdvanceTime obj) {
    switch (obj) {
      case ReminderAdvanceTime.sameDay:
        writer.writeByte(0);
        break;
      case ReminderAdvanceTime.oneDay:
        writer.writeByte(1);
        break;
      case ReminderAdvanceTime.threeDays:
        writer.writeByte(2);
        break;
      case ReminderAdvanceTime.oneWeek:
        writer.writeByte(3);
        break;
      case ReminderAdvanceTime.twoWeeks:
        writer.writeByte(4);
        break;
      case ReminderAdvanceTime.oneMonth:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdvanceTimeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
