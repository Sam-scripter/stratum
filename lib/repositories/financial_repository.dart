import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stratum/models/account/account_model.dart';
import 'package:stratum/models/box_manager.dart';
import 'package:stratum/models/transaction/transaction_model.dart';
import 'package:stratum/services/finances/financial_service.dart';
import 'package:stratum/services/finances/investment_service.dart'; // NEW
import 'package:stratum/services/sms_reader/sms_reader_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stratum/models/investment/investment_model.dart'; // NEW

class FinancialRepository with ChangeNotifier {
  final BoxManager _boxManager;
  final FinancialService _financialService;
  late final InvestmentService _investmentService; // NEW
  final SmsReaderService _smsReaderService;
  final String _userId;

  List<Account> _accounts = [];
  List<Transaction> _recentTransactions = [];
  List<Transaction> _allTransactions = [];
  List<InvestmentModel> _investments = []; // NEW
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
    _investmentService = InvestmentService(userId); // Init
    _initialize();
  }

  // Getters
  List<Account> get accounts => _accounts;
  List<Transaction> get recentTransactions => _recentTransactions;
  List<Transaction> get allTransactions => _allTransactions;
  List<InvestmentModel> get investments => _investments; // NEW
  InvestmentService get investmentService => _investmentService; // Expose service
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get userId => _userId;

  StreamSubscription? _accountsSubscription;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _investmentsSubscription; // NEW

  Future<void> _initialize() async {
    if (_userId.isEmpty) return; 
    try {
      await _boxManager.openAllBoxes(_userId);
      await _loadUserAliases(); 
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
        
    _investmentsSubscription = _boxManager
        .getBox<InvestmentModel>(BoxManager.investmentsBoxName, _userId)
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
    // Fetch Investments
    _investments = await _investmentService.getAllInvestments();

    final allAccounts = accountsBox.values.toList();
    final allTransactions = transactionsBox.values.toList();

    // 1. Deduplicate Accounts Logic (moved from HomeScreen)
    _accounts = _deduplicateAccounts(allAccounts, allTransactions);

    // 2. Get Recent Transactions
    // We can use financialService for this, or do it here. 
    // Ensuring consistency by doing it here manually effectively.
    allTransactions.sort((a, b) => b.date.compareTo(a.date));
    _allTransactions = allTransactions;
    _recentTransactions = allTransactions.take(8).toList();

    notifyListeners();
  }

  // Exposed method for Pull-to-Refresh
  Future<void> refresh() async {
    // 1. Scan for new SMS (Optimized)
    if (await _smsReaderService.hasPermission()) {
      // If we have no accounts (first run?), try full discovery first
      if (_accounts.isEmpty) {
         await _smsReaderService.discoverAccounts();
      }
      
      // Ensure parser has latest names before scanning
      await _updateParserNames();

      // Always scan recent messages
      await _smsReaderService.scanRecentMessages(count: 20);
    }
    // 2. Trigger UI update (Box listeners will handle the rest, but we can force it)
    await _refreshDataInternal();
  }

  // --- User Aliases Logic ---
  List<String> _userAliases = [];
  List<String> get userAliases => List.unmodifiable(_userAliases);

  Future<void> _loadUserAliases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userAliases = prefs.getStringList('user_aliases') ?? [];
      await _updateParserNames();
    } catch (e) {
      print('Error loading aliases: $e');
    }
  }

  Future<void> addAlias(String alias) async {
    if (alias.isEmpty || _userAliases.contains(alias)) return;
    _userAliases.add(alias);
    notifyListeners(); // Update UI
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_aliases', _userAliases);
    await _updateParserNames();
  }

  Future<void> removeAlias(String alias) async {
    if (_userAliases.remove(alias)) {
       notifyListeners();
       final prefs = await SharedPreferences.getInstance();
       await prefs.setStringList('user_aliases', _userAliases);
       await _updateParserNames();
    }
  }

  // Allow manual trigger of balance reconciliation (e.g. after manual edits)
  Future<void> reconcileAccount(String accountId) async {
    await _smsReaderService.reconcileBalances(accountId);
    // After logic update, refresh internal lists (UI update)
    await _refreshDataInternal();
  }

  Future<void> _updateParserNames() async {
    final List<String> allNames = [..._userAliases];
    
    // Add Auth names
    // Note: We need FirebaseAuth import or pass it in. 
    // Since we are in Repository, using FirebaseAuth instance directly is acceptable 
    // as it is a singleton service.
    // However, we don't have the import in this file yet.
    // Assuming we add import 'package:firebase_auth/firebase_auth.dart';
    
    // START_TEMPORARY_FIX: Accessing Auth via what we have available or assuming import
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null) {
      final parts = user.displayName!.split(' ');
      
      // Add individual parts
      for (var part in parts) {
        if (part.isNotEmpty && !allNames.contains(part)) {
          allNames.add(part);
        }
      }
    }
    
    _smsReaderService.setUserNames(allNames);
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
