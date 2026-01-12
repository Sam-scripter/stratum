import 'package:hive/hive.dart';
import '../transaction/transaction_model.dart';

part 'recurring_transaction_pattern.g.dart';

/// Pattern for automatically categorizing recurring transactions
@HiveType(typeId: 7)
class RecurringTransactionPattern extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String patternType; // 'merchant', 'amount', 'description', 'combined'

  @HiveField(3)
  final String? merchantName; // Merchant/recipient name to match

  @HiveField(4)
  final double? amountMin; // Minimum amount range

  @HiveField(5)
  final double? amountMax; // Maximum amount range

  @HiveField(6)
  final String? descriptionKeyword; // Keyword in transaction description

  @HiveField(7)
  final TransactionCategory category; // Category to assign

  @HiveField(8)
  final String? customTitle; // Custom title override (optional)

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime lastMatchedAt;

  @HiveField(11)
  final int matchCount; // How many times this pattern has matched

  RecurringTransactionPattern({
    required this.id,
    required this.userId,
    required this.patternType,
    this.merchantName,
    this.amountMin,
    this.amountMax,
    this.descriptionKeyword,
    required this.category,
    this.customTitle,
    required this.createdAt,
    required this.lastMatchedAt,
    this.matchCount = 0,
  });

  /// Check if a transaction matches this pattern
  bool matches(Transaction transaction) {
    // Match by merchant name
    if (merchantName != null && 
        !transaction.title.toLowerCase().contains(merchantName!.toLowerCase())) {
      return false;
    }

    // Match by amount range
    if (amountMin != null && transaction.amount < amountMin!) {
      return false;
    }
    if (amountMax != null && transaction.amount > amountMax!) {
      return false;
    }

    // Match by description keyword
    if (descriptionKeyword != null &&
        !transaction.title.toLowerCase().contains(descriptionKeyword!.toLowerCase())) {
      return false;
    }

    return true;
  }

  /// Apply this pattern to a transaction (creates a new transaction with updated fields)
  Transaction applyTo(Transaction transaction) {
    return Transaction(
      id: transaction.id,
      title: customTitle ?? transaction.title,
      amount: transaction.amount,
      type: transaction.type,
      category: category, // Apply the pattern's category
      date: transaction.date,
      description: transaction.description,
      recipient: transaction.recipient,
      mpesaCode: transaction.mpesaCode,
      isRecurring: true, // Mark as recurring
      accountId: transaction.accountId,
    );
  }

  RecurringTransactionPattern copyWith({
    String? id,
    String? userId,
    String? patternType,
    String? merchantName,
    double? amountMin,
    double? amountMax,
    String? descriptionKeyword,
    TransactionCategory? category,
    String? customTitle,
    DateTime? createdAt,
    DateTime? lastMatchedAt,
    int? matchCount,
  }) {
    return RecurringTransactionPattern(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patternType: patternType ?? this.patternType,
      merchantName: merchantName ?? this.merchantName,
      amountMin: amountMin ?? this.amountMin,
      amountMax: amountMax ?? this.amountMax,
      descriptionKeyword: descriptionKeyword ?? this.descriptionKeyword,
      category: category ?? this.category,
      customTitle: customTitle ?? this.customTitle,
      createdAt: createdAt ?? this.createdAt,
      lastMatchedAt: lastMatchedAt ?? this.lastMatchedAt,
      matchCount: matchCount ?? this.matchCount,
    );
  }
}

