import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/investment_model.dart';
import 'add_investment_screen.dart';
import 'investment_detail_screen.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Investments',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.primaryGold),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Portfolio Value
            PremiumCard(
              backgroundColor: AppTheme.surfaceGray,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Portfolio Value',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textGray,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radius20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: AppTheme.accentGreen,
                              size: 16,
                            ),
                            const SizedBox(width: AppTheme.spacing4),
                            Text(
                              '+12.5%',
                              style: GoogleFonts.poppins(
                                color: AppTheme.accentGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'KES 285,000',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'Gain: KES 31,500',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // AI Investment Advisor
            PremiumCard(
              backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: AppTheme.accentBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Investment Advisor',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          '🔒 Get personalized portfolio recommendations',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textGray,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Portfolio Distribution
            Text(
              'Portfolio Distribution',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            PremiumCard(
              child: Column(
                children: [
                  _buildPortfolioItem('Money Market Funds', 45, AppTheme.accentBlue),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildPortfolioItem('SACCO Shares', 30, AppTheme.accentGreen),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildPortfolioItem('Government Bonds', 15, AppTheme.accentOrange),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildPortfolioItem('Stocks', 10, AppTheme.accentRed),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Active Investments
            Text(
              'Active Investments',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildInvestmentCard(
              'CIC Money Market Fund',
              'Money Market',
              128250,
              12.5,
              AppTheme.accentBlue,
            ),
            _buildInvestmentCard(
              'Stima SACCO',
              'SACCO Shares',
              85500,
              8.3,
              AppTheme.accentGreen,
            ),
            _buildInvestmentCard(
              'Treasury Bonds',
              'Government Securities',
              42750,
              14.2,
              AppTheme.accentOrange,
            ),
            _buildInvestmentCard(
              'NSE Stocks Portfolio',
              'Equities',
              28500,
              -2.1,
              AppTheme.accentRed,
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Investment Opportunities
            Text(
              'Investment Opportunities',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildOpportunityCard(
              'Sanlam Money Market Fund',
              '11.2% p.a.',
              'Min: KES 5,000',
              'Low Risk',
              AppTheme.accentGreen,
            ),
            _buildOpportunityCard(
              'Kenya Treasury Bills',
              '15.8% p.a.',
              'Min: KES 50,000',
              'Low Risk',
              AppTheme.accentBlue,
            ),
            _buildOpportunityCard(
              'Equity Bank Rights Issue',
              'Market Rate',
              'Min: 100 shares',
              'Medium Risk',
              AppTheme.accentOrange,
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddInvestmentScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.accentGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Investment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioItem(String name, double percentage, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: AppTheme.borderGray.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentCard(String name, String type, double value, double returnRate, Color color) {
    bool isPositive = returnRate > 0;
    // Create a mock investment for navigation
    final mockInvestment = Investment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: _getInvestmentTypeFromString(type),
      investedAmount: value * 0.9, // Approximate
      currentValue: value,
      returnRate: returnRate,
      dateInvested: DateTime.now().subtract(const Duration(days: 90)),
    );
    
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => InvestmentDetailScreen(
                investment: mockInvestment,
              ),
            ),
          );
        },
        child: Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(
          color: AppTheme.borderGray.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radius12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(Icons.account_balance_wallet, color: color, size: 24),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  type,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textGray,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KES ${value.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppTheme.accentGreen.withOpacity(0.2)
                      : AppTheme.accentRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                  border: Border.all(
                    color: isPositive
                        ? AppTheme.accentGreen.withOpacity(0.3)
                        : AppTheme.accentRed.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? AppTheme.accentGreen : AppTheme.accentRed,
                      size: 12,
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Text(
                      '${returnRate.abs().toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        color: isPositive ? AppTheme.accentGreen : AppTheme.accentRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  InvestmentType _getInvestmentTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'money market':
        return InvestmentType.moneyMarket;
      case 'sacco shares':
        return InvestmentType.sacco;
      case 'government securities':
        return InvestmentType.bonds;
      case 'equities':
        return InvestmentType.stocks;
      default:
        return InvestmentType.other;
    }
  }

  Widget _buildOpportunityCard(String name, String rate, String minimum, String risk, Color color) {
    // Create a mock opportunity for navigation
    final mockOpportunity = InvestmentOpportunity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      expectedReturn: rate,
      minimumInvestment: minimum,
      riskLevel: risk,
      type: InvestmentType.moneyMarket, // Default, could be determined by name
      provider: 'Investment Provider',
    );
    
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          // Navigate to Add Investment screen with opportunity pre-filled
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddInvestmentScreen(
                opportunity: mockOpportunity,
              ),
            ),
          );
        },
        child: Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radius20),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  risk,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Icon(Icons.show_chart, color: color, size: 20),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Returns: $rate',
                style: GoogleFonts.poppins(
                  color: AppTheme.textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              Icon(Icons.payments, color: AppTheme.textGray, size: 20),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                minimum,
                style: GoogleFonts.poppins(
                  color: AppTheme.textGray,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}

