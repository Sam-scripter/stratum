import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app settings/app_settings.dart';
import '../../models/box_manager.dart';
import '../../models/transaction/transaction_model.dart';


// Time period enum for filtering transactions
enum TimePeriod {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  thisYear,
  lastYear,
  // Dynamic years will be added based on transaction data
}

extension TimePeriodExtension on TimePeriod {
  String get displayName {
    switch (this) {
      case TimePeriod.today:
        return 'Today';
      case TimePeriod.thisWeek:
        return 'This Week';
      case TimePeriod.thisMonth:
        return 'This Month';
      case TimePeriod.lastMonth:
        return 'Last Month';
      case TimePeriod.thisYear:
        return 'This Year';
      case TimePeriod.lastYear:
        return 'Last Year';
    }
  }
}

// Helper class for dynamic year periods
class YearPeriod {
  final int year;
  YearPeriod(this.year);
  
  String get displayName => year.toString();
}

// Data Transfer Object for summary
class FinancialSummary {
  final double totalIncome;
  final double totalExpense;

  FinancialSummary({required this.totalIncome, required this.totalExpense});
}

class FinancialService {
  static final FinancialService _instance = FinancialService._internal();
  final BoxManager _boxManager = BoxManager();

  factory FinancialService() {
    return _instance;
  }

  FinancialService._internal();
  
