// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountSnapshotAdapter extends TypeAdapter<AccountSnapshot> {
  @override
  final int typeId = 8;

  @override
  AccountSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountSnapshot(
      id: fields[0] as String,
      accountId: fields[1] as String,
      balance: fields[2] as double,
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AccountSnapshot obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.balance)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
