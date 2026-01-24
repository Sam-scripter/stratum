import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:stratum/repositories/financial_repository.dart';
import 'package:stratum/screens/accounts/account_detail_screen.dart';
import 'package:stratum/screens/accounts/add_account_screen.dart';
import 'package:stratum/screens/notifications/notifications_screen.dart';
import 'package:stratum/screens/settings/name_aliases_screen.dart';
import 'package:stratum/screens/transactions/add_transaction_screen.dart';
import 'package:stratum/screens/transactions/transaction_detail_screen.dart';

import '../../models/account/account_model.dart';
import '../../models/transaction/transaction_model.dart';
import '../../services/finances/financial_service.dart';
import '../transactions/transactions_screen.dart';
import '../reports/reports_screen.dart';
import '../ai_advisor/ai_advisor_screen.dart';
import '../onboarding/sms_scanning_screen.dart';
import '../budgets/budget_screen.dart';
import '../../services/finances/budget_service.dart';
import '../../theme/app_theme.dart';
import '../accounts/account_detail_screen.dart';
import '../onboarding/sms_scanning_screen.dart';
import '../accounts/add_account_screen.dart';
import '../budgets/budget_screen.dart';
import '../../services/finances/budget_service.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Local state for UI toggles only
  bool _isBalanceVisible = true;
  bool _isBackgroundSyncing = false;
  bool _hasSmsPermission = false;
  bool _isCategoryExpanded = false;
  TimePeriod _selectedPeriod = TimePeriod.today;
  FinancialSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FinancialRepository>().refresh();
        _checkPermissions();
      }
    });
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.sms.status;
    if (mounted) {
      setState(() {
        _hasSmsPermission = status.isGranted;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
       context.read<FinancialRepository>().refresh();
       _checkPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Helper to calculate Net Worth locally from Repository data
  double _calculateNetWorth(List<Account> accounts) {
    double assets = accounts
        .where((a) => a.type != AccountType.Liability)
        .fold(0, (sum, a) => sum + a.balance);
    double liabilities = accounts
        .where((a) => a.type == AccountType.Liability)
        .fold(0, (sum, a) => sum + a.balance);
    return assets - liabilities;
  }

  // Get user's display name from Firebase Auth
  String _getUserDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      final nameParts = user.displayName!.split(' ');
      return nameParts[0];
    }

    if (user.email != null) {
      final emailParts = user.email!.split('@');
      return emailParts[0];
    }

    return 'User';
  }

  // Helper to get the "Freshness" text
  String _lastUpdatedText(List<Account> accounts) {
    if (accounts.isEmpty) return 'No data';

    final latest = accounts
        .map((e) => e.lastUpdated)
        .where((date) => date != null)
        .fold<DateTime?>(null, (prev, current) {
          if (prev == null) return current;
          return current.isAfter(prev) ? current : prev;
        });

    if (latest == null) return 'No data';

    final now = DateTime.now();
    final latestLocal = latest.toLocal();
    final diff = now.difference(latestLocal);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    
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
    return Consumer<FinancialRepository>(
      builder: (context, repository, child) {
        final accounts = repository.accounts;
        final recentTransactions = repository.recentTransactions;
        final netWorth = _calculateNetWorth(accounts);
        
        // Use repository summary if available, or update local cache
        if (_summary == null) {
          try {
             _summary = repository.getSummary(_selectedPeriod);
          } catch(e) {
             // Fallback or loading state handled implicitly
          }
        }
        
        // Ensure summary is never null for UI rendering
        final currentSummary = _summary ?? repository.getSummary(_selectedPeriod); 

        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await repository.refresh();
                setState(() {
                   _summary = repository.getSummary(_selectedPeriod);
                });
              },
              color: AppTheme.primaryGold,
              backgroundColor: const Color(0xFF1A2332),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildNetWorthCard(netWorth, accounts, repository.isLoading),
                    const SizedBox(height: 20),
                    _buildAccountsScroll(accounts, repository.isLoading),
                    const SizedBox(height: 20),
                    _buildQuickStats(currentSummary),
                    const SizedBox(height: 32),
                    _buildQuickActions(),
                    const SizedBox(height: 32),
                    _buildFinancialHealthScore(),
                    const SizedBox(height: 32),
                    _buildAIInsights(),
                    const SizedBox(height: 32),
                    _buildSpendingByCategory(repository), // Pass repository if needed for queries
                    const SizedBox(height: 32),
                    _buildRecentTransactions(recentTransactions),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _buildCleanFAB(context),
        );
      },
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
              Row(
                children: [
                  // Settings Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2332),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white, size: 22),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NameAliasesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Notifications Button
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
            ],
          ),
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

  Widget _buildNetWorthCard(double netWorth, List<Account> accounts, bool isLoading) {
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
                child: isLoading
                    ? ShaderMask( 
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
                    : ShaderMask( 
                  shaderCallback: (bounds) {
                    return AppTheme.goldGradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    );
                  },
                  child: Text(
                    _isBalanceVisible
                        ? netWorth
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
                'Updated ${_lastUpdatedText(accounts)}',
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

  Widget _buildAccountsScroll(List<Account> accounts, bool isLoading) {
    if (accounts.isEmpty && !isLoading) return const SizedBox.shrink();

    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length + 1, 
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == accounts.length) {
            return _buildAddAccountCard();
          }
          return _buildAccountCard(accounts[index]);
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
  
  // Method to request SMS permission
  Future<void> _requestSmsPermission() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SmsScanningScreen()),
    );
  }
  
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
                      // We can check repository or service directly for data presence
                      final hasData = context.read<FinancialRepository>().getSummary(period).totalIncome > 0 
                          || context.read<FinancialRepository>().getSummary(period).totalExpense > 0;
                      // Just allow all for now or check service
                      // Better to use repository pass-through
                      
                      final isSelected = _selectedPeriod == period;

                      return ListTile(
                        title: Text(
                          period.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
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
                        enabled: true,
                        onTap: () {
                            setState(() {
                              _selectedPeriod = period;
                              _summary = context.read<FinancialRepository>().getSummary(_selectedPeriod);
                            });
                            Navigator.pop(context);
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(FinancialSummary summary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
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
                  'KES ${summary.totalIncome.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
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
                  'KES ${summary.totalExpense.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
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
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'View Options',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentBlue,
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

  Widget _buildSpendingByCategory(FinancialRepository repository) {
    // This probably needs to be fetched from repository properly
    // Using simple mock or logic similar to what was there if possible
    // For now, let's just use what was likely logic:
    // This widget was complex, let's keep it but ideally refactor.
    // Assuming we can get top spending via Repository/Service
    
    // We can use the service solely for computation if we pass it data, 
    // or just rely on the repository's data
    // Let's create a temporary instance or use the one from repository if exposed
    // But repository doesn't expose service.
    // Let's instantiate a local service just for calculating stats from repo data?
    // Or add getTopSpending to Repository.
    
    // For now, let's instantiate FinancialService as a helper since it's just logic mostly
    final helperService = FinancialService();
    // Use data from repository
    // Wait, getTopSpendingCategories fetches from Hive directly inside service.
    // So it's safe to call if boxes are open.
    
    final allCategories = helperService.getTopSpendingCategories(limit: 100);
    
    if (allCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalExpense = allCategories.fold(0.0, (sum, item) => sum + item.value);
    
    // Take top 4
    final topCategories = allCategories.take(4).toList();
    // Group rest
    final rest = allCategories.skip(4).toList();
    
    // If expanded, show all (limited)
    final listItems = _isCategoryExpanded ? allCategories : topCategories;

    // Chart data always shows top segments + others logic if needed
    // ... logic from before ...
    // Simplified for this rewrite:
    
    final colors = [
          Color(0xFF4C6FFF),
          Color(0xFF4CC9F0),
          Color(0xFF7209B7),
          Color(0xFFF72585),
          Color(0xFFFFDD00),
        ];

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
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: listItems.asMap().entries.map((entry) {
                         final index = entry.key;
                         final item = entry.value;
                         final percentage = totalExpense == 0 ? 0.0 : (item.value / totalExpense) * 100;
                         return PieChartSectionData(
                           value: percentage,
                           color: colors[index % colors.length],
                           radius: 50,
                           title: '${percentage.toStringAsFixed(0)}%',
                           titleStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                         );
                      }).toList(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                 // Legend/List
                 const SizedBox(height: 20),
                 Column(
                   children: listItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final name = item.key.toString().split('.').last;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                             Container(
                               width: 12, height: 12, 
                               decoration: BoxDecoration(
                                 color: colors[index % colors.length],
                                 borderRadius: BorderRadius.circular(3),
                               ),
                             ),
                             const SizedBox(width: 8),
                             Text(name, style: TextStyle(color: Colors.white70)),
                             Spacer(),
                             Text('KES ${item.value.toStringAsFixed(0)}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                   }).toList(),
                 ),
                 
                 if (rest.isNotEmpty)
                   TextButton(
                     onPressed: () {
                        setState(() { _isCategoryExpanded = !_isCategoryExpanded; });
                     },
                     child: Text(_isCategoryExpanded ? 'Show Less' : 'Show More'),
                   ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions) {
    if (transactions.isEmpty) {
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
                ...transactions.take(10).toList().asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final transaction = entry.value;
                  final transactionsList = transactions
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
                        builder: (context) => BudgetScreen(userId: FirebaseAuth.instance.currentUser!.uid),
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
          if (result == true && mounted) {
             context.read<FinancialRepository>().refresh();
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
