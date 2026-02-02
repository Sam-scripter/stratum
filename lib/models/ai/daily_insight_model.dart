import 'package:hive/hive.dart';

// part 'daily_insight_model.g.dart'; // Removing generation part

@HiveType(typeId: 30)
class DailyInsight extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String type;

  DailyInsight({
    required this.text,
    required this.date,
    this.type = 'neutral',
  });
  
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class DailyInsightAdapter extends TypeAdapter<DailyInsight> {
  @override
  final int typeId = 30;

  @override
  DailyInsight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyInsight(
      text: fields[0] as String,
      date: fields[1] as DateTime,
      type: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DailyInsight obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyInsightAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
