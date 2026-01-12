// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction_pattern.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTransactionPatternAdapter
    extends TypeAdapter<RecurringTransactionPattern> {
  @override
  final int typeId = 7;

  @override
  RecurringTransactionPattern read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTransactionPattern(
      id: fields[0] as String,
      userId: fields[1] as String,
      patternType: fields[2] as String,
      merchantName: fields[3] as String?,
      amountMin: fields[4] as double?,
      amountMax: fields[5] as double?,
      descriptionKeyword: fields[6] as String?,
      category: fields[7] as TransactionCategory,
      customTitle: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      lastMatchedAt: fields[10] as DateTime,
      matchCount: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransactionPattern obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.patternType)
      ..writeByte(3)
      ..write(obj.merchantName)
      ..writeByte(4)
      ..write(obj.amountMin)
      ..writeByte(5)
      ..write(obj.amountMax)
      ..writeByte(6)
      ..write(obj.descriptionKeyword)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.customTitle)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.lastMatchedAt)
      ..writeByte(11)
      ..write(obj.matchCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionPatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
