// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 4;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      lastMpesaSmsTimestamp: fields[0] as int?,
      initialScanComplete: fields[1] as bool,
      appInstallDate: fields[2] as DateTime?,
      completedWeeks: (fields[3] as List).cast<String>(),
      completedMonths: (fields[4] as List).cast<String>(),
      transactionNotificationsEnabled: fields[5] as bool,
      accountsMerged: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.lastMpesaSmsTimestamp)
      ..writeByte(1)
      ..write(obj.initialScanComplete)
      ..writeByte(2)
      ..write(obj.appInstallDate)
      ..writeByte(3)
      ..write(obj.completedWeeks)
      ..writeByte(4)
      ..write(obj.completedMonths)
      ..writeByte(5)
      ..write(obj.transactionNotificationsEnabled)
      ..writeByte(6)
      ..write(obj.accountsMerged);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
