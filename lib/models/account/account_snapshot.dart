import 'package:hive/hive.dart';

part 'account_snapshot.g.dart';

@HiveType(typeId: 8) // Ensure ID is unique
class AccountSnapshot extends HiveObject {
  @HiveField(0)
  late String id; // UUID

  @HiveField(1)
  late String accountId; // Links to the parent Account

  @HiveField(2)
  late double balance;

  @HiveField(3)
  late DateTime timestamp;

  AccountSnapshot({
    required this.id,
    required this.accountId,
    required this.balance,
    required this.timestamp,
  });
}