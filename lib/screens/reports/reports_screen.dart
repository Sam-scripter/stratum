import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';

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
          PopupMenuButton<String>(
            icon: Icon(Icons.calendar_today, color: AppTheme.primaryGold),
            color: AppTheme.surfaceGray,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
              const PopupMenuItem(value: 'This Month', child: Text('This Month')),
              const PopupMenuItem(value: 'This Year', child: Text('This Year')),
              const PopupMenuItem(value: 'Custom', child: Text('Custom Range')),
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
          _buildOverviewTab(),
          _buildExpensesTab(),
          _buildIncomeTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
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
                  'Financial Summary - $_selectedPeriod',
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
                        'KES 125,000',
                        AppTheme.accentGreen,
                        Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Expenses',
                        'KES 85,420',
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
                        'KES 39,580',
                        AppTheme.primaryGold,
                        Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: _buildSummaryItem(
                        'Savings Rate',
                        '31.6%',
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
                      maxY: 150000,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
                              if (value.toInt() < labels.length) {
                                return Text(
                                  labels[value.toInt()],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppTheme.textGray,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1000).toStringAsFixed(0)}K',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppTheme.textGray,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25000,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderGray.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: 35000,
                              color: AppTheme.accentGreen,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: 22000,
                              color: AppTheme.accentRed,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: 42000,
                              color: AppTheme.accentGreen,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: 28000,
                              color: AppTheme.accentRed,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 2,
                          barRods: [
                            BarChartRodData(
                              toY: 31000,
                              color: AppTheme.accentGreen,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: 19000,
                              color: AppTheme.accentRed,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 3,
                          barRods: [
                            BarChartRodData(
                              toY: 17000,
                              color: AppTheme.accentGreen,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: 16420,
                              color: AppTheme.accentRed,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ],
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
                _buildCategoryRow('Food & Dining', 28500, 0.33, AppTheme.accentRed),
                _buildCategoryRow('Transport', 18200, 0.21, AppTheme.accentBlue),
                _buildCategoryRow('Shopping', 15400, 0.18, AppTheme.accentOrange),
                _buildCategoryRow('Entertainment', 12300, 0.14, AppTheme.accentOrange),
                _buildCategoryRow('Utilities', 11020, 0.13, AppTheme.accentGreen),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
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
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 10000,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderGray.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (value.toInt() < labels.length) {
                                return Text(
                                  labels[value.toInt()],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppTheme.textGray,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1000).toStringAsFixed(0)}K',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppTheme.textGray,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 15000),
                            FlSpot(1, 22000),
                            FlSpot(2, 18000),
                            FlSpot(3, 25000),
                            FlSpot(4, 19000),
                            FlSpot(5, 21000),
                            FlSpot(6, 16420),
                          ],
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

  Widget _buildIncomeTab() {
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
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 10000,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderGray.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (value.toInt() < labels.length) {
                                return Text(
                                  labels[value.toInt()],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppTheme.textGray,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1000).toStringAsFixed(0)}K',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppTheme.textGray,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 35000),
                            FlSpot(1, 42000),
                            FlSpot(2, 31000),
                            FlSpot(3, 48000),
                            FlSpot(4, 36000),
                            FlSpot(5, 41000),
                            FlSpot(6, 17000),
                          ],
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
                'KES ${amount.toStringAsFixed(0)}',
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
}

