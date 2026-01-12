import 'package:hive/hive.dart';

part 'message_pattern.g.dart';

@HiveType(typeId: 9) // Ensure ID is unique
class MessagePattern extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String pattern; // The SMS pattern/template

  @HiveField(2)
  late String category; // Learned category

  @HiveField(3)
  late String accountType; // MPESA, KCB, etc.

  @HiveField(4)
  late int matchCount; // How many times this pattern matched

  @HiveField(5)
  late DateTime lastSeen;

  MessagePattern({
    required this.id,
    required this.pattern,
    required this.category,
    required this.accountType,
    this.matchCount = 1,
    required this.lastSeen,
  });

  MessagePattern copyWith({
    String? id,
    String? pattern,
    String? category,
    String? accountType,
    int? matchCount,
    DateTime? lastSeen,
  }) {
    return MessagePattern(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      category: category ?? this.category,
      accountType: accountType ?? this.accountType,
      matchCount: matchCount ?? this.matchCount,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

