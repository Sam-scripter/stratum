import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stratum/models/account/account_model.dart';
import 'package:stratum/models/box_manager.dart';
import 'package:stratum/models/transaction/transaction_model.dart';
import 'package:stratum/services/finances/financial_service.dart';
import 'package:stratum/services/sms_reader/sms_reader_service.dart';

class FinancialRepository with ChangeNotifier {
  final BoxManager _boxManager;
  final FinancialService _financialService;
  final SmsReaderService _smsReaderService;
  final String _userId;

  List<Account> _accounts = [];
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;
  String? _error;

  FinancialRepository({
    required String userId,
    required BoxManager boxManager,
    required FinancialService financialService,
    required SmsReaderService smsReaderService,
  })  : _userId = userId,
        _boxManager = boxManager,
        _financialService = financialService,
        _smsReaderService = smsReaderService {
    _initialize();
  }

  // Getters
  List<Account> get accounts => _accounts;
  List<Transaction> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get userId => _userId;

  StreamSubscription? _accountsSubscription;
  StreamSubscription? _transactionsSubscription;

  Future<void> _initialize() async {
    if (_userId.isEmpty) return; // Guard against unauthenticated initialization
    try {
      await _boxManager.openAllBoxes(_userId);
      _financialService.updateCompletedPeriods();
      _setupBoxListeners();
      await _refreshDataInternal();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupBoxListeners() {
    _accountsSubscription = _boxManager
        .getBox<Account>(BoxManager.accountsBoxName, _userId)
        .watch()
        .listen((_) => _refreshDataInternal());

    _transactionsSubscription = _boxManager
        .getBox<Transaction>(BoxManager.transactionsBoxName, _userId)
        .watch()
        .listen((_) => _refreshDataInternal());
  }

  Future<void> _refreshDataInternal() async {
    final accountsBox = _boxManager.getBox<Account>(
      BoxManager.accountsBoxName,
      _userId,
    );
    final transactionsBox = _boxManager.getBox<Transaction>(
      BoxManager.transactionsBoxName,
      _userId,
    );

    final allAccounts = accountsBox.values.toList();
    final allTransactions = transactionsBox.values.toList();

    // 1. Deduplicate Accounts Logic (moved from HomeScreen)
    _accounts = _deduplicateAccounts(allAccounts, allTransactions);

    // 2. Get Recent Transactions
    // We can use financialService for this, or do it here. 
    // Ensuring consistency by doing it here manually effectively.
    allTransactions.sort((a, b) => b.date.compareTo(a.date));
    _recentTransactions = allTransactions.take(8).toList();

    notifyListeners();
  }

  // Exposed method for Pull-to-Refresh
  Future<void> refresh() async {
    // 1. Scan for new SMS (Optimized)
    if (await _smsReaderService.hasPermission()) {
      await _smsReaderService.scanRecentMessages(count: 20);
    }
    // 2. Trigger UI update (Box listeners will handle the rest, but we can force it)
    await _refreshDataInternal();
  }

  // Deduplication Logic
  List<Account> _deduplicateAccounts(
      List<Account> allAccounts, List<Transaction> allTransactions) {
    final Map<String, Account> uniqueAccounts = {};

    for (var account in allAccounts) {
      final key = _getAccountKey(account);
      if (!uniqueAccounts.containsKey(key)) {
        uniqueAccounts[key] = account;
      } else {
        final existing = uniqueAccounts[key]!;
        
        final existingTxCount = allTransactions
            .where((t) => t.accountId == existing.id)
            .length;
        final currentTxCount = allTransactions
            .where((t) => t.accountId == account.id)
            .length;

        bool shouldReplace = false;
        if (currentTxCount > existingTxCount) {
          shouldReplace = true;
        } else if (currentTxCount == existingTxCount) {
          if (account.balance > existing.balance) {
            shouldReplace = true;
          } else if (account.balance == existing.balance) {
            shouldReplace = account.id.compareTo(existing.id) < 0;
          }
        }

        if (shouldReplace) {
          uniqueAccounts[key] = account;
        }
      }
    }

    return uniqueAccounts.values.where((account) {
      final hasTransactions = allTransactions.any(
        (t) => t.accountId == account.id,
      );
      if (account.balance == 0 && !hasTransactions) {
        return false;
      }
      return true;
    }).toList();
  }

  String _getAccountKey(Account account) {
    final normalizedName = account.name.toUpperCase().trim();
    if (normalizedName == 'MPESA' ||
        normalizedName == 'M-PESA' ||
        normalizedName.contains('MPESA') ||
        normalizedName.contains('M-PESA')) {
      return 'MPESA';
    }
    return normalizedName;
  }

  // Pass-through for Financial Summary
  FinancialSummary getSummary(TimePeriod period) {
    return _financialService.getFinancialSummary(period: period);
  }

  @override
  void dispose() {
    _accountsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
