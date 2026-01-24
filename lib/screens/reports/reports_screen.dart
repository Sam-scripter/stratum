import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../repositories/financial_repository.dart';
import '../../models/transaction/transaction_model.dart';
import '../../services/finances/financial_service.dart';
import 'category_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimePeriod _selectedPeriod = TimePeriod.thisMonth;

  String _getPeriodDisplayName(TimePeriod period) {
    switch(period) {
      case TimePeriod.thisWeek: return 'This Week';
      case TimePeriod.thisMonth: return 'This Month';
      case TimePeriod.thisYear: return 'This Year';
      case TimePeriod.today: return 'Today';
      default: return 'Custom';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancialRepository>(
      builder: (context, repository, _) {
        // Filter transactions once for consistency
        final transactions = _filterTransactions(repository.allTransactions);
        
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          appBar: AppBar(
            title: Text(
              'Financial Reports',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            backgroundColor: AppTheme.primaryDark,
            elevation: 0,
            actions: [
              PopupMenuButton<TimePeriod>(
                icon: Icon(Icons.calendar_today, color: AppTheme.primaryGold),
                color: AppTheme.surfaceGray,
                onSelected: (value) {
                  setState(() => _selectedPeriod = value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: TimePeriod.thisWeek, child: Text('This Week')),
                  const PopupMenuItem(value: TimePeriod.thisMonth, child: Text('This Month')),
                  const PopupMenuItem(value: TimePeriod.thisYear, child: Text('This Year')),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryGold,
              labelColor: AppTheme.primaryGold,
              unselectedLabelColor: AppTheme.textGray,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Expenses'),
                Tab(text: 'Income'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(transactions),
              _buildExpensesTab(transactions),
              _buildIncomeTab(transactions),
            ],
          ),
        );
      },
    );
  }

  // Helper to filter transactions
  List<Transaction> _filterTransactions(List<Transaction> allTransactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return allTransactions.where((t) {
      final tDate = t.date;
      final tDateOnly = DateTime(tDate.year, tDate.month, tDate.day);
      
      switch (_selectedPeriod) {
        case TimePeriod.today:
          return tDateOnly == today;
        case TimePeriod.thisWeek:
           // Week starts Sunday
           final daysFromSunday = now.weekday == 7 ? 0 : now.weekday;
           final weekStart = today.subtract(Duration(days: daysFromSunday));
           final weekEnd = weekStart.add(const Duration(days: 7)); // Exclusive
           return (tDateOnly.isAtSameMomentAs(weekStart) || tDateOnly.isAfter(weekStart)) && 
                  tDateOnly.isBefore(weekEnd);
        case TimePeriod.thisMonth:
           return tDate.year == now.year && tDate.month == now.month;
        case TimePeriod.thisYear:
           return tDate.year == now.year;
        default:
           return true;
      }
    }).toList();
  }

  Widget _buildOverviewTab(List<Transaction> transactions) {
    // 1. Calculate Totals
    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.income) income += t.amount;
      else expense += t.amount;
    }
    final net = income - expense;
    final savingsRate = income > 0 ? (net / income * 100) : 0.0;
    final formatter = NumberFormat('#,##0', 'en_US');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Card
          PremiumCard(
            hasGlow: true,
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Summary - ${_getPeriodDisplayName(_selectedPeriod)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Income',
                        'KES ${formatter.format(income)}',
                        AppTheme.accentGreen,
                        Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Expenses',
                        'KES ${formatter.format(expense)}',
                        AppTheme.accentRed,
                        Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Net Savings',
                        'KES ${formatter.format(net)}',
                        AppTheme.primaryGold,
                        Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: _buildSummaryItem(
                        'Savings Rate',
                        '${savingsRate.toStringAsFixed(1)}%',
                        AppTheme.accentBlue,
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),

          // Income vs Expenses Chart
          PremiumCard(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income vs Expenses',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _calculateMaxY(transactions),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: AppTheme.surfaceGray,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              'KES ${rod.toY.toStringAsFixed(0)}',
                              GoogleFonts.poppins(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => _getBottomTitles(value, meta, _selectedPeriod),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                               if (value == 0) return const SizedBox();
                               return Text(
                                  '${(value / 1000).toStringAsFixed(0)}K',
                                  style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textGray),
                               );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: _generateBarGroups(transactions, _selectedPeriod),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),

          // Top Categories
          PremiumCard(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Spending Categories',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing20),
                const SizedBox(height: AppTheme.spacing20),
                ..._buildTopSpendingCategories(transactions),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Center(child: Text('No transactions found', style: GoogleFonts.poppins(color: Colors.white54)));
    }
    
    // Filter expenses only
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          PremiumCard(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense Trends',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(enabled: true),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => _getBottomTitles(value, meta, _selectedPeriod),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                             showTitles: true, 
                             reservedSize: 40,
                             getTitlesWidget: (value, meta) {
                               if (value == 0) return const SizedBox();
                               return Text('${(value / 1000).toStringAsFixed(0)}K', style: TextStyle(fontSize: 10, color: Colors.grey));
                             }
                          )
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateLineSpots(expenses, _selectedPeriod),
                          isCurved: true,
                          color: AppTheme.accentRed,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.accentRed.withOpacity(0.1),
                          ),
                        ),
                      ],
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

  Widget _buildIncomeTab(List<Transaction> transactions) {
     if (transactions.isEmpty) {
      return Center(child: Text('No transactions found', style: GoogleFonts.poppins(color: Colors.white54)));
    }
    
    // Filter income
    final income = transactions.where((t) => t.type == TransactionType.income).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          PremiumCard(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income Trends',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(enabled: true),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => _getBottomTitles(value, meta, _selectedPeriod),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                             showTitles: true, 
                             reservedSize: 40,
                             getTitlesWidget: (value, meta) {
                               if (value == 0) return const SizedBox();
                               return Text('${(value / 1000).toStringAsFixed(0)}K', style: TextStyle(fontSize: 10, color: Colors.grey));
                             }
                          )
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateLineSpots(income, _selectedPeriod),
                          isCurved: true,
                          color: AppTheme.accentGreen,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.accentGreen.withOpacity(0.1),
                          ),
                        ),
                      ],
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

  List<FlSpot> _generateLineSpots(List<Transaction> transactions, TimePeriod period) {
     final Map<int, double> map = {};
     for (var t in transactions) {
        int xIndex = 0;
        final date = t.date;
        if (period == TimePeriod.thisWeek) {
           xIndex = date.weekday % 7; 
        } else {
           xIndex = (date.day - 1) ~/ 7;
        }
        map[xIndex] = (map[xIndex] ?? 0) + t.amount;
     }
     
     final List<FlSpot> spots = [];
     int limit = period == TimePeriod.thisWeek ? 7 : 5;
     
     for (int i = 0; i < limit; i++) {
        spots.add(FlSpot(i.toDouble(), map[i] ?? 0));
     }
     return spots;
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category, double amount, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
              Text(
                'KES ${NumberFormat('#,##0').format(amount)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: AppTheme.borderGray.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // --- Chart Helpers ---

  double _calculateMaxY(List<Transaction> transactions) {
     if (transactions.isEmpty) return 1000;
     double maxVal = 0;
     // Simple estimate: max single transaction * 1.5, or grouping max? 
     // Better: pre-calc groups and find max. For now, static safe buffer relative to highest tx
     for(var t in transactions) {
       if(t.amount > maxVal) maxVal = t.amount;
     }
     return maxVal * 1.2;
  }

  Widget _getBottomTitles(double value, TitleMeta meta, TimePeriod period) {
    // If This Week: Mon, Tue...
    // If This Month: Week 1, 2...
    final index = value.toInt();
    String text = '';
    
    if (period == TimePeriod.thisWeek) {
       const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']; 
       // Adjusted to match weekday(1..7) logic or just 0..6
       if (index >= 0 && index < days.length) text = days[index];
    } else {
       // Month/Year -> W1..W5
       if (index >= 0 && index < 5) text = 'W${index + 1}';
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textGray)),
    );
  }

  List<BarChartGroupData> _generateBarGroups(List<Transaction> transactions, TimePeriod period) {
     // Aggregate by x-axis index
     final Map<int, double> incomeMap = {};
     final Map<int, double> expenseMap = {};

     for (var t in transactions) {
        int xIndex = 0;
        final date = t.date;
        
        if (period == TimePeriod.thisWeek) {
           // 0=Sun, 6=Sat (or Mon-Sun)
           xIndex = date.weekday % 7; // 7->0 (Sun), 1->1 (Mon)
        } else {
           // Month: Week of month (0..4)
           xIndex = (date.day - 1) ~/ 7;
        }
        
        if (t.type == TransactionType.income) {
           incomeMap[xIndex] = (incomeMap[xIndex] ?? 0) + t.amount;
        } else {
           expenseMap[xIndex] = (expenseMap[xIndex] ?? 0) + t.amount;
        }
     }
     
     final List<BarChartGroupData> groups = [];
     int limit = period == TimePeriod.thisWeek ? 7 : 5;
     
     for (int i = 0; i < limit; i++) {
        groups.add(BarChartGroupData(
           x: i,
           barRods: [
              BarChartRodData(toY: incomeMap[i] ?? 0, color: AppTheme.accentGreen, width: 8),
              BarChartRodData(toY: expenseMap[i] ?? 0, color: AppTheme.accentRed, width: 8),
           ],
        ));
     }
     return groups;
  }
  
  List<Widget> _buildTopSpendingCategories(List<Transaction> transactions) {
     final expenses = transactions.where((t) => t.type == TransactionType.expense);
     final totalExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);
     
     if (totalExpense == 0) return [Text('No expense data', style: TextStyle(color: Colors.white54))];
     
     final grouped = groupBy(expenses, (Transaction t) => t.category);
     final List<MapEntry<TransactionCategory, double>> sorted = [];
     
     grouped.forEach((key, list) {
        sorted.add(MapEntry(key, list.fold(0.0, (sum, t) => sum + t.amount)));
     });
     
     sorted.sort((a, b) => b.value.compareTo(a.value));
     
     return sorted.take(5).map((e) {
        final catName = e.key.toString().split('.').last.toUpperCase();
        final amount = e.value;
        final percentage = amount / totalExpense;
        
        // Simple color rotation
        return GestureDetector(
          onTap: () {
             final categoryTransactions = expenses
                 .where((t) => t.category == e.key)
                 .toList();
                 
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => CategoryDetailScreen(
                   categoryName: catName,
                   categoryEnum: e.key,
                   transactions: categoryTransactions,
                 ),
               ),
             );
          },
          child: _buildCategoryRow(catName, amount, percentage, AppTheme.primaryGold),
        );
     }).toList();
  }
}

