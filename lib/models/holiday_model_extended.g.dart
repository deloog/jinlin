// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_model_extended.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HolidayModelExtendedAdapter extends TypeAdapter<HolidayModelExtended> {
  @override
  final int typeId = 11;

  @override
  HolidayModelExtended read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HolidayModelExtended(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as HolidayType,
      regions: (fields[3] as List).cast<String>(),
      calculationType: fields[4] as DateCalculationType,
      calculationRule: fields[5] as String,
      description: fields[6] as String?,
      importanceLevel: fields[7] as ImportanceLevel,
      customs: fields[8] as String?,
      taboos: fields[9] as String?,
      foods: fields[10] as String?,
      greetings: fields[11] as String?,
      activities: fields[12] as String?,
      history: fields[13] as String?,
      imageUrl: fields[14] as String?,
      userImportance: fields[15] as int,
      nameEn: fields[16] as String?,
      descriptionEn: fields[17] as String?,
      lastModified: fields[18] as DateTime?,
      names: (fields[19] as Map?)?.cast<String, String>(),
      descriptions: (fields[20] as Map?)?.cast<String, String>(),
      customsMultilingual: (fields[21] as Map?)?.cast<String, String>(),
      taboosMultilingual: (fields[22] as Map?)?.cast<String, String>(),
      foodsMultilingual: (fields[23] as Map?)?.cast<String, String>(),
      greetingsMultilingual: (fields[24] as Map?)?.cast<String, String>(),
      activitiesMultilingual: (fields[25] as Map?)?.cast<String, String>(),
      historyMultilingual: (fields[26] as Map?)?.cast<String, String>(),
      contactId: fields[27] as String?,
      contactName: fields[28] as String?,
      contactRelation: fields[29] as String?,
      contactAvatar: fields[30] as String?,
      tags: (fields[31] as List?)?.cast<String>(),
      groupId: fields[32] as String?,
      aiGeneratedGreetings: (fields[33] as List?)?.cast<String>(),
      aiGeneratedGiftSuggestions: (fields[34] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      aiGeneratedTips: (fields[35] as Map?)?.cast<String, String>(),
      reminderSettings: (fields[36] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      isRepeating: fields[37] as bool,
      repeatRule: fields[38] as String?,
      isShared: fields[39] as bool,
      sharedWith: (fields[40] as List?)?.cast<String>(),
      sharingPermissions: (fields[41] as Map?)?.cast<String, bool>(),
      lastSynced: fields[42] as DateTime?,
      isSyncConflict: fields[43] as bool,
      showLunarDate: fields[44] as bool,
      customColor: fields[45] as String?,
      customIcon: fields[46] as String?,
      createdAt: fields[47] as DateTime?,
      isExpired: fields[48] as bool,
      isHidden: fields[49] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HolidayModelExtended obj) {
    writer
      ..writeByte(50)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.regions)
      ..writeByte(4)
      ..write(obj.calculationType)
      ..writeByte(5)
      ..write(obj.calculationRule)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.importanceLevel)
      ..writeByte(8)
      ..write(obj.customs)
      ..writeByte(9)
      ..write(obj.taboos)
      ..writeByte(10)
      ..write(obj.foods)
      ..writeByte(11)
      ..write(obj.greetings)
      ..writeByte(12)
      ..write(obj.activities)
      ..writeByte(13)
      ..write(obj.history)
      ..writeByte(14)
      ..write(obj.imageUrl)
      ..writeByte(15)
      ..write(obj.userImportance)
      ..writeByte(16)
      ..write(obj.nameEn)
      ..writeByte(17)
      ..write(obj.descriptionEn)
      ..writeByte(18)
      ..write(obj.lastModified)
      ..writeByte(19)
      ..write(obj.names)
      ..writeByte(20)
      ..write(obj.descriptions)
      ..writeByte(21)
      ..write(obj.customsMultilingual)
      ..writeByte(22)
      ..write(obj.taboosMultilingual)
      ..writeByte(23)
      ..write(obj.foodsMultilingual)
      ..writeByte(24)
      ..write(obj.greetingsMultilingual)
      ..writeByte(25)
      ..write(obj.activitiesMultilingual)
      ..writeByte(26)
      ..write(obj.historyMultilingual)
      ..writeByte(27)
      ..write(obj.contactId)
      ..writeByte(28)
      ..write(obj.contactName)
      ..writeByte(29)
      ..write(obj.contactRelation)
      ..writeByte(30)
      ..write(obj.contactAvatar)
      ..writeByte(31)
      ..write(obj.tags)
      ..writeByte(32)
      ..write(obj.groupId)
      ..writeByte(33)
      ..write(obj.aiGeneratedGreetings)
      ..writeByte(34)
      ..write(obj.aiGeneratedGiftSuggestions)
      ..writeByte(35)
      ..write(obj.aiGeneratedTips)
      ..writeByte(36)
      ..write(obj.reminderSettings)
      ..writeByte(37)
      ..write(obj.isRepeating)
      ..writeByte(38)
      ..write(obj.repeatRule)
      ..writeByte(39)
      ..write(obj.isShared)
      ..writeByte(40)
      ..write(obj.sharedWith)
      ..writeByte(41)
      ..write(obj.sharingPermissions)
      ..writeByte(42)
      ..write(obj.lastSynced)
      ..writeByte(43)
      ..write(obj.isSyncConflict)
      ..writeByte(44)
      ..write(obj.showLunarDate)
      ..writeByte(45)
      ..write(obj.customColor)
      ..writeByte(46)
      ..write(obj.customIcon)
      ..writeByte(47)
      ..write(obj.createdAt)
      ..writeByte(48)
      ..write(obj.isExpired)
      ..writeByte(49)
      ..write(obj.isHidden);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HolidayModelExtendedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HolidayTypeAdapter extends TypeAdapter<HolidayType> {
  @override
  final int typeId = 1;

  @override
  HolidayType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HolidayType.statutory;
      case 1:
        return HolidayType.traditional;
      case 2:
        return HolidayType.solarTerm;
      case 3:
        return HolidayType.memorial;
      case 4:
        return HolidayType.custom;
      case 5:
        return HolidayType.other;
      case 6:
        return HolidayType.religious;
      case 7:
        return HolidayType.international;
      case 8:
        return HolidayType.professional;
      case 9:
        return HolidayType.cultural;
      default:
        return HolidayType.statutory;
    }
  }

  @override
  void write(BinaryWriter writer, HolidayType obj) {
    switch (obj) {
      case HolidayType.statutory:
        writer.writeByte(0);
        break;
      case HolidayType.traditional:
        writer.writeByte(1);
        break;
      case HolidayType.solarTerm:
        writer.writeByte(2);
        break;
      case HolidayType.memorial:
        writer.writeByte(3);
        break;
      case HolidayType.custom:
        writer.writeByte(4);
        break;
      case HolidayType.other:
        writer.writeByte(5);
        break;
      case HolidayType.religious:
        writer.writeByte(6);
        break;
      case HolidayType.international:
        writer.writeByte(7);
        break;
      case HolidayType.professional:
        writer.writeByte(8);
        break;
      case HolidayType.cultural:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HolidayTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DateCalculationTypeAdapter extends TypeAdapter<DateCalculationType> {
  @override
  final int typeId = 2;

  @override
  DateCalculationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DateCalculationType.fixedGregorian;
      case 1:
        return DateCalculationType.fixedLunar;
      case 2:
        return DateCalculationType.nthWeekdayOfMonth;
      case 3:
        return DateCalculationType.solarTermBased;
      case 4:
        return DateCalculationType.relativeTo;
      case 5:
        return DateCalculationType.lastWeekdayOfMonth;
      case 6:
        return DateCalculationType.easterBased;
      case 7:
        return DateCalculationType.lunarPhase;
      case 8:
        return DateCalculationType.seasonBased;
      case 9:
        return DateCalculationType.weekOfYear;
      default:
        return DateCalculationType.fixedGregorian;
    }
  }

  @override
  void write(BinaryWriter writer, DateCalculationType obj) {
    switch (obj) {
      case DateCalculationType.fixedGregorian:
        writer.writeByte(0);
        break;
      case DateCalculationType.fixedLunar:
        writer.writeByte(1);
        break;
      case DateCalculationType.nthWeekdayOfMonth:
        writer.writeByte(2);
        break;
      case DateCalculationType.solarTermBased:
        writer.writeByte(3);
        break;
      case DateCalculationType.relativeTo:
        writer.writeByte(4);
        break;
      case DateCalculationType.lastWeekdayOfMonth:
        writer.writeByte(5);
        break;
      case DateCalculationType.easterBased:
        writer.writeByte(6);
        break;
      case DateCalculationType.lunarPhase:
        writer.writeByte(7);
        break;
      case DateCalculationType.seasonBased:
        writer.writeByte(8);
        break;
      case DateCalculationType.weekOfYear:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateCalculationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ImportanceLevelAdapter extends TypeAdapter<ImportanceLevel> {
  @override
  final int typeId = 3;

  @override
  ImportanceLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ImportanceLevel.low;
      case 1:
        return ImportanceLevel.medium;
      case 2:
        return ImportanceLevel.high;
      default:
        return ImportanceLevel.low;
    }
  }

  @override
  void write(BinaryWriter writer, ImportanceLevel obj) {
    switch (obj) {
      case ImportanceLevel.low:
        writer.writeByte(0);
        break;
      case ImportanceLevel.medium:
        writer.writeByte(1);
        break;
      case ImportanceLevel.high:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportanceLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderTypeAdapter extends TypeAdapter<ReminderType> {
  @override
  final int typeId = 10;

  @override
  ReminderType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderType.notification;
      case 1:
        return ReminderType.email;
      case 2:
        return ReminderType.sms;
      case 3:
        return ReminderType.alarm;
      default:
        return ReminderType.notification;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderType obj) {
    switch (obj) {
      case ReminderType.notification:
        writer.writeByte(0);
        break;
      case ReminderType.email:
        writer.writeByte(1);
        break;
      case ReminderType.sms:
        writer.writeByte(2);
        break;
      case ReminderType.alarm:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
