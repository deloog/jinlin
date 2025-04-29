// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HolidayModelAdapter extends TypeAdapter<HolidayModel> {
  @override
  final int typeId = 0;

  @override
  HolidayModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HolidayModel(
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
    );
  }

  @override
  void write(BinaryWriter writer, HolidayModel obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.userImportance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HolidayModelAdapter &&
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
