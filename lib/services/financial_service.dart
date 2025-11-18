import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import '../models/transaction/transaction_model.dart';

class FinancialService {
  static final FinancialService _instance = FinancialService._internal();
  final String _boxName = 'transactions';

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

  // 1. Get Real Summary
  FinancialSummary getFinancialSummary() {
    // Return zero-state if box isn't open or doesn't exist
    if (!Hive.isBoxOpen(_boxName)) {
      return FinancialSummary(totalIncome: 0, totalExpense: 0);
    }

    final box = Hive.box<Transaction>(_boxName);
    final now = DateTime.now();

    // Filter for current month only
    final thisMonthTransactions = box.values.where((t) =>
    t.date.year == now.year && t.date.month == now.month
    );

    double income = 0;
    double expense = 0;

    for (var t in thisMonthTransactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return FinancialSummary(
      totalIncome: income,
      totalExpense: expense,
    );
  }

  // 2. Get Real Recent Transactions
  List<Transaction> getRecentTransactions({int limit = 5}) {
    if (!Hive.isBoxOpen(_boxName)) return [];

    final box = Hive.box<Transaction>(_boxName);
    final transactions = box.values.toList();

    // Sort by date descending (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions.take(limit).toList();
  }

  // 3. Get Spending Categories (Fixed Enum vs String error)
  List<MapEntry<String, double>> getTopSpendingCategories({int limit = 5}) {
    if (!Hive.isBoxOpen(_boxName)) return [];

    final box = Hive.box<Transaction>(_boxName);
    final now = DateTime.now();

    // Filter: Expenses only, This Month only
    final expenses = box.values.where((t) =>
    t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month
    );

    // Group by Category (Enum)
    final grouped = groupBy(expenses, (Transaction t) => t.category);

    // Sum up amounts per category
    final List<MapEntry<String, double>> categories = [];

    // FIXED: Iterate over (Enum, List<Transaction>) and convert Enum to String
    grouped.forEach((TransactionCategory categoryEnum, List<Transaction> transactions) {
      double total = transactions.fold(0, (sum, t) => sum + t.amount);

      // Convert Enum to String for the chart (e.g., "Groceries")
      String rawName = categoryEnum.toString().split('.').last;
      String categoryName = rawName[0].toUpperCase() + rawName.substring(1);

      categories.add(MapEntry(categoryName, total));
    });

    // Sort highest spending first
    categories.sort((a, b) => b.value.compareTo(a.value));

    return categories.take(limit).toList();
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

}
