// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestmentTypeAdapter extends TypeAdapter<InvestmentType> {
  @override
  final int typeId = 23;

  @override
  InvestmentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InvestmentType.stock;
      case 1:
        return InvestmentType.mmf;
      case 2:
        return InvestmentType.crypto;
      case 3:
        return InvestmentType.bond;
      case 4:
        return InvestmentType.property;
      case 5:
        return InvestmentType.other;
      default:
        return InvestmentType.other;
    }
  }

  @override
  void write(BinaryWriter writer, InvestmentType obj) {
    switch (obj) {
      case InvestmentType.stock:
        writer.writeByte(0);
        break;
      case InvestmentType.mmf:
        writer.writeByte(1);
        break;
      case InvestmentType.crypto:
        writer.writeByte(2);
        break;
      case InvestmentType.bond:
        writer.writeByte(3);
        break;
      case InvestmentType.property:
        writer.writeByte(4);
        break;
      case InvestmentType.other:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvestmentModelAdapter extends TypeAdapter<InvestmentModel> {
  @override
  final int typeId = 24;

  @override
  InvestmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvestmentModel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as InvestmentType,
      principalAmount: fields[3] as double,
      currentValue: fields[4] as double,
      quantity: fields[5] as double,
      notes: fields[6] as String,
      lastUpdated: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, InvestmentModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.principalAmount)
      ..writeByte(4)
      ..write(obj.currentValue)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
