import 'package:hive_flutter/hive_flutter.dart';
import '../../models/box_manager.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/budget/budget_model.dart';
import '../../models/savings/savings_goal_model.dart';
import '../../models/account/account_model.dart';

class BudgetService {
  final String userId;
  late final BoxManager _boxManager;

  BudgetService(this.userId) {
    _boxManager = BoxManager();
  }

  // --- SAVINGS GOALS ---

  Future<void> createSavingsGoal(String name, double targetAmount, int colorValue, int iconCodePoint) async {
    await _boxManager.openAllBoxes(userId);
    final box = _boxManager.getBox<SavingsGoal>(BoxManager.savingsGoalsBoxName, userId);
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final goal = SavingsGoal(
      id: id,
      name: name,
      targetAmount: targetAmount,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
    );

    await box.put(id, goal);
  }

  Future<void> addFundsToGoal(String goalId, double amount) async {
    await _boxManager.openAllBoxes(userId);
    final box = _boxManager.getBox<SavingsGoal>(BoxManager.savingsGoalsBoxName, userId);
    
    final goal = box.get(goalId);
    if (goal != null) {
      final updated = goal.copyWith(savedAmount: goal.savedAmount + amount);
      await box.put(goalId, updated);
    }
  }

  Future<void> withdrawFundsFromGoal(String goalId, double amount) async {
     await addFundsToGoal(goalId, -amount);
  }

  // --- BUDGETS ---

  Future<void> createOrUpdateBudget(String categoryName, double limit, {int? month, int? year}) async {
    await _boxManager.openAllBoxes(userId);
    final budgetBox = _boxManager.getBox<Budget>(BoxManager.budgetsBoxName, userId);

    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    // Check if budget exists for this category/month/year
    final existingKey = budgetBox.values.firstWhere(
      (b) => b.categoryName == categoryName && b.month == targetMonth && b.year == targetYear,
      orElse: () => Budget(
        id: '', 
        categoryName: '', 
        limitAmount: 0, 
        month: 0, 
        year: 0, 
        colorValue: 0
      ), // Dummy return
    );

    if (existingKey.id.isNotEmpty) {
      // Update existing
      final updated = existingKey.copyWith(limitAmount: limit);
      await budgetBox.put(existingKey.id, updated);
    } else {
      // Create new
      final id = '${targetYear}_${targetMonth}_${categoryName.replaceAll(" ", "")}';
      final newBudget = Budget(
        id: id,
        categoryName: categoryName,
        limitAmount: limit,
        month: targetMonth,
        year: targetYear,
        colorValue: 0xFF4CAF50, // Default green, UI can update this
      );
      // Determine color based on Category? For now default.
      
      await budgetBox.put(id, newBudget);
      
      // Initial scan to populate spentAmount
      await _recalculateBudgetSpent(newBudget);
    }
  }

  Future<void> _recalculateBudgetSpent(Budget budget) async {
    final transactionsBox = _boxManager.getBox<Transaction>(BoxManager.transactionsBoxName, userId);
    final budgetBox = _boxManager.getBox<Budget>(BoxManager.budgetsBoxName, userId);

    final spent = transactionsBox.values
        .where((t) => 
            t.type == TransactionType.expense && 
            t.categoryName == budget.categoryName &&
            t.date.month == budget.month && 
            t.date.year == budget.year
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final updated = budget.copyWith(spentAmount: spent);
    await budgetBox.put(updated.id, updated);
  }

  // Called whenever a new transaction is added/modified
  Future<void> onTransactionUpdated(Transaction transaction) async {
    if (transaction.type != TransactionType.expense) return;

    await _boxManager.openAllBoxes(userId);
    final budgetBox = _boxManager.getBox<Budget>(BoxManager.budgetsBoxName, userId);
    
    try {
      final budget = budgetBox.values.firstWhere(
        (b) => 
          b.categoryName == transaction.categoryName && 
          b.month == transaction.date.month && 
          b.year == transaction.date.year
      );
      
      // Recalculate is safer than incrementing to handle edits/deletes
      await _recalculateBudgetSpent(budget);
      
    } catch (_) {
      // No budget for this category, ignore
    }
  }

  // --- CALCULATIONS ---

  Future<double> getTotalNetWorth() async {
    await _boxManager.openAllBoxes(userId);
    final accountsBox = _boxManager.getBox<Account>(BoxManager.accountsBoxName, userId);
    return accountsBox.values.fold<double>(0.0, (double sum, acc) => sum + acc.balance);
  }

  Future<double> getTotalAllocated() async {
    await _boxManager.openAllBoxes(userId);
    final goalsBox = _boxManager.getBox<SavingsGoal>(BoxManager.savingsGoalsBoxName, userId);
    return goalsBox.values.fold<double>(0.0, (double sum, goal) => sum + goal.savedAmount);
  }

  Future<double> getFreeCash() async {
    final netWorth = await getTotalNetWorth();
    final allocated = await getTotalAllocated();
    return netWorth - allocated;
  }

  // Synchronous getters (for when boxes are already open)
  double get totalNetWorth {
    final accountsBox = _boxManager.getBox<Account>(BoxManager.accountsBoxName, userId);
    return accountsBox.values.fold(0.0, (sum, acc) => sum + acc.balance);
  }

  double get totalAllocated {
    final goalsBox = _boxManager.getBox<SavingsGoal>(BoxManager.savingsGoalsBoxName, userId);
    return goalsBox.values.fold(0.0, (sum, goal) => sum + goal.savedAmount);
  }

  double get freeCash => totalNetWorth - totalAllocated;

  // --- DATA RETRIEVAL ---

  Future<List<Budget>> getAllBudgets() async {
    await _boxManager.openAllBoxes(userId);
    final box = _boxManager.getBox<Budget>(BoxManager.budgetsBoxName, userId);
    return box.values.toList();
  }

  Future<List<SavingsGoal>> getAllSavingsGoals() async {
    await _boxManager.openAllBoxes(userId);
    final box = _boxManager.getBox<SavingsGoal>(BoxManager.savingsGoalsBoxName, userId);
    return box.values.toList();
  }
}
