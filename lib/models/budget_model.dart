import 'transaction_model.dart';

class BudgetDetail {
  final String id;
  final String name;
  final double budgetAmount;
  final double spentAmount;
  final TransactionCategory category;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;

  BudgetDetail({
    required this.id,
    required this.name,
    required this.budgetAmount,
    required this.spentAmount,
    required this.category,
    required this.startDate,
    required this.endDate,
    this.notes,
  });

  double get percentage => spentAmount / budgetAmount;
  double get remaining => budgetAmount - spentAmount;
  bool get isOverBudget => spentAmount > budgetAmount;
}

