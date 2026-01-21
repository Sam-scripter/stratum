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
  late double balance; // Changed from currentBalance to match parser logic

  @HiveField(3)
  late AccountType type;

  @HiveField(4)
  late bool isAutomated; // True if updated via SMS

  @HiveField(5)
  late DateTime lastUpdated;

  // NEW FIELD: Used by SMS parser to match incoming messages
  @HiveField(6)
  late String senderAddress;

  Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    this.isAutomated = false,
    required this.lastUpdated,
    required this.senderAddress,
  });

  // copyWith method for cleaner updates in SmsParser
  Account copyWith({
    String? id,
    String? name,
    double? balance,
    AccountType? type,
    bool? isAutomated,
    DateTime? lastUpdated,
    String? senderAddress,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      isAutomated: isAutomated ?? this.isAutomated,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      senderAddress: senderAddress ?? this.senderAddress,
    );
  }
}