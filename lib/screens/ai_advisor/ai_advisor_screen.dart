import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class AIAdvisorScreen extends StatefulWidget {
  const AIAdvisorScreen({Key? key}) : super(key: key);

  @override
  State<AIAdvisorScreen> createState() => _AIAdvisorScreenState();
}

class _AIAdvisorScreenState extends State<AIAdvisorScreen> {
  String _selectedTimeframe = 'This Month';
  bool _isPremium = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'AI Financial Advisor',
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
              setState(() => _selectedTimeframe = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
              const PopupMenuItem(value: 'This Month', child: Text('This Month')),
              const PopupMenuItem(value: 'This Year', child: Text('This Year')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Upgrade Banner (if not premium)
            if (!_isPremium)
              PremiumCard(
                backgroundColor: AppTheme.primaryGold.withOpacity(0.15),
                hasGlow: true,
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: AppTheme.primaryDark,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'Unlock AI-Powered Insights',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'Get personalized financial recommendations powered by advanced AI',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radius12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Upgrade to Premium',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!_isPremium) const SizedBox(height: AppTheme.spacing24),

            // AI Insights Section
            Text(
              'AI Insights - $_selectedTimeframe',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Spending Analysis Insight
            AIInsightCard(
              title: 'Spending Analysis',
              insight: 'Your spending on Food & Dining has increased by 15% compared to last month. Consider setting a budget limit to maintain better financial health.',
              actionLabel: 'Set Budget Limit',
              accentColor: AppTheme.accentOrange,
              onAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Savings Recommendation
            AIInsightCard(
              title: 'Savings Opportunity',
              insight: 'Based on your income pattern, you could save an additional KES 12,000 this month by optimizing non-essential expenses.',
              actionLabel: 'View Recommendations',
              accentColor: AppTheme.accentGreen,
              onAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recommendations coming soon!')),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Investment Suggestion
            AIInsightCard(
              title: 'Investment Opportunity',
              insight: 'With your current savings rate of 31.6%, consider investing in money market funds for better returns. Expected annual return: 12-15%.',
              actionLabel: 'Explore Investments',
              accentColor: AppTheme.accentBlue,
              onAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Investments feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Financial Health Score
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'AI Financial Health Score',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentGreen,
                              AppTheme.accentGreen.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radius20),
                        ),
                        child: Text(
                          '78/100',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHealthMetric('Budget Adherence', 85, AppTheme.accentGreen),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: _buildHealthMetric('Savings Rate', 72, AppTheme.accentBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHealthMetric('Spending Control', 90, AppTheme.accentGreen),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: _buildHealthMetric('Growth Potential', 65, AppTheme.accentOrange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Recommendations Section
            Text(
              'Personalized Recommendations',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildRecommendation(
              'Reduce Dining Expenses',
              'Cut down on restaurant meals by 30% to save KES 8,500 this month',
              Icons.restaurant,
              AppTheme.accentRed,
            ),
            _buildRecommendation(
              'Automate Savings',
              'Set up automatic transfers of KES 15,000 monthly to savings',
              Icons.savings,
              AppTheme.accentGreen,
            ),
            _buildRecommendation(
              'Diversify Investments',
              'Consider allocating 20% of savings to money market funds',
              Icons.trending_up,
              AppTheme.accentBlue,
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, int score, Color color) {
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
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 8,
                    backgroundColor: AppTheme.borderGray.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                '$score%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(
          color: color.withOpacity(0.3),
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textGray,
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
}

