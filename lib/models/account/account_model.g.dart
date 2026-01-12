// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 7;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      id: fields[0] as String,
      name: fields[1] as String,
      balance: fields[2] as double,
      type: fields[3] as AccountType,
      isAutomated: fields[4] as bool,
      lastUpdated: fields[5] as DateTime,
      senderAddress: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.balance)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.isAutomated)
      ..writeByte(5)
      ..write(obj.lastUpdated)
      ..writeByte(6)
      ..write(obj.senderAddress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = 6;

  @override
  AccountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountType.Mpesa;
      case 1:
        return AccountType.Bank;
      case 2:
        return AccountType.Cash;
      case 3:
        return AccountType.MobileSavings;
      case 4:
        return AccountType.Liability;
      default:
        return AccountType.Mpesa;
    }
  }

  @override
  void write(BinaryWriter writer, AccountType obj) {
    switch (obj) {
      case AccountType.Mpesa:
        writer.writeByte(0);
        break;
      case AccountType.Bank:
        writer.writeByte(1);
        break;
      case AccountType.Cash:
        writer.writeByte(2);
        break;
      case AccountType.MobileSavings:
        writer.writeByte(3);
        break;
      case AccountType.Liability:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
