// home_screen.dart(stratum app):

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stratum/screens/transactions/add_transaction_screen.dart';
import 'package:stratum/screens/transactions/transaction_detail_screen.dart';
import '../../models/account/account_model.dart';
import '../../services/sms_parser_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import '../../models/transaction/transaction_model.dart';
import '../../services/financial_service.dart';
import '../transactions/transactions_screen.dart';
import '../budgets/add_budget_screen.dart';
import '../reports/reports_screen.dart';
import '../ai_advisor/ai_advisor_screen.dart';
import '../notifications/notifications_screen.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FinancialService _financialService = FinancialService();
  final SmsParserService _smsParser = SmsParserService();

  late FinancialSummary _summary;
  late List<Transaction> _recentTransactions;

  // Multi-Account State
  List<Account> _accounts = [];
  bool _isBalanceVisible = true;
  bool _isLoadingAccounts = true;
  bool _hasSmsPermission = false;

  @override
  void initState() {
    super.initState();
    _summary = _financialService.getFinancialSummary();
    _recentTransactions = _financialService.getRecentTransactions(limit: 8);
    _initializeFinancials();
  }

  Future<void> _initializeFinancials() async {
    // 1. Check Permissions
    var status = await Permission.sms.status;
    setState(() {
      _hasSmsPermission = status.isGranted;
    });

    // 2. If granted, parse SMS (This updates the Hive 'accounts' box locally)
    if (_hasSmsPermission) {
      await _smsParser.parseAndSyncMessages();
    }

    // 3. Sync with Cloud (Merges Firebase data into Hive)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final syncService = SyncService(user.uid);
      await syncService.syncAccounts();
    }

    // 4. Load Real Data from Hive
    if (mounted) {
      // Ensure the box is open (Safety check)
      if (!Hive.isBoxOpen('accounts')) {
        await Hive.openBox<Account>('accounts');
      }

      final box = Hive.box<Account>('accounts');
      final realAccounts = box.values.toList();

      setState(() {
        _accounts = realAccounts;
        _isLoadingAccounts = false;
      });

      // 5. Trigger a refresh of the transaction data (Summary & Charts)
      _loadTransactionData();
    }
  }

// Helper to reload transaction-based widgets
  void _loadTransactionData() {
    setState(() {
      _summary = _financialService.getFinancialSummary();
      _recentTransactions = _financialService.getRecentTransactions(limit: 8);
    });
  }

  // Helper to calculate Net Worth
  double get _totalNetWorth {
    double assets = _accounts.where((a) => a.type != AccountType.Liability).fold(0, (sum, a) => sum + a.currentBalance);
    double liabilities = _accounts.where((a) => a.type == AccountType.Liability).fold(0, (sum, a) => sum + a.currentBalance);
    return assets - liabilities;
  }

  Future<void> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      setState(() {
        _hasSmsPermission = true;
        _isLoadingAccounts = true;
      });
      await _initializeFinancials();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS permission needed to sync M-Pesa automatically.')),
        );
      }
    }
  }

  // Helper to get the "Freshness" text
  String get _lastUpdatedText {
    if (_accounts.isEmpty) return 'No data';

    // Find the most recent update time across all accounts
    // Default to DateTime(2000) if no dates exist to avoid errors
    final latest = _accounts.map((e) => e.lastUpdated).reduce(
            (a, b) => a.isAfter(b) ? a : b
    );

    final diff = DateTime.now().difference(latest);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Today, ${DateFormat('HH:mm').format(latest)}';
    if (diff.inDays < 2) return 'Yesterday';
    return DateFormat('MMM d').format(latest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Deep navy - clean design
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _initializeFinancials, // Pull to refresh syncs SMS
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

                SizedBox(height: 20,),
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
    final color = isLiability ? AppTheme.accentRed : (account.type == AccountType.Mpesa ? const Color(0xFF43B02A) : AppTheme.accentBlue);
    final icon = account.type == AccountType.Mpesa
        ? Icons.phone_android
        : (isLiability ? Icons.warning_amber_rounded : Icons.account_balance_wallet);

    return Container(
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
                      color: Colors.white70
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isBalanceVisible
                ? 'KES ${account.currentBalance.toStringAsFixed(0)}'
                : '••••',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isLiability && account.currentBalance > 0 ? AppTheme.accentRed : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountCard() {
    return GestureDetector(
      onTap: () {
        // Navigate to Add Account Screen (To be implemented)
      },
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05), style: BorderStyle.solid),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
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
                'Alex Johnson',
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
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
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
    );
  }

  // --- UPDATED: Net Worth Card with Freshness Indicator ---
  Widget _buildNetWorthCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A2332),
              const Color(0xFF1A2332).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Side: Title + Status Dot
                Row(
                  children: [
                    Text(
                      'TOTAL NET WORTH',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // The "Freshness" Dot
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: _hasSmsPermission ? AppTheme.accentGreen : Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_hasSmsPermission ? AppTheme.accentGreen : Colors.orange).withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ]
                      ),
                    ),
                  ],
                ),

                // Right Side: Permission Status (Simplified)
                if (!_hasSmsPermission)
                  GestureDetector(
                    onTap: _requestSmsPermission,
                    child: Text(
                      'Enable Sync',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGold
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'KES ',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.white60, height: 2),
                ),
                Expanded(
                  child: _isLoadingAccounts
                      ? SizedBox(height: 30, child: LinearProgressIndicator(color: AppTheme.primaryGold, backgroundColor: Colors.transparent))
                      : Text(
                    _isBalanceVisible
                        ? _totalNetWorth.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')
                        : '••••••',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // The "Last Updated" Text
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.white.withOpacity(0.3)),
                const SizedBox(width: 6),
                Text(
                  'Updated $_lastUpdatedText',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Eye Icon moved here for better balance
                GestureDetector(
                  onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                  child: Icon(
                    _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white.withOpacity(0.3),
                    size: 18,
                  ),
                ),
              ],
            )
          ],
        ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Text(
                      'This Month', // Make this dynamic later
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white54),
                  ],
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
                  'KES ${_summary.totalIncome.toStringAsFixed(0).replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                  )}',
                  AppTheme.accentGreen,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Expenses',
                  'KES ${_summary.totalExpense.toStringAsFixed(0).replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                  )}',
                  AppTheme.accentRed,
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
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
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
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
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
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
              border: Border.all(
                color: AppTheme.accentBlue.withOpacity(0.2),
              ),
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
                        const SnackBar(content: Text('Investment options coming soon!')),
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
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: topCategories
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final category = entry.value.key;
                        final amount = entry.value.value;
                        final total = topCategories
                            .fold<double>(0, (sum, item) => sum + item.value);
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
                      })
                          .toList(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: topCategories
                      .asMap()
                      .entries
                      .map((entry) {
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
                  })
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
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
                      builder: (context) => const TransactionsScreen(),
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
          ..._recentTransactions.take(3).map((transaction) => _buildTransactionItem(
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
          )).toList(),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}KES ${amount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
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
                  'Set Budget',
                  Icons.savings_outlined,
                  AppTheme.accentBlue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddBudgetScreen(),
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
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
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