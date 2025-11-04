import 'package:intl/intl.dart';

enum TransactionType { income, expense }
enum TransactionCategory {
  salary,
  freelance,
  mpesa,
  groceries,
  transport,
  utilities,
  entertainment,
  dining,
  shopping,
  health,
  education,
  investment,
  other
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? description;
  final String? mpesaCode;
  final String? recipient;
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

  String get categoryName {
    switch (category) {
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.freelance:
        return 'Freelance';
      case TransactionCategory.mpesa:
        return 'M-Pesa';
      case TransactionCategory.groceries:
        return 'Groceries';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.dining:
        return 'Dining';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.health:
        return 'Health';
      case TransactionCategory.education:
        return 'Education';
      case TransactionCategory.investment:
        return 'Investment';
      case TransactionCategory.other:
        return 'Other';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case TransactionCategory.salary:
        return '💼';
      case TransactionCategory.freelance:
        return '💻';
      case TransactionCategory.mpesa:
        return '📱';
      case TransactionCategory.groceries:
        return '🛒';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.utilities:
        return '⚡';
      case TransactionCategory.entertainment:
        return '🎬';
      case TransactionCategory.dining:
        return '🍽️';
      case TransactionCategory.shopping:
        return '🛍️';
      case TransactionCategory.health:
        return '🏥';
      case TransactionCategory.education:
        return '📚';
      case TransactionCategory.investment:
        return '📈';
      case TransactionCategory.other:
        return '📌';
    }
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String get formattedTime {
    return DateFormat('hh:mm a').format(date);
  }

  String get formattedAmount {
    return 'KES ${amount.toStringAsFixed(2)}';
  }
}

class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final double netWorth;
  final double savingsRate;
  final Map<TransactionCategory, double> categoryExpenses;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netWorth,
    required this.savingsRate,
    required this.categoryExpenses,
  });

  double get balance => totalIncome - totalExpense;

  String get formattedBalance {
    return 'KES ${balance.toStringAsFixed(2)}';
  }

  String get formattedNetWorth {
    return 'KES ${netWorth.toStringAsFixed(2)}';
  }

  String get formattedSavingsRate {
    return '${(savingsRate * 100).toStringAsFixed(1)}%';
  }
}
