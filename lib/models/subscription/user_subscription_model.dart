import 'package:hive/hive.dart';

enum SubscriptionTier {
  core,  // Free
  plus,  // Tier 1
  elite, // Tier 2
}

@HiveType(typeId: 31)
class UserSubscription extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final int tierIndex; // 0=Core, 1=Plus, 2=Elite

  @HiveField(2)
  final DateTime? expiryDate; // Null = Lifetime or Free

  @HiveField(3)
  final bool isActive; 

  UserSubscription({
    required this.userId,
    this.tierIndex = 0,
    this.expiryDate,
    this.isActive = true,
  });

  SubscriptionTier get tier => SubscriptionTier.values[tierIndex];
  
  bool get isPlusOrHigher => tierIndex >= 1 && isActive;
  bool get isElite => tierIndex >= 2 && isActive;
}

// Manual Adapter
class UserSubscriptionAdapter extends TypeAdapter<UserSubscription> {
  @override
  final int typeId = 31;

  @override
  UserSubscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSubscription(
      userId: fields[0] as String,
      tierIndex: fields[1] as int,
      expiryDate: fields[2] as DateTime?,
      isActive: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserSubscription obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.tierIndex)
      ..writeByte(2)
      ..write(obj.expiryDate)
      ..writeByte(3)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
