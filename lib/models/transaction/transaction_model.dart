import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'transaction_model.g.dart';

// Assign unique TypeIds. Account used 6, 7, 8. Let's use 9, 10, 11.

@HiveType(typeId: 9)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense
}

@HiveType(typeId: 10)
enum TransactionCategory {
  @HiveField(0)
  salary,
  @HiveField(1)
  freelance,
  @HiveField(2)
  mpesa,
  @HiveField(3)
  groceries,
  @HiveField(4)
  transport,
  @HiveField(5)
  utilities,
  @HiveField(6)
  entertainment,
  @HiveField(7)
  dining,
  @HiveField(8)
  shopping,
  @HiveField(9)
  health,
  @HiveField(10)
  education,
  @HiveField(11)
  investment,
  @HiveField(12)
  other
}

@HiveType(typeId: 11)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final TransactionType type;

  @HiveField(4)
  final TransactionCategory category;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final String? description;

  @HiveField(7)
  final String? mpesaCode;

  @HiveField(8)
  final String? recipient;

  @HiveField(9)
  final bool isRecurring;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
    this.mpesaCode,
    this.recipient,
    this.isRecurring = false,
  });

  // Helper Getters
  String get categoryName {
    // Capitalize first letter
    String name = category.toString().split('.').last;
    return name[0].toUpperCase() + name.substring(1);
  }

  String get categoryEmoji {
    switch (category) {
      case TransactionCategory.salary: return '💼';
      case TransactionCategory.freelance: return '💻';
      case TransactionCategory.mpesa: return '📱';
      case TransactionCategory.groceries: return '🛒';
      case TransactionCategory.transport: return '🚗';
      case TransactionCategory.utilities: return '⚡';
      case TransactionCategory.entertainment: return '🎬';
      case TransactionCategory.dining: return '🍽️';
      case TransactionCategory.shopping: return '🛍️';
      case TransactionCategory.health: return '🏥';
      case TransactionCategory.education: return '📚';
      case TransactionCategory.investment: return '📈';
      case TransactionCategory.other: return '📌';
    }
  }
}

// Simplified Summary Class
// We removed 'netWorth' because that is now calculated in HomeScreen via Accounts
class FinancialSummary {
  final double totalIncome;
  final double totalExpense;

  // These are calculated getters now
  double get balance => totalIncome - totalExpense;
  double get savingsRate => totalIncome == 0 ? 0 : (balance / totalIncome);

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
  });
}