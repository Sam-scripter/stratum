// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_pattern.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessagePatternAdapter extends TypeAdapter<MessagePattern> {
  @override
  final int typeId = 9;

  @override
  MessagePattern read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessagePattern(
      id: fields[0] as String,
      pattern: fields[1] as String,
      category: fields[2] as String,
      accountType: fields[3] as String,
      matchCount: fields[4] as int,
      lastSeen: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MessagePattern obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pattern)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.accountType)
      ..writeByte(4)
      ..write(obj.matchCount)
      ..writeByte(5)
      ..write(obj.lastSeen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagePatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
