import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stratum/screens/transactions/add_transaction_screen.dart';
import 'package:stratum/screens/transactions/transaction_detail_screen.dart';
import '../../theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../services/financial_service.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/enhanced_widgets_demo.dart';
import '../budgets/add_budget_screen.dart';
import '../reports/reports_screen.dart';
import '../ai_advisor/ai_advisor_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FinancialService _financialService = FinancialService();
  late FinancialSummary _summary;
  late List<Transaction> _recentTransactions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _summary = _financialService.getFinancialSummary();
    _recentTransactions = _financialService.getRecentTransactions(limit: 8);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: AppTheme.spacing20),
              // Net Worth Card
              _buildNetWorthCard(),
              const SizedBox(height: AppTheme.spacing20),
              // Quick Actions (moved right after balance for better action flow)
              _buildQuickActions(),
              const SizedBox(height: AppTheme.spacing20),
              // Financial Health Score
              _buildFinancialHealthScore(),
              const SizedBox(height: AppTheme.spacing20),
              // AI Insights
              _buildAIInsights(),
              const SizedBox(height: AppTheme.spacing20),
              // Spending by Category
              _buildSpendingByCategory(),
              const SizedBox(height: AppTheme.spacing20),
              // Recent Transactions
              _buildRecentTransactions(),
              const SizedBox(height: AppTheme.spacing32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'Alex Johnson',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Preview Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnhancedWidgetsDemo(),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radius8),
                        border: Border.all(
                          color: AppTheme.primaryGold.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.preview,
                        color: AppTheme.primaryGold,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  // Notification icon
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGray,
                        borderRadius: BorderRadius.circular(AppTheme.radius12),
                        border: Border.all(
                          color: AppTheme.borderGray.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.notifications_outlined,
                              color: AppTheme.primaryGold,
                              size: 24,
                            ),
                          ),
                          // Unread badge (you can make this dynamic based on actual notification count)
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
                                  color: AppTheme.primaryDark,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: PremiumCard(
        backgroundColor: AppTheme.surfaceGray,
        hasGlow: true, // Add gold glow to balance card
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Balance',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.textGray,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KES ',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.primaryGold.withOpacity(0.6),
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  _summary.balance.toStringAsFixed(2).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      ),
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGold,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      border: Border.all(
                        color: AppTheme.borderGray.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textGray,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          'KES ${_summary.totalIncome.toStringAsFixed(2).replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]},',
                              )}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentGreen,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      border: Border.all(
                        color: AppTheme.borderGray.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expenses',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textGray,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          'KES ${_summary.totalExpense.toStringAsFixed(2).replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]},',
                              )}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentRed,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: Row(
        children: [
          Expanded(
            child: PremiumCard(
              backgroundColor: AppTheme.surfaceGray,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: const Center(
                      child: Text('📈', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    'Income',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'KES ${_summary.totalIncome.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: PremiumCard(
              backgroundColor: AppTheme.surfaceGray,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: const Center(
                      child: Text('📉', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    'Expenses',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'KES ${_summary.totalExpense.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthScore() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: FinancialHealthScore(
        score: 78,
        description:
            'Your financial health is good! Keep up the consistent saving habits and consider diversifying your investments.',
      ),
    );
  }

  Widget _buildAIInsights() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Insights',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          AIInsightCard(
            title: 'Smart Savings Opportunity',
            insight:
                'You have KES 15,000 idle in your account. Moving this to Britam Money Market Fund could earn you ~KES 75 this month.',
            actionLabel: 'View Investment Options',
            accentColor: AppTheme.accentBlue,
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Investment options coming soon!')),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacing12),
          AIInsightCard(
            title: 'Spending Alert',
            insight:
                'Your dining expenses are 35% higher than last month. Consider setting a weekly limit to stay on track.',
            actionLabel: 'Adjust Budget',
            accentColor: AppTheme.accentOrange,
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget adjustment coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingByCategory() {
    final topCategories = _financialService.getTopSpendingCategories(limit: 5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
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
            const SizedBox(height: AppTheme.spacing16),
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
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
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
                      const SizedBox(width: AppTheme.spacing8),
                      Expanded(
                        child: Text(
                          category.toString().split('.').last,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ),
                      Text(
                        'KES ${amount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryLight,
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
    );
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
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
                  color: AppTheme.primaryLight,
                  letterSpacing: 0.3,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('View all transactions coming soon!')),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radius20),
                    border: Border.all(
                      color: AppTheme.primaryGold.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          // Individual cards for each transaction
          ..._recentTransactions
              .map((transaction) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                    child: PremiumCard(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TransactionDetailScreen(
                              transaction: transaction,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          // Category Icon Container - Smaller like financial_advisor
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacing12),
                            decoration: BoxDecoration(
                              color: (transaction.type == TransactionType.income
                                      ? AppTheme.accentGreen
                                      : AppTheme.accentRed)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radius12),
                              border: Border.all(
                                color: (transaction.type == TransactionType.income
                                        ? AppTheme.accentGreen
                                        : AppTheme.accentRed)
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              transaction.categoryEmoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          // Transaction Details - Compact layout
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  transaction.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  transaction.categoryName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.textGray,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Amount - Compact like financial_advisor
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                transaction.type == TransactionType.income
                                    ? '+${transaction.formattedAmount.replaceAll('KES ', '')}'
                                    : '-${transaction.formattedAmount.replaceAll('KES ', '')}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: transaction.type == TransactionType.income
                                      ? AppTheme.accentGreen
                                      : AppTheme.primaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                transaction.formattedTime,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  'Add Transaction',
                  Icons.add_circle_outline,
                  AppTheme.accentGreen,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _buildQuickAction(
                  'Set Budget',
                  Icons.savings_outlined,
                  AppTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  'View Reports',
                  Icons.bar_chart_rounded,
                  AppTheme.accentOrange,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _buildQuickAction(
                  'AI Advisor',
                  Icons.psychology_outlined,
                  AppTheme.primaryGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        if (title == 'Add Transaction') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        } else if (title == 'Set Budget') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
          );
        } else if (title == 'View Reports') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportsScreen()),
          );
        } else if (title == 'AI Advisor') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIAdvisorScreen()),
          );
        }
      },
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                border: Border.all(
                  color: color.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
                letterSpacing: 0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
