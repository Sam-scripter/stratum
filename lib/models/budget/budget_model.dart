import 'package:hive/hive.dart';
import '../transaction/transaction_model.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 5)
class Budget extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String categoryName;

  @HiveField(2)
  late double limitAmount;

  @HiveField(3)
  late double spentAmount;

  @HiveField(4)
  late int month;

  @HiveField(5)
  late int year;

  @HiveField(6)
  late int colorValue;

  Budget({
    required this.id,
    required this.categoryName,
    required this.limitAmount,
    this.spentAmount = 0.0,
    required this.month,
    required this.year,
    required this.colorValue,
  });

  double get progress => limitAmount > 0 ? spentAmount / limitAmount : 0.0;
  
  double get remaining => limitAmount - spentAmount;

  bool get isExceeded => spentAmount > limitAmount;

  Budget copyWith({
    String? id,
    String? categoryName,
    double? limitAmount,
    double? spentAmount,
    int? month,
    int? year,
    int? colorValue,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      month: month ?? this.month,
      year: year ?? this.year,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

/// Helper model for UI display
class BudgetDetail {
  final String id;
  final String name;
  final TransactionCategory category;
  final double budgetAmount;
  final double spentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;

  BudgetDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.startDate,
    required this.endDate,
    this.notes,
  });

  double get remaining => budgetAmount - spentAmount;
  double get percentage => budgetAmount > 0 ? spentAmount / budgetAmount : 0.0;
  bool get isOverBudget => spentAmount > budgetAmount;

  Budget toBudget() {
    return Budget(
      id: id,
      categoryName: name,
      limitAmount: budgetAmount,
      spentAmount: spentAmount,
      month: startDate.month,
      year: startDate.year,
      colorValue: 0xFFD4AF37, // Default to Gold if lost
    );
  }
}
