// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContactModelAdapter extends TypeAdapter<ContactModel> {
  @override
  final int typeId = 13;

  @override
  ContactModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContactModel(
      id: fields[0] as String,
      name: fields[1] as String,
      relationType: fields[2] as RelationType,
      specificRelation: fields[3] as String?,
      phoneNumber: fields[4] as String?,
      email: fields[5] as String?,
      avatarUrl: fields[6] as String?,
      birthday: fields[7] as DateTime?,
      isBirthdayLunar: fields[8] as bool,
      additionalInfo: (fields[9] as Map?)?.cast<String, String>(),
      associatedHolidayIds: (fields[10] as List?)?.cast<String>(),
      createdAt: fields[11] as DateTime?,
      lastModified: fields[12] as DateTime?,
      names: (fields[13] as Map?)?.cast<String, String>(),
      specificRelations: (fields[14] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ContactModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.relationType)
      ..writeByte(3)
      ..write(obj.specificRelation)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.avatarUrl)
      ..writeByte(7)
      ..write(obj.birthday)
      ..writeByte(8)
      ..write(obj.isBirthdayLunar)
      ..writeByte(9)
      ..write(obj.additionalInfo)
      ..writeByte(10)
      ..write(obj.associatedHolidayIds)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.lastModified)
      ..writeByte(13)
      ..write(obj.names)
      ..writeByte(14)
      ..write(obj.specificRelations);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RelationTypeAdapter extends TypeAdapter<RelationType> {
  @override
  final int typeId = 12;

  @override
  RelationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RelationType.family;
      case 1:
        return RelationType.friend;
      case 2:
        return RelationType.colleague;
      case 3:
        return RelationType.classmate;
      case 4:
        return RelationType.other;
      default:
        return RelationType.family;
    }
  }

  @override
  void write(BinaryWriter writer, RelationType obj) {
    switch (obj) {
      case RelationType.family:
        writer.writeByte(0);
        break;
      case RelationType.friend:
        writer.writeByte(1);
        break;
      case RelationType.colleague:
        writer.writeByte(2);
        break;
      case RelationType.classmate:
        writer.writeByte(3);
        break;
      case RelationType.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