  // Get user ID from Firebase Auth
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

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
        recipient: 'Employer Inc.', accountId: 'asa',
      ),
      Transaction(
        id: '2',
        title: 'Freelance Project',
        amount: 15000,
        type: TransactionType.income,
        category: TransactionCategory.freelance,
        date: now.subtract(const Duration(days: 3)),
        description: 'Web design project completion',
        recipient: 'Client XYZ', accountId: 'asb',
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
        isRecurring: true, accountId: 'asv',
      ),
      Transaction(
        id: '4',
        title: 'Naivas Supermarket',
        amount: 5200,
        type: TransactionType.expense,
        category: TransactionCategory.groceries,
        date: now.subtract(const Duration(days: 2)),
        description: 'Weekly groceries',
        mpesaCode: 'RJ21D4NFLA', accountId: 'asy',
      ),
      Transaction(
        id: '5',
        title: 'Uber Trip',
        amount: 850,
        type: TransactionType.expense,
        category: TransactionCategory.transport,
        date: now.subtract(const Duration(days: 1)),
        description: 'Trip to office',
        mpesaCode: 'RJ21D4NFLB', accountId: 'asr',
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
        isRecurring: true, accountId: 'ass',
      ),
      Transaction(
        id: '7',
        title: 'Restaurant - The Boma',
        amount: 2500,
        type: TransactionType.expense,
        category: TransactionCategory.dining,
        date: now,
        description: 'Dinner with friends',
        mpesaCode: 'RJ21D4NFLD', accountId: 'asu',
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
        isRecurring: true, accountId: 'ads',
      ),
      Transaction(
        id: '9',
        title: 'Safaricom Airtime',
        amount: 1000,
        type: TransactionType.expense,
        category: TransactionCategory.utilities,
        date: now.subtract(const Duration(hours: 2)),
        description: 'Mobile airtime',
        mpesaCode: 'RJ21D4NFLF', accountId: 'awe',
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
        isRecurring: true, accountId: 'asc',
      ),
      Transaction(
        id: '11',
        title: 'Britam Money Market Fund',
        amount: 10000,
        type: TransactionType.expense,
        category: TransactionCategory.investment,
        date: now.subtract(const Duration(days: 7)),
        description: 'Investment deposit',
        mpesaCode: 'RJ21D4NFLH', accountId: 'asd',
      ),
      Transaction(
        id: '12',
        title: 'Shoprite - Shopping',
        amount: 3800,
        type: TransactionType.expense,
        category: TransactionCategory.shopping,
        date: now.subtract(const Duration(days: 8)),
        description: 'Clothing and accessories',
        mpesaCode: 'RJ21D4NFLI', accountId: 'ase',
      ),
    ];
  }

  // 1. Get Real Summary with time period support
  FinancialSummary getFinancialSummary({TimePeriod period = TimePeriod.thisMonth}) {
    // Use real Hive data from BoxManager (scoped by user ID)
    Iterable<Transaction> dataSource;

    if (_userId != null) {
      try {
        final scopedBoxName = '${BoxManager.transactionsBoxName}_$_userId';
        if (Hive.isBoxOpen(scopedBoxName)) {
          dataSource = Hive.box<Transaction>(scopedBoxName).values;
        } else {
          // Box not open, return empty summary (no mock data)
          return FinancialSummary(totalIncome: 0, totalExpense: 0);
        }
      } catch (e) {
        print('Error accessing transactions box: $e');
        // Return empty summary if box access fails
        return FinancialSummary(totalIncome: 0, totalExpense: 0);
      }
    } else {
      // No user logged in, return empty summary
      return FinancialSummary(totalIncome: 0, totalExpense: 0);
    }

    // Use device's local timezone for all date comparisons
    final now = DateTime.now(); // Already in local timezone
    final today = DateTime(now.year, now.month, now.day);
    
    Iterable<Transaction> filteredTransactions;

    switch (period) {
      case TimePeriod.today:
        filteredTransactions = dataSource.where((t) {
          // Convert transaction date to local timezone for comparison
          final tDateLocal = t.date.toLocal();
          final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
          final todayOnly = DateTime(today.year, today.month, today.day);
          return tDateOnly == todayOnly;
        });
        break;
      case TimePeriod.thisWeek:
        // Week starts on Sunday (weekday 7 in Dart: Monday=1, Sunday=7)
        // Calculate days from Sunday: if today is Sunday (7), daysFromSunday = 0
        // If today is Monday (1), daysFromSunday = 1, etc.
        final daysFromSunday = now.weekday == 7 ? 0 : now.weekday;
        final weekStartSunday = today.subtract(Duration(days: daysFromSunday));
        final weekEnd = today.add(const Duration(days: 1)); // End of today
        
        filteredTransactions = dataSource.where((t) {
          final tDateLocal = t.date.toLocal();
          final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
          // Include transactions from week start (Sunday) up to and including today
          return tDateOnly == weekStartSunday || 
                 (tDateOnly.isAfter(weekStartSunday.subtract(const Duration(days: 1))) && tDateOnly.isBefore(weekEnd));
        });
        break;
      case TimePeriod.thisMonth:
        // This Month: From 1st of current month to end of today
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = today.add(const Duration(days: 1)); // End of today
        
        filteredTransactions = dataSource.where((t) {
          final tDateLocal = t.date.toLocal();
          final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
          // Include all transactions from month start to today
          return tDateOnly.year == now.year && 
                 tDateOnly.month == now.month &&
                 (tDateOnly == monthStart || 
                  (tDateOnly.isAfter(monthStart.subtract(const Duration(days: 1))) && tDateOnly.isBefore(monthEnd)));
        });
        break;
      case TimePeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0); // Last day of last month
        
        filteredTransactions = dataSource.where((t) {
          final tDateLocal = t.date.toLocal();
          final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
          return tDateOnly.year == lastMonth.year && 
                 tDateOnly.month == lastMonth.month;
        });
        break;
      case TimePeriod.thisYear:
        // This Year: From Jan 1st of current year to today
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = today.add(const Duration(days: 1)); // End of today
        
        filteredTransactions = dataSource.where((t) {
          final tDateLocal = t.date.toLocal();
          final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
          return tDateOnly.year == now.year &&
                 (tDateOnly == yearStart || 
                  (tDateOnly.isAfter(yearStart.subtract(const Duration(days: 1))) && tDateOnly.isBefore(yearEnd)));
        });
        break;
      case TimePeriod.lastYear:
        // Last Year: All transactions from the previous year
        final lastYear = now.year - 1;
        filteredTransactions = dataSource.where((t) {
          final tDateLocal = t.date.toLocal();
          final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
          return tDateOnly.year == lastYear;
        });
        break;
    }

    double income = 0;
    double expense = 0;

    // Only log in debug mode to reduce console noise
    // print('Filtering transactions for period: ${period.displayName}');
    // print('Total transactions in dataSource: ${dataSource.length}');
    // print('Filtered transactions count: ${filteredTransactions.length}');
    
    for (var t in filteredTransactions) {
      // print('Transaction: ${t.title} - ${t.amount} - Date: ${t.date.toLocal()} - Type: ${t.type}');
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    
    // print('Final summary - Income: $income, Expense: $expense');

    return FinancialSummary(
      totalIncome: income,
      totalExpense: expense,
    );
  }
  
  // Get app install date (when user started using the app)
  DateTime? _getAppInstallDate() {
    if (_userId == null) return null;
    try {
      final settingsBoxName = '${BoxManager.settingsBoxName}_$_userId';
      if (Hive.isBoxOpen(settingsBoxName)) {
        final settingsBox = Hive.box<AppSettings>(settingsBoxName);
        final settings = settingsBox.get(_userId);
        return settings?.appInstallDate;
      }
    } catch (e) {
      print('Error getting app install date: $e');
    }
    return null;
  }

  // Get app settings
  AppSettings? _getAppSettings() {
    if (_userId == null) return null;
    try {
      final settingsBoxName = '${BoxManager.settingsBoxName}_$_userId';
      if (Hive.isBoxOpen(settingsBoxName)) {
        final settingsBox = Hive.box<AppSettings>(settingsBoxName);
        return settingsBox.get(_userId);
      }
    } catch (e) {
      print('Error getting app settings: $e');
    }
    return null;
  }

  // Update completed weeks and months based on current date
  // This should be called periodically (e.g., on app start or daily)
  // Made public for access from home screen
  void updateCompletedPeriods() {
    if (_userId == null) return;
    
    final settings = _getAppSettings();
    if (settings == null || settings.appInstallDate == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final installDate = settings.appInstallDate!;
    final installDateOnly = DateTime(installDate.year, installDate.month, installDate.day);
    
    // Check if today is Sunday (weekday 7 in Dart: Monday=1, Sunday=7)
    final isSunday = now.weekday == 7;
    
    // Check if today is the last day of the month
    final isLastDayOfMonth = today.day == DateTime(now.year, now.month + 1, 0).day;
    
    try {
      final settingsBoxName = '${BoxManager.settingsBoxName}_$_userId';
      if (!Hive.isBoxOpen(settingsBoxName)) return;
      
      final settingsBox = Hive.box<AppSettings>(settingsBoxName);
      List<String> updatedWeeks = List.from(settings.completedWeeks);
      List<String> updatedMonths = List.from(settings.completedMonths);
      
      // Track completed weeks (every Sunday marks a completed week)
      if (isSunday) {
        // Calculate week identifier: "YYYY-WW"
        // Week starts on Sunday, so this Sunday is the end of the week
        // Find the Sunday that starts this week (which is today if today is Sunday)
        final weekStartSunday = today; // Today is Sunday, so it's the start of this week
        // Calculate week number from Jan 1st
        final jan1 = DateTime(now.year, 1, 1);
        // Find the Sunday of the week containing Jan 1st
        final jan1Weekday = jan1.weekday;
        final daysToFirstSunday = jan1Weekday == 7 ? 0 : 7 - jan1Weekday;
        final firstSunday = jan1.add(Duration(days: daysToFirstSunday));
        // Calculate week number
        final weekNumber = ((weekStartSunday.difference(firstSunday).inDays) / 7).floor() + 1;
        final weekId = '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
        
        if (!updatedWeeks.contains(weekId)) {
          updatedWeeks.add(weekId);
        }
      }
      
      // Track completed months (last day of month)
      if (isLastDayOfMonth) {
        final monthId = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        if (!updatedMonths.contains(monthId)) {
          updatedMonths.add(monthId);
        }
      }
      
      // Update settings if changed
      if (updatedWeeks.length != settings.completedWeeks.length ||
          updatedMonths.length != settings.completedMonths.length) {
        final updatedSettings = settings.copyWith(
          completedWeeks: updatedWeeks,
          completedMonths: updatedMonths,
        );
        settingsBox.put(_userId, updatedSettings);
      }
    } catch (e) {
      print('Error updating completed periods: $e');
    }
  }

  // Helper: Check if a week has been completed
  bool _hasCompletedWeek() {
    final settings = _getAppSettings();
    if (settings == null || settings.appInstallDate == null) return false;
    
    // Check if we've completed at least one week
    return settings.completedWeeks.isNotEmpty;
  }

  // Helper: Check if a month has been completed
  bool _hasCompletedMonth() {
    final settings = _getAppSettings();
    if (settings == null || settings.appInstallDate == null) return false;
    
    // Check if we've completed at least one month
    return settings.completedMonths.isNotEmpty;
  }

  // Helper: Count completed months
  int _getCompletedMonthsCount() {
    final settings = _getAppSettings();
    if (settings == null) return 0;
    return settings.completedMonths.length;
  }

  // Check if a time period should be enabled based on actual transaction data
  // Data-driven approach: Enable periods if transactions exist in that period
  // Rules:
  // 1. Today: Enabled if there are transactions today
  // 2. This Week: Enabled if there are transactions this week
  // 3. This Month: Enabled if there are transactions this month
  // 4. Last Month: Enabled if there are transactions last month
  // 5. This Year: Enabled if there are transactions this year
  bool hasDataForPeriod(TimePeriod period) {
    if (_userId == null) return false;
    
    try {
      final scopedBoxName = '${BoxManager.transactionsBoxName}_$_userId';
      if (!Hive.isBoxOpen(scopedBoxName)) {
        return false;
      }
      
      final dataSource = Hive.box<Transaction>(scopedBoxName).values;
      if (dataSource.isEmpty) {
        // No transactions at all - only enable Today (user can still see current day)
        return period == TimePeriod.today;
      }
      
      // Use device's local timezone for all date comparisons
      final now = DateTime.now(); // Already in local timezone
      final today = DateTime(now.year, now.month, now.day);
      bool hasData = false;
      
      switch (period) {
        case TimePeriod.today:
          // Check if there are transactions today
          hasData = dataSource.any((t) {
            final tDateLocal = t.date.toLocal();
            final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
            return tDateOnly == today;
          });
          break;
          
        case TimePeriod.thisWeek:
          // Week starts on Sunday (weekday 7 in Dart: Monday=1, Sunday=7)
          final daysFromSunday = now.weekday == 7 ? 0 : now.weekday;
          final weekStartSunday = today.subtract(Duration(days: daysFromSunday));
          final weekEnd = today.add(const Duration(days: 1));
          
          hasData = dataSource.any((t) {
            final tDateLocal = t.date.toLocal();
            final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
            return tDateOnly == weekStartSunday || 
                   (tDateOnly.isAfter(weekStartSunday.subtract(const Duration(days: 1))) && tDateOnly.isBefore(weekEnd));
          });
          break;
          
        case TimePeriod.thisMonth:
          // Check if there are transactions this month
          hasData = dataSource.any((t) {
            final tDateLocal = t.date.toLocal();
            final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
            return tDateOnly.year == now.year && tDateOnly.month == now.month;
          });
          break;
          
        case TimePeriod.lastMonth:
          // Check if there are transactions last month
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          
          hasData = dataSource.any((t) {
            final tDateLocal = t.date.toLocal();
            final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
            return tDateOnly.year == lastMonth.year && tDateOnly.month == lastMonth.month;
          });
          break;
          
        case TimePeriod.thisYear:
          // Check if there are transactions this year
          hasData = dataSource.any((t) {
            final tDateLocal = t.date.toLocal();
            final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
            return tDateOnly.year == now.year;
          });
          break;
          
        case TimePeriod.lastYear:
          // Check if there are transactions from last year
          final lastYear = now.year - 1;
          hasData = dataSource.any((t) {
            final tDateLocal = t.date.toLocal();
            final tDateOnly = DateTime(tDateLocal.year, tDateLocal.month, tDateLocal.day);
            return tDateOnly.year == lastYear;
          });
          break;
      }
      
      return hasData;
    } catch (e) {
      print('Error checking period data: $e');
      return false;
    }
  }
  
  // 2. Get Real Recent Transactions
  List<Transaction> getRecentTransactions({int limit = 5}) {
    Iterable<Transaction> dataSource;
    if (_userId != null) {
      try {
        final scopedBoxName = '${BoxManager.transactionsBoxName}_$_userId';
        if (Hive.isBoxOpen(scopedBoxName)) {
          dataSource = Hive.box<Transaction>(scopedBoxName).values;
        } else {
          return []; // Return empty list if box not open (no mock data)
        }
      } catch (e) {
        return [];
      }
    } else {
      return [];
    }

    final transactions = dataSource.toList();

    // Sort by date descending (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions.take(limit).toList();
  }

  // 3. Get Spending Categories (Fixed Enum vs String error)
  List<MapEntry<String, double>> getTopSpendingCategories({int limit = 5}) {
    Iterable<Transaction> dataSource;
    if (_userId != null) {
      try {
        final scopedBoxName = '${BoxManager.transactionsBoxName}_$_userId';
        if (Hive.isBoxOpen(scopedBoxName)) {
          dataSource = Hive.box<Transaction>(scopedBoxName).values;
        } else {
          return []; // Return empty list if box not open (no mock data)
        }
      } catch (e) {
        return [];
      }
    } else {
      return [];
    }

    final now = DateTime.now();

    // Filter: Expenses only, This Month only
    final expenses = dataSource.where((t) =>
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

  // Get transactions for current month (uses mock data)
  List<Transaction> getMonthTransactions() {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
    t.date.year == now.year &&
        t.date.month == now.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get transactions by category (uses mock data)
  List<Transaction> getTransactionsByCategory(TransactionCategory category) {
    return _transactions
        .where((t) => t.category == category)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Add new transaction (adds to mock data - typically this would add to Hive)
  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
  }
  
  // Get all years that have transactions (for dynamic year selection)
  // Returns years in descending order (newest first)
  // Only returns years that are 2+ years ago (current year and last year are handled by TimePeriod enum)
  List<int> getAvailableYears() {
    if (_userId == null) return [];
    
    try {
      final scopedBoxName = '${BoxManager.transactionsBoxName}_$_userId';
      if (!Hive.isBoxOpen(scopedBoxName)) {
        return [];
      }
      
      final dataSource = Hive.box<Transaction>(scopedBoxName).values;
      final now = DateTime.now();
      final currentYear = now.year;
      final lastYear = currentYear - 1;
      
      // Get unique years from transactions (convert to local timezone)
      final years = dataSource.map((t) {
        final tDateLocal = t.date.toLocal();
        return tDateLocal.year;
      }).toSet().toList();
      
      // Sort descending (newest first)
      years.sort((a, b) => b.compareTo(a));
      
      // Filter out current year and last year (already handled by TimePeriod enum)
      // Only return years that are 2+ years ago
      final olderYears = years.where((year) => year < lastYear).toList();
      
      return olderYears;
    } catch (e) {
      print('Error getting available years: $e');
      return [];
    }
  }
  
  // Get financial summary for a specific year
  FinancialSummary getFinancialSummaryForYear(int year) {
    if (_userId == null) {
      return FinancialSummary(totalIncome: 0, totalExpense: 0);
    }
    
    try {
      final scopedBoxName = '${BoxManager.transactionsBoxName}_$_userId';
      if (!Hive.isBoxOpen(scopedBoxName)) {
        return FinancialSummary(totalIncome: 0, totalExpense: 0);
      }
      
      final dataSource = Hive.box<Transaction>(scopedBoxName).values;
      
      final filteredTransactions = dataSource.where((t) {
        final tDateLocal = t.date.toLocal();
        return tDateLocal.year == year;
      });
      
      double income = 0;
      double expense = 0;
      
      for (var t in filteredTransactions) {
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
    } catch (e) {
      print('Error getting financial summary for year: $e');
      return FinancialSummary(totalIncome: 0, totalExpense: 0);
    }
  }
}