part of 'merchant_map.dart';

class MerchantMapAdapter extends TypeAdapter<MerchantMap> {
  @HiveType(typeId: 20)

  @override
  final int typeId = 20;

  @override
  MerchantMap read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MerchantMap(
      rawName: fields[0] as String,
      cleanName: fields[1] as String,
      category: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MerchantMap obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.rawName)
      ..writeByte(1)
      ..write(obj.cleanName)
      ..writeByte(2)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MerchantMapAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
