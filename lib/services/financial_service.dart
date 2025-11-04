

import '../models/transaction_model.dart';

class FinancialService {
  static final FinancialService _instance = FinancialService._internal();

  factory FinancialService() {
    return _instance;
  }

  FinancialService._internal();

  // Mock data for demo purposes
  late List<Transaction> _transactions = _generateMockTransactions();

  List<Transaction> get transactions => _transactions;

  // Generate mock transactions (simulating M-Pesa and other transactions)
  static List<Transaction> _generateMockTransactions() {
    final now = DateTime.now();
    return [
      // Income transactions
      Transaction(
        id: '1',
        title: 'Monthly Salary',
        amount: 85000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: now.subtract(const Duration(days: 5)),
        description: 'Salary for November 2025',
        recipient: 'Employer Inc.',
      ),
      Transaction(
        id: '2',
        title: 'Freelance Project',
        amount: 15000,
        type: TransactionType.income,
        category: TransactionCategory.freelance,
        date: now.subtract(const Duration(days: 3)),
        description: 'Web design project completion',
        recipient: 'Client XYZ',
      ),
      // Expense transactions
      Transaction(
        id: '3',
        title: 'Rent Payment',
        amount: 35000,
        type: TransactionType.expense,
        category: TransactionCategory.utilities,
        date: now.subtract(const Duration(days: 4)),
        description: 'Monthly rent',
        mpesaCode: 'RJ21D4NFLF',
        isRecurring: true,
      ),
      Transaction(
        id: '4',
        title: 'Naivas Supermarket',
        amount: 5200,
        type: TransactionType.expense,
        category: TransactionCategory.groceries,
        date: now.subtract(const Duration(days: 2)),
        description: 'Weekly groceries',
        mpesaCode: 'RJ21D4NFLA',
      ),
      Transaction(
        id: '5',
        title: 'Uber Trip',
        amount: 850,
        type: TransactionType.expense,
        category: TransactionCategory.transport,
        date: now.subtract(const Duration(days: 1)),
        description: 'Trip to office',
        mpesaCode: 'RJ21D4NFLB',
      ),
      Transaction(
        id: '6',
        title: 'Netflix Subscription',
        amount: 499,
        type: TransactionType.expense,
        category: TransactionCategory.entertainment,
        date: now.subtract(const Duration(days: 1)),
        description: 'Monthly subscription',
        mpesaCode: 'RJ21D4NFLC',
        isRecurring: true,
      ),
      Transaction(
        id: '7',
        title: 'Restaurant - The Boma',
        amount: 2500,
        type: TransactionType.expense,
        category: TransactionCategory.dining,
        date: now,
        description: 'Dinner with friends',
        mpesaCode: 'RJ21D4NFLD',
      ),
      Transaction(
        id: '8',
        title: 'KPLC Electricity',
        amount: 3200,
        type: TransactionType.expense,
        category: TransactionCategory.utilities,
        date: now,
        description: 'Monthly electricity bill',
        mpesaCode: 'RJ21D4NFLE',
        isRecurring: true,
      ),
      Transaction(
        id: '9',
        title: 'Safaricom Airtime',
        amount: 1000,
        type: TransactionType.expense,
        category: TransactionCategory.utilities,
        date: now.subtract(const Duration(hours: 2)),
        description: 'Mobile airtime',
        mpesaCode: 'RJ21D4NFLF',
      ),
      Transaction(
        id: '10',
        title: 'Gym Membership',
        amount: 2000,
        type: TransactionType.expense,
        category: TransactionCategory.health,
        date: now.subtract(const Duration(days: 6)),
        description: 'Monthly gym fee',
        mpesaCode: 'RJ21D4NFLG',
        isRecurring: true,
      ),
      Transaction(
        id: '11',
        title: 'Britam Money Market Fund',
        amount: 10000,
        type: TransactionType.expense,
        category: TransactionCategory.investment,
        date: now.subtract(const Duration(days: 7)),
        description: 'Investment deposit',
        mpesaCode: 'RJ21D4NFLH',
      ),
      Transaction(
        id: '12',
        title: 'Shoprite - Shopping',
        amount: 3800,
        type: TransactionType.expense,
        category: TransactionCategory.shopping,
        date: now.subtract(const Duration(days: 8)),
        description: 'Clothing and accessories',
        mpesaCode: 'RJ21D4NFLI',
      ),
    ];
  }

  // Get financial summary
  FinancialSummary getFinancialSummary() {
    double totalIncome = 0;
    double totalExpense = 0;
    final categoryExpenses = <TransactionCategory, double>{};

    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
        categoryExpenses.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    final balance = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? balance / totalIncome : 0.0;

    // Mock net worth (in real app, this would be calculated from assets/liabilities)
    final netWorth = 250000.0 + balance;

    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netWorth: netWorth,
      savingsRate: savingsRate,
      categoryExpenses: categoryExpenses,
    );
  }

  // Get transactions for current month
  List<Transaction> getMonthTransactions() {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.date.year == now.year &&
            t.date.month == now.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get recent transactions
  List<Transaction> getRecentTransactions({int limit = 10}) {
    return _transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date))
      ..take(limit);
  }

  // Get transactions by category
  List<Transaction> getTransactionsByCategory(TransactionCategory category) {
    return _transactions
        .where((t) => t.category == category)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Add new transaction
  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
  }

  // Get top spending categories
  List<MapEntry<TransactionCategory, double>> getTopSpendingCategories({
    int limit = 5,
  }) {
    final summary = getFinancialSummary();
    final entries = summary.categoryExpenses.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }
}
