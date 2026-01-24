import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 2) // Ensure ID is unique
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer,
}

@HiveType(typeId: 3) // Ensure ID is unique
enum TransactionCategory {
  @HiveField(0)
  salary,
  @HiveField(1)
  freelance,
  @HiveField(2)
  utilities,
  @HiveField(3)
  groceries,
  @HiveField(4)
  transport,
  @HiveField(5)
  entertainment,
  @HiveField(6)
  dining,
  @HiveField(7)
  health,
  @HiveField(8)
  investment,
  @HiveField(9)
  shopping,
  @HiveField(10)
  transfer,
  @HiveField(11)
  other,
  @HiveField(12)
  manual,
  @HiveField(13)
  general,
  @HiveField(14)
  gifts,
  @HiveField(15)
  familySupport,
}

@HiveType(typeId: 1) // Ensure ID is unique
class Transaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late TransactionType type;

  @HiveField(4)
  late TransactionCategory category;

  @HiveField(5)
  late DateTime date;

  @HiveField(6)
  late String? description;

  @HiveField(7)
  late String? recipient;

  @HiveField(8)
  late String? mpesaCode;

  @HiveField(9)
  late bool isRecurring;

  @HiveField(10)
  late String accountId;

  @HiveField(11)
  late String? originalSms; // Store original SMS for learning

  @HiveField(12)
  late double? newBalance; // Balance after transaction

  @HiveField(13)
  late String? reference; // Transaction reference code

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
    this.recipient,
    this.mpesaCode,
    this.isRecurring = false,
    required this.accountId,
    this.originalSms,
    this.newBalance,
    this.reference,
  });

  // Helper Getters
  String get categoryName {
    // Capitalize first letter
    String name = category.toString().split('.').last;
    return name[0].toUpperCase() + name.substring(1);
  }

  String get categoryEmoji {
    switch (category) {
      case TransactionCategory.salary:
        return '💼';
      case TransactionCategory.freelance:
        return '💻';
      case TransactionCategory.utilities:
        return '⚡';
      case TransactionCategory.groceries:
        return '🛒';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.entertainment:
        return '🎬';
      case TransactionCategory.dining:
        return '🍽️';
      case TransactionCategory.shopping:
        return '🛍️';
      case TransactionCategory.health:
        return '🏥';
      case TransactionCategory.investment:
        return '📈';
      case TransactionCategory.transfer:
        return '🔁'; // Fixed
      case TransactionCategory.manual:
        return '📝'; // Fixed
      case TransactionCategory.other:
        return '📌';
      case TransactionCategory.general:
        return '📌';
      case TransactionCategory.gifts:
        return '🎁';
      case TransactionCategory.familySupport:
        return '👨‍👩‍👧‍👦';
    }
  }

  // CopyWith method for creating modified copies
  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    String? description,
    String? recipient,
    String? mpesaCode,
    bool? isRecurring,
    String? accountId,
    String? originalSms,
    double? newBalance,
    String? reference,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      recipient: recipient ?? this.recipient,
      mpesaCode: mpesaCode ?? this.mpesaCode,
      isRecurring: isRecurring ?? this.isRecurring,
      accountId: accountId ?? this.accountId,
      originalSms: originalSms ?? this.originalSms,
      newBalance: newBalance ?? this.newBalance,
      reference: reference ?? this.reference,
    );
  }
}
