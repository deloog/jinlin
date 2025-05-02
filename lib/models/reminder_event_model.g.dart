// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderEventModelAdapter extends TypeAdapter<ReminderEventModel> {
  @override
  final int typeId = 19;

  @override
  ReminderEventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReminderEventModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      type: fields[3] as ReminderEventType,
      dueDate: fields[4] as DateTime?,
      isAllDay: fields[5] as bool,
      isLunarDate: fields[6] as bool,
      status: fields[7] as ReminderStatus,
      isCompleted: fields[8] as bool,
      completedAt: fields[9] as DateTime?,
      isRepeating: fields[10] as bool,
      repeatRule: fields[11] as String?,
      repeatUntil: fields[12] as DateTime?,
      reminderTimes: (fields[13] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      contactId: fields[14] as String?,
      holidayId: fields[15] as String?,
      location: fields[16] as String?,
      latitude: fields[17] as double?,
      longitude: fields[18] as double?,
      tags: (fields[19] as List?)?.cast<String>(),
      category: fields[20] as String?,
      titles: (fields[21] as Map?)?.cast<String, String>(),
      descriptions: (fields[22] as Map?)?.cast<String, String>(),
      aiGeneratedDescription: fields[23] as String?,
      aiGeneratedGreetings: (fields[24] as List?)?.cast<String>(),
      aiGeneratedGiftSuggestions: (fields[25] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      createdAt: fields[26] as DateTime?,
      lastModified: fields[27] as DateTime?,
      importance: fields[28] as int,
      customColor: fields[29] as String?,
      customIcon: fields[30] as String?,
      isShared: fields[31] as bool,
      sharedWith: (fields[32] as List?)?.cast<String>(),
      lastSynced: fields[33] as DateTime?,
      isSyncConflict: fields[34] as bool,
      isDeleted: fields[35] as bool,
      deletedAt: fields[36] as DateTime?,
      deletionReason: fields[37] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReminderEventModel obj) {
    writer
      ..writeByte(38)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.isAllDay)
      ..writeByte(6)
      ..write(obj.isLunarDate)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.isRepeating)
      ..writeByte(11)
      ..write(obj.repeatRule)
      ..writeByte(12)
      ..write(obj.repeatUntil)
      ..writeByte(13)
      ..write(obj.reminderTimes)
      ..writeByte(14)
      ..write(obj.contactId)
      ..writeByte(15)
      ..write(obj.holidayId)
      ..writeByte(16)
      ..write(obj.location)
      ..writeByte(17)
      ..write(obj.latitude)
      ..writeByte(18)
      ..write(obj.longitude)
      ..writeByte(19)
      ..write(obj.tags)
      ..writeByte(20)
      ..write(obj.category)
      ..writeByte(21)
      ..write(obj.titles)
      ..writeByte(22)
      ..write(obj.descriptions)
      ..writeByte(23)
      ..write(obj.aiGeneratedDescription)
      ..writeByte(24)
      ..write(obj.aiGeneratedGreetings)
      ..writeByte(25)
      ..write(obj.aiGeneratedGiftSuggestions)
      ..writeByte(26)
      ..write(obj.createdAt)
      ..writeByte(27)
      ..write(obj.lastModified)
      ..writeByte(28)
      ..write(obj.importance)
      ..writeByte(29)
      ..write(obj.customColor)
      ..writeByte(30)
      ..write(obj.customIcon)
      ..writeByte(31)
      ..write(obj.isShared)
      ..writeByte(32)
      ..write(obj.sharedWith)
      ..writeByte(33)
      ..write(obj.lastSynced)
      ..writeByte(34)
      ..write(obj.isSyncConflict)
      ..writeByte(35)
      ..write(obj.isDeleted)
      ..writeByte(36)
      ..write(obj.deletedAt)
      ..writeByte(37)
      ..write(obj.deletionReason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderEventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderEventTypeAdapter extends TypeAdapter<ReminderEventType> {
  @override
  final int typeId = 17;

  @override
  ReminderEventType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderEventType.birthday;
      case 1:
        return ReminderEventType.anniversary;
      case 2:
        return ReminderEventType.holiday;
      case 3:
        return ReminderEventType.appointment;
      case 4:
        return ReminderEventType.task;
      case 5:
        return ReminderEventType.memorial;
      case 6:
        return ReminderEventType.other;
      default:
        return ReminderEventType.birthday;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderEventType obj) {
    switch (obj) {
      case ReminderEventType.birthday:
        writer.writeByte(0);
        break;
      case ReminderEventType.anniversary:
        writer.writeByte(1);
        break;
      case ReminderEventType.holiday:
        writer.writeByte(2);
        break;
      case ReminderEventType.appointment:
        writer.writeByte(3);
        break;
      case ReminderEventType.task:
        writer.writeByte(4);
        break;
      case ReminderEventType.memorial:
        writer.writeByte(5);
        break;
      case ReminderEventType.other:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderEventTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderStatusAdapter extends TypeAdapter<ReminderStatus> {
  @override
  final int typeId = 18;

  @override
  ReminderStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderStatus.pending;
      case 1:
        return ReminderStatus.completed;
      case 2:
        return ReminderStatus.missed;
      case 3:
        return ReminderStatus.cancelled;
      default:
        return ReminderStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderStatus obj) {
    switch (obj) {
      case ReminderStatus.pending:
        writer.writeByte(0);
        break;
      case ReminderStatus.completed:
        writer.writeByte(1);
        break;
      case ReminderStatus.missed:
        writer.writeByte(2);
        break;
      case ReminderStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
