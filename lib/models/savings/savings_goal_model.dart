import 'package:hive/hive.dart';

part 'savings_goal_model.g.dart';

@HiveType(typeId: 10) // Changed from 4 to avoid conflict with AppSettings
class SavingsGoal extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double targetAmount;

  @HiveField(3)
  late double savedAmount;

  @HiveField(4)
  late int iconCodePoint; // Store IconData.codePoint

  @HiveField(5)
  late int colorValue; // Store Color.value

  @HiveField(6)
  late DateTime? deadLine;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0.0,
    required this.iconCodePoint,
    required this.colorValue,
    this.deadLine,
  });

  // Calculate progress matching the user's "Overfunding" requirement
  // If savedAmount > targetAmount, progress > 1.0 (100%+)
  double get progress => targetAmount > 0 ? savedAmount / targetAmount : 0.0;

  bool get isCompleted => savedAmount >= targetAmount;

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    int? iconCodePoint,
    int? colorValue,
    DateTime? deadLine,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      deadLine: deadLine ?? this.deadLine,
    );
  }
}
