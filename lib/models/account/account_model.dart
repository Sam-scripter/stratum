import 'package:hive/hive.dart';

part 'account_model.g.dart';

@HiveType(typeId: 6) // Ensure ID is unique
enum AccountType {
  @HiveField(0)
  Mpesa,
  @HiveField(1)
  Bank,
  @HiveField(2)
  Cash,
  @HiveField(3)
  MobileSavings, // M-Shwari, KCB M-Pesa
  @HiveField(4)
  Liability, // Fuliza, Loans
}

@HiveType(typeId: 7)
class Account extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name; // e.g., "M-Pesa", "KCB", "Wallet"

  @HiveField(2)
  late double currentBalance;

  @HiveField(3)
  late AccountType type;

  @HiveField(4)
  late bool isAutomated; // True if updated via SMS

  @HiveField(5)
  DateTime lastUpdated;

  Account({
    required this.id,
    required this.name,
    required this.currentBalance,
    required this.type,
    this.isAutomated = false,
    required this.lastUpdated,
  });
}