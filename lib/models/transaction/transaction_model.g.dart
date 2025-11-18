// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 11;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      type: fields[3] as TransactionType,
      category: fields[4] as TransactionCategory,
      date: fields[5] as DateTime,
      description: fields[6] as String?,
      mpesaCode: fields[7] as String?,
      recipient: fields[8] as String?,
      isRecurring: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.mpesaCode)
      ..writeByte(8)
      ..write(obj.recipient)
      ..writeByte(9)
      ..write(obj.isRecurring);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 9;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.income;
      case 1:
        return TransactionType.expense;
      default:
        return TransactionType.income;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.income:
        writer.writeByte(0);
        break;
      case TransactionType.expense:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionCategoryAdapter extends TypeAdapter<TransactionCategory> {
  @override
  final int typeId = 10;

  @override
  TransactionCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionCategory.salary;
      case 1:
        return TransactionCategory.freelance;
      case 2:
        return TransactionCategory.mpesa;
      case 3:
        return TransactionCategory.groceries;
      case 4:
        return TransactionCategory.transport;
      case 5:
        return TransactionCategory.utilities;
      case 6:
        return TransactionCategory.entertainment;
      case 7:
        return TransactionCategory.dining;
      case 8:
        return TransactionCategory.shopping;
      case 9:
        return TransactionCategory.health;
      case 10:
        return TransactionCategory.education;
      case 11:
        return TransactionCategory.investment;
      case 12:
        return TransactionCategory.other;
      default:
        return TransactionCategory.salary;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionCategory obj) {
    switch (obj) {
      case TransactionCategory.salary:
        writer.writeByte(0);
        break;
      case TransactionCategory.freelance:
        writer.writeByte(1);
        break;
      case TransactionCategory.mpesa:
        writer.writeByte(2);
        break;
      case TransactionCategory.groceries:
        writer.writeByte(3);
        break;
      case TransactionCategory.transport:
        writer.writeByte(4);
        break;
      case TransactionCategory.utilities:
        writer.writeByte(5);
        break;
      case TransactionCategory.entertainment:
        writer.writeByte(6);
        break;
      case TransactionCategory.dining:
        writer.writeByte(7);
        break;
      case TransactionCategory.shopping:
        writer.writeByte(8);
        break;
      case TransactionCategory.health:
        writer.writeByte(9);
        break;
      case TransactionCategory.education:
        writer.writeByte(10);
        break;
      case TransactionCategory.investment:
        writer.writeByte(11);
        break;
      case TransactionCategory.other:
        writer.writeByte(12);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
