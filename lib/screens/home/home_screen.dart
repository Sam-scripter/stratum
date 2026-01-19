// home_screen.dart:

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stratum/screens/transactions/add_transaction_screen.dart';
import 'package:stratum/screens/transactions/transaction_detail_screen.dart';
import '../../models/account/account_model.dart';
import '../../models/box_manager.dart';
import '../../services/cloud_sync/sync_service.dart';
import '../../services/sms_reader/sms_reader_service.dart';
import '../../theme/app_theme.dart';
import '../../models/transaction/transaction_model.dart';
import '../../services/finances/financial_service.dart';
import '../transactions/transactions_screen.dart';
import '../reports/reports_screen.dart';
import '../ai_advisor/ai_advisor_screen.dart';
import '../notifications/notifications_screen.dart';
import 'package:intl/intl.dart';
import '../accounts/account_detail_screen.dart';
import '../onboarding/sms_scanning_screen.dart';
import '../accounts/add_account_screen.dart';
import '../budgets/budget_screen.dart';
import '../../services/finances/budget_service.dart';
import 'package:hive/hive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FinancialService _financialService = FinancialService();
  final BoxManager _boxManager = BoxManager();

  // Services will be initialized in initState
  late String _userId;
  late SyncService _syncService;
  late SmsReaderService _smsReaderService;

  // Background sync status
  bool _isBackgroundSyncing = false;

  late FinancialSummary _summary;
  late List<Transaction> _recentTransactions;
  TimePeriod _selectedPeriod = TimePeriod.today; // Start with Today

  // Multi-Account State
  List<Account> _accounts = [];
  bool _isBalanceVisible = true;
  bool _isLoadingAccounts = true;
  bool _hasSmsPermission = false;

  // Box listeners for real-time updates
  StreamSubscription? _accountsSubscription;
  StreamSubscription? _transactionsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register lifecycle observer
    _summary = _financialService.getFinancialSummary(period: _selectedPeriod);
    _recentTransactions = _financialService.getRecentTransactions(limit: 8);

    // Wait for Firebase auth to be ready
    _initializeWithAuth();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
       // App came to foreground - quick check for recent messages
       _checkForNewMessages(isQuickCheck: true);
    }
  }

  Future<void> _checkForNewMessages({bool isQuickCheck = true}) async {
    // Determine how many messages to check
    // Quick check (resume) = 10 messages
    // Full check (pull-to-refresh) = 20 messages
    final count = isQuickCheck ? 10 : 20;
    
    // Only proceed if services are initialized
    // ignore: unnecessary_null_comparison
    if (_smsReaderService != null) {
      if (await _smsReaderService.hasPermission()) {
        final found = await _smsReaderService.scanRecentMessages(count: count);
        if (found > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Found $found new transactions'), behavior: SnackBarBehavior.floating,),
          );
          _refreshAccountData(); // Refresh UI manually just in case
        }
      }
    }
  }

  Future<void> _initializeWithAuth() async {
    // Wait for Firebase Auth to initialize
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Listen for auth state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null && mounted) {
          _initializeWithUserId(user.uid);
        }
      });
    } else {
      _initializeWithUserId(user.uid);
    }
  }

  void _initializeWithUserId(String userId) {
    _userId = userId;
    print("USER ID IS $_userId (length: ${userId.length})");

    // 2. Initialize Services with the obtained user ID
    _syncService = SyncService(_userId);
    _smsReaderService = SmsReaderService(_userId);

    _initializeFinancials();

    // Update completed periods on app start
    _financialService.updateCompletedPeriods();
    
    // Initial check on startup as well
    _checkForNewMessages(isQuickCheck: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _accountsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }

  bool _isRefreshing = false;

  void _setupBoxListeners() {
    // Set up listeners for real-time updates when background service modifies data
    _accountsSubscription = _boxManager
        .getBox<Account>(BoxManager.accountsBoxName, _userId)
        .watch()
        .listen((event) {
          if (mounted && !_isRefreshing) { // ✅ ADD flag check
            _isRefreshing = true;
            print('Accounts box changed, refreshing UI');
            _refreshAccountData().then((_) {
              if (mounted) {
                _isRefreshing = false;
              }
            });
          }
        });

    _transactionsSubscription = _boxManager
        .getBox<Transaction>(BoxManager.transactionsBoxName, _userId)
        .watch()
        .listen((event) {
           // No need to check _isMerging anymore
          print('Transactions box changed, refreshing UI');
          _refreshAccountData();
        });
  }

  Future<void> _refreshAccountData() async {
    if (!mounted) return;

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

    // Apply the same filtering logic as in _initializeFinancials
    // Use deterministic selection: always pick the same account ID for the same key
    final Map<String, Account> uniqueAccounts = {};
    for (var account in allAccounts) {
      final key = _getAccountKey(account);
      if (!uniqueAccounts.containsKey(key)) {
        uniqueAccounts[key] = account;
      } else {
        final existing = uniqueAccounts[key]!;
        // Deterministic: prefer account with more transactions, then higher balance, then earlier ID (alphabetically)
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
            // If everything is equal, prefer the account with earlier ID (deterministic)
            shouldReplace = account.id.compareTo(existing.id) < 0;
          }
        }
        
        if (shouldReplace) {
          uniqueAccounts[key] = account;
        }
      }
    }

    final filteredAccounts = uniqueAccounts.values.where((account) {
      final hasTransactions = allTransactions.any(
        (t) => t.accountId == account.id,
      );
      if (account.balance == 0 && !hasTransactions) {
        return false;
      }
      return true;
    }).toList();

    // Log which accounts are being displayed for debugging
    if (filteredAccounts.length != _accounts.length || 
        filteredAccounts.any((acc) => !_accounts.any((a) => a.id == acc.id))) {
      print('Account display changed:');
      print('  Previous: ${_accounts.map((a) => '${a.name}(${a.balance})').join(', ')}');
      print('  Current: ${filteredAccounts.map((a) => '${a.name}(${a.balance})').join(', ')}');
      for (var account in filteredAccounts) {
        final txCount = allTransactions.where((t) => t.accountId == account.id).length;
        print('    - ${account.name} (${account.id.substring(0, 8)}...): Balance=${account.balance}, Tx=$txCount, Updated=${account.lastUpdated}');
      }
    }

    setState(() {
      _accounts = filteredAccounts;
    });

    // Also refresh the summary and recent transactions
    setState(() {
      _summary = _financialService.getFinancialSummary(period: _selectedPeriod);
      _recentTransactions = _financialService.getRecentTransactions(limit: 8);
    });
  }

  late Box<Account> _accountsBox;
  late Box<Transaction> _transactionsBox;

  Future<void> _initializeFinancials() async {
    // 1. Check SMS permission status (but don't request it)
    final status = await Permission.sms.status;
    setState(() {
      _hasSmsPermission = status.isGranted;
    });

    await _boxManager.openAllBoxes(_userId);

    // Cache boxes
    _accountsBox = _boxManager.getBox<Account>(
      BoxManager.accountsBoxName,
      _userId,
    );
    _transactionsBox = _boxManager.getBox<Transaction>(
      BoxManager.transactionsBoxName,
      _userId,
    );

    // Set up box listeners now that boxes are open
    _setupBoxListeners();

    // 2. Load existing accounts first (before SMS parsing)
    if (mounted) {
      final accountsBox = _boxManager.getBox<Account>(
        BoxManager.accountsBoxName,
        _userId,
      );
      final transactionsBox = _boxManager.getBox<Transaction>(
        BoxManager.transactionsBoxName,
        _userId,
      );


      // Reload accounts after merging (they may have changed)
      final accountsAfterMerge = accountsBox.values.toList();
      final transactionsAfterMerge = transactionsBox.values.toList();

      // Then deduplicate for display
      // Use deterministic selection: always pick the same account ID for the same key
      final Map<String, Account> uniqueAccounts = {};
      for (var account in accountsAfterMerge) {
        // Create a unique key based on account type and normalized sender address
        final key = _getAccountKey(account);
        if (!uniqueAccounts.containsKey(key)) {
          uniqueAccounts[key] = account;
        } else {
          // If duplicate found, use deterministic selection
          final existing = uniqueAccounts[key]!;
          final existingTxCount = transactionsAfterMerge
              .where((t) => t.accountId == existing.id)
              .length;
          final currentTxCount = transactionsAfterMerge
              .where((t) => t.accountId == account.id)
              .length;

          bool shouldReplace = false;
          if (currentTxCount > existingTxCount) {
            shouldReplace = true;
          } else if (currentTxCount == existingTxCount) {
            if (account.balance > existing.balance) {
              shouldReplace = true;
            } else if (account.balance == existing.balance) {
              // If everything is equal, prefer the account with earlier ID (deterministic)
              shouldReplace = account.id.compareTo(existing.id) < 0;
            }
          }
          
          if (shouldReplace) {
            uniqueAccounts[key] = account;
          }
        }
      }

      final filteredAccounts = uniqueAccounts.values.where((account) {
        // Show account if it has a balance > 0 OR has transactions
        final hasTransactions = transactionsAfterMerge.any(
          (t) => t.accountId == account.id,
        );
        // Filter out accounts with 0 balance AND no transactions
        if (account.balance == 0 && !hasTransactions) {
          return false;
        }
        return true;
      }).toList();

      setState(() {
        _accounts = filteredAccounts;
        _isLoadingAccounts = false;
      });
      _loadTransactionData();
    }

    // 3. Sync with Cloud (Merges Firebase data into Hive) - also in background
    // Note: SMS reading is handled by SMS scanning screen, not here
    // DISABLE CLOUD SYNC FOR NOW (User Request)
    /*
    _syncService
        .syncAccounts()
        .then((_) async {
          // Reload accounts after cloud sync
          if (mounted) {
            final accountsBox = _boxManager.getBox<Account>(
              BoxManager.accountsBoxName,
              _userId,
            );
            final transactionsBox = _boxManager.getBox<Transaction>(
              BoxManager.transactionsBoxName,
              _userId,
            );

            // Reload after merging
            final accountsAfterMerge = accountsBox.values.toList();
            final transactionsAfterMerge = transactionsBox.values.toList();

            // Deduplicate accounts for display
            final Map<String, Account> uniqueAccounts = {};
            for (var account in accountsAfterMerge) {
              final key = _getAccountKey(account);
              if (!uniqueAccounts.containsKey(key)) {
                uniqueAccounts[key] = account;
              } else {
                final existing = uniqueAccounts[key]!;
                final existingTxCount = transactionsAfterMerge
                    .where((t) => t.accountId == existing.id)
                    .length;
                final currentTxCount = transactionsAfterMerge
                    .where((t) => t.accountId == account.id)
                    .length;

                if (account.balance > existing.balance ||
                    (account.balance == existing.balance &&
                        currentTxCount > existingTxCount)) {
                  uniqueAccounts[key] = account;
                }
              }
            }

            setState(() {
              _accounts = uniqueAccounts.values.toList();
            });
            _loadTransactionData();
          }
        })
        .catchError((error) {
          print('Error syncing with cloud: $error');
        });
    */
  }

  // ==============================================================================
  // SMS READING (financial_tracker approach)
  // ==============================================================================

  /// Read SMS messages using financial_tracker's simple approach
  /// SMS reading removed - handled by SMS scanning screen only

  // Helper to reload transaction-based widgets
  void _loadTransactionData() {
    if (!mounted) return;
    // Use post-frame callback to ensure we're not in the middle of a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _summary = _financialService.getFinancialSummary(
            period: _selectedPeriod,
          );
          _recentTransactions = _financialService.getRecentTransactions(
            limit: 8,
          );
        });
      }
    });
  }

  // Helper to create unique key for account deduplication
  String _getAccountKey(Account account) {
    // For MPESA, check by name first (regardless of type) to catch incorrectly typed accounts
    final normalizedName = account.name.toUpperCase().trim();
    if (normalizedName == 'MPESA' || 
        normalizedName == 'M-PESA' ||
        normalizedName.contains('MPESA') ||
        normalizedName.contains('M-PESA')) {
      return 'MPESA';
    }
    
    // For other accounts, use normalized name (not type, to catch type mismatches)
    return normalizedName;
  }



  // Helper to calculate Net Worth
  double get _totalNetWorth {
    double assets = _accounts
        .where((a) => a.type != AccountType.Liability)
        .fold(0, (sum, a) => sum + a.balance);
    double liabilities = _accounts
        .where((a) => a.type == AccountType.Liability)
        .fold(0, (sum, a) => sum + a.balance);
    return assets - liabilities;
  }

  // Helper to calculate Free Cash (Net Worth - Savings Allocations)
  Future<double> _calculateFreeCash() async {
    final budgetService = BudgetService(_userId);
    return await budgetService.getFreeCash();
  }

  // Get user's display name from Firebase Auth
  String _getUserDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';

    // Try to get display name first
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      // Extract first name (split by space and take first part)
      final nameParts = user.displayName!.split(' ');
      return nameParts[0];
    }

    // Fallback to email username (before @)
    if (user.email != null) {
      final emailParts = user.email!.split('@');
      return emailParts[0];
    }

    return 'User';
  }

  // Show time period selector
  void _showTimePeriodSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Time Period',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...TimePeriod.values.map((period) {
                      final hasData = _financialService.hasDataForPeriod(
                        period,
                      );
                      final isSelected = _selectedPeriod == period;

                      return ListTile(
                        title: Text(
                          period.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: hasData ? Colors.white : Colors.white38,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: AppTheme.primaryGold,
                                size: 20,
                              )
                            : null,
                        enabled: hasData,
                        onTap: hasData
                            ? () {
                                setState(() {
                                  _selectedPeriod = period;
                                  _summary = _financialService
                                      .getFinancialSummary(period: period);
                                });
                                Navigator.pop(context);
                              }
                            : null,
                      );
                    }),
                    const SizedBox(height: 8),
                    // Info message explaining progressive periods
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              TimePeriod.values.any(
                                    (p) =>
                                        !_financialService.hasDataForPeriod(p),
                                  )
                                  ? 'Periods unlock as you use the app. Start with "Today" and more options will become available over time.'
                                  : 'All periods are now available. Data is tracked from when you first installed the app.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to SMS scanning screen when user wants to enable SMS reading
  Future<void> _requestSmsPermission() async {
    // Navigate to SMS scanning screen instead of requesting permission directly
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SmsScanningScreen()),
    );
  }

  // Helper to get the "Freshness" text
  String get _lastUpdatedText {
    if (_accounts.isEmpty) return 'No data';

    // Find the most recent update time across all accounts
    final latest = _accounts
        .map((e) => e.lastUpdated)
        .where((date) => date != null)
        .fold<DateTime?>(null, (prev, current) {
          if (prev == null) return current;
          return current.isAfter(prev) ? current : prev;
        });

    if (latest == null) return 'No data';

    // Ensure we're working with local time
    final now = DateTime.now();
    final latestLocal = latest.toLocal();
    final diff = now.difference(latestLocal);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    
    // Check if it's actually the same calendar day
    if (now.year == latestLocal.year && 
        now.month == latestLocal.month && 
        now.day == latestLocal.day) {
      return 'Today, ${DateFormat('HH:mm').format(latestLocal)}';
    }
    
    if (diff.inDays < 2) return 'Yesterday';
    return DateFormat('MMM d').format(latestLocal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Deep navy - clean design
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _initializeFinancials();
            // Also force re-scan recent SMS messages for any missing transactions
            await _checkForNewMessages(isQuickCheck: false);
          }, // Pull to refresh reloads accounts and rescans SMS
          color: AppTheme.primaryGold,
          backgroundColor: const Color(0xFF1A2332),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 14),
                // 1. Net Worth Card
                _buildNetWorthCard(),
                // 2. ACCOUNTS SCROLL (The Breakdown)
                const SizedBox(height: 20),
                _buildAccountsScroll(),

                SizedBox(height: 20),
                // Income/Expense Quick Stats
                _buildQuickStats(),
                const SizedBox(height: 32),
                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 32),
                // Financial Health Score
                _buildFinancialHealthScore(),
                const SizedBox(height: 32),
                // AI Insights
                _buildAIInsights(),
                const SizedBox(height: 32),
                // Spending by Category
                _buildSpendingByCategory(),
                const SizedBox(height: 32),
                // Recent Transactions
                _buildRecentTransactions(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildCleanFAB(context),
    );
  }

  // --- Horizontal Scroll for Individual Accounts ---
  Widget _buildAccountsScroll() {
    if (_isLoadingAccounts) return const SizedBox.shrink();

    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: _accounts.length + 1, // +1 for "Add Account"
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == _accounts.length) {
            return _buildAddAccountCard();
          }
          return _buildAccountCard(_accounts[index]);
        },
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    final isLiability = account.type == AccountType.Liability;
    final color = isLiability
        ? AppTheme.accentRed
        : (account.type == AccountType.Mpesa
              ? const Color(0xFF43B02A)
              : AppTheme.accentBlue);
    final icon = account.type == AccountType.Mpesa
        ? Icons.phone_android
        : (isLiability
              ? Icons.warning_amber_rounded
              : Icons.account_balance_wallet);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountDetailScreen(account: account),
          ),
        );
      },
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    account.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isBalanceVisible
                  ? 'KES ${account.balance.toStringAsFixed(0)}'
                  : '••••',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isLiability && account.balance > 0
                    ? AppTheme.accentRed
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAccountCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddAccountScreen(),
          ),
        );
      },
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(child: Icon(Icons.add, color: Colors.white54)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME BACK',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getUserDisplayName(),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: const Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    // Unread badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0A1628),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Background Sync Status Indicator
          if (_isBackgroundSyncing) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analyzing historical data...',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- UPDATED: Net Worth Card with Freshness Indicator ---
  Widget _buildNetWorthCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundLight,
            AppTheme.backgroundLight.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'TOTAL NET WORTH',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _hasSmsPermission
                          ? AppTheme.positive
                          : AppTheme.warning,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_hasSmsPermission
                              ? AppTheme.positive
                              : AppTheme.warning).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!_hasSmsPermission)
                GestureDetector(
                  onTap: _requestSmsPermission,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.warningGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Enable Sync',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KES ',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textGray,
                  height: 2,
                ),
              ),
              Expanded(
                child: _isLoadingAccounts
                    ? ShaderMask( // ✅ IMPROVED loading
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        AppTheme.primaryGold,
                        AppTheme.lightGold,
                        AppTheme.primaryGold,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds);
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
                    : ShaderMask( // ✅ GOLD gradient on amount
                  shaderCallback: (bounds) {
                    return AppTheme.goldGradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    );
                  },
                  child: Text(
                    _isBalanceVisible
                        ? _totalNetWorth
                        .toStringAsFixed(0)
                        .replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]},',
                    )
                        : '••••••',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: AppTheme.textGray.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'Updated $_lastUpdatedText',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textGray.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() =>
                _isBalanceVisible = !_isBalanceVisible
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDeep.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isBalanceVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.textGray.withOpacity(0.5),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UPDATED: Quick Stats with "Month" Context ---
  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Header Row with Dropdown-like UI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cash Flow',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () => _showTimePeriodSelector(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedPeriod.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Income',
                  'KES ${_summary.totalIncome.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  AppTheme.accentGreen,
                  Icons.arrow_downward,
                  onTap: () => _showFilteredTransactions(
                    context,
                    TransactionType.income,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Expenses',
                  'KES ${_summary.totalExpense.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  AppTheme.accentRed,
                  Icons.arrow_upward,
                  onTap: () => _showFilteredTransactions(
                    context,
                    TransactionType.expense,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show filtered transactions by type
  void _showFilteredTransactions(BuildContext context, TransactionType type) {
    final filter = type == TransactionType.income 
        ? TransactionFilter.income 
        : TransactionFilter.expenses;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionsScreen(initialFilter: filter),
      ),
    );
  }

  Widget _buildFinancialHealthScore() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Health',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2332),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accentGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '78',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.78,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.accentGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Good financial health. Keep up the savings momentum.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Insight',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentBlue.withOpacity(0.1),
                  AppTheme.accentBlue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentBlue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.accentBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Smart Savings Opportunity',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'You have KES 15,000 idle in your account. Moving this to a money market fund could earn you ~KES 75 this month.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Investment options coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppTheme.accentBlue,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Explore Options',
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingByCategory() {
    final topCategories = _financialService.getTopSpendingCategories(limit: 5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2332),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: topCategories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value.key;
                        final amount = entry.value.value;
                        final total = topCategories.fold<double>(
                          0,
                          (sum, item) => sum + item.value,
                        );
                        final percentage = (amount / total) * 100;

                        final colors = [
                          AppTheme.primaryGold,
                          AppTheme.accentBlue,
                          AppTheme.accentGreen,
                          AppTheme.accentOrange,
                          AppTheme.accentRed,
                        ];

                        return PieChartSectionData(
                          value: percentage,
                          color: colors[index % colors.length],
                          radius: 60,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          title: '${percentage.toStringAsFixed(0)}%',
                        );
                      }).toList(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: topCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value.key;
                    final amount = entry.value.value;

                    final colors = [
                      AppTheme.primaryGold,
                      AppTheme.accentBlue,
                      AppTheme.accentGreen,
                      AppTheme.accentOrange,
                      AppTheme.accentRed,
                    ];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category.toString().split('.').last,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                          Text(
                            'KES ${amount.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_recentTransactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            'No transactions yet',
            style: GoogleFonts.poppins(color: Colors.white60),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TransactionsScreen(initialFilter: null),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2332),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                ..._recentTransactions.take(10).toList().asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final transaction = entry.value;
                  final transactionsList = _recentTransactions
                      .take(10)
                      .toList();
                  final isLast = index == transactionsList.length - 1;
                  return Column(
                    children: [
                      _buildTransactionItem(
                        transaction.title,
                        transaction.categoryName,
                        transaction.amount,
                        transaction.categoryEmoji,
                        transaction.type == TransactionType.income
                            ? AppTheme.accentGreen
                            : AppTheme.accentRed,
                        transaction.type == TransactionType.income,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TransactionDetailScreen(
                                transaction: transaction,
                              ),
                            ),
                          );
                        },
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.white.withOpacity(0.05),
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    String title,
    String category,
    double amount,
    String emoji,
    Color color,
    bool isIncome,
    VoidCallback? onTap,
  ) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          category,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}KES ${amount.toStringAsFixed(0)}',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  'Add Transaction',
                  Icons.add_circle_outline,
                  AppTheme.accentGreen,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddTransactionScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickAction(
                  'Smart Budgets',
                  Icons.savings_outlined,
                  AppTheme.accentBlue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BudgetScreen(userId: _userId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  'View Reports',
                  Icons.bar_chart_rounded,
                  AppTheme.accentOrange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickAction(
                  'AI Advisor',
                  Icons.psychology_outlined,
                  AppTheme.accentBlue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AIAdvisorScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
          // Refresh data if transaction was added/updated
          if (result == true && mounted) {
            await _initializeFinancials();
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add, color: Color(0xFF0A1628)),
        label: Text(
          'Add Transaction',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0A1628),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
