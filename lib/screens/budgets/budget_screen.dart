import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import 'add_budget_screen.dart';
import 'budget_detail_screen.dart';
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Budget',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryGold),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddBudgetScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Overview Card
            PremiumCard(
              backgroundColor: AppTheme.surfaceGray,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'October Budget',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'KES 42,520 / 60,000',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                    child: LinearProgressIndicator(
                      value: 0.71,
                      minHeight: 8,
                      backgroundColor: AppTheme.borderGray.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    '71% used • KES 17,480 remaining',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // AI Budget Recommendation
            PremiumCard(
              backgroundColor: AppTheme.accentGreen.withOpacity(0.1),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      color: AppTheme.accentGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Budget Optimizer',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          '🔒 Get personalized budget recommendations',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textGray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Category Budgets
            Text(
              'Budget by Category',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildBudgetCategory(
              'Food & Dining',
              15000,
              12500,
              Icons.restaurant,
              AppTheme.accentRed,
            ),
            _buildBudgetCategory(
              'Transport',
              8000,
              6200,
              Icons.local_taxi,
              AppTheme.accentBlue,
            ),
            _buildBudgetCategory(
              'Entertainment',
              5000,
              3800,
              Icons.movie,
              AppTheme.accentBlue,
            ),
            _buildBudgetCategory(
              'Shopping',
              12000,
              9500,
              Icons.shopping_bag,
              AppTheme.accentOrange,
            ),
            _buildBudgetCategory(
              'Utilities',
              10000,
              8520,
              Icons.flash_on,
              AppTheme.accentGreen,
            ),
            _buildBudgetCategory(
              'Others',
              10000,
              2000,
              Icons.more_horiz,
              AppTheme.textGray,
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Savings Goals
            Text(
              'Savings Goals',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSavingsGoal(
              'Emergency Fund',
              50000,
              32000,
              AppTheme.accentBlue,
            ),
            _buildSavingsGoal('New Laptop', 80000, 45000, AppTheme.accentGreen),
            _buildSavingsGoal('Vacation', 120000, 28000, AppTheme.accentOrange),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  TransactionCategory _getCategoryFromName(String name) {
    switch (name) {
      case 'Food & Dining':
        return TransactionCategory.dining;
      case 'Transport':
        return TransactionCategory.transport;
      case 'Entertainment':
        return TransactionCategory.entertainment;
      case 'Shopping':
        return TransactionCategory.shopping;
      case 'Utilities':
        return TransactionCategory.utilities;
      default:
        return TransactionCategory.other;
    }
  }

  Widget _buildBudgetCategory(
    String name,
    double budget,
    double spent,
    IconData icon,
    Color color,
  ) {
    double percentage = spent / budget;
    final category = _getCategoryFromName(name);

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          final budgetDetail = BudgetDetail(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            budgetAmount: budget,
            spentAmount: spent,
            category: category,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 30)),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BudgetDetailScreen(budget: budgetDetail),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
          padding: const EdgeInsets.all(AppTheme.spacing20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceGray,
            borderRadius: BorderRadius.circular(AppTheme.radius16),
            border: Border.all(
              color: AppTheme.borderGray.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
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
                          name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          'KES ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textGray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: percentage > 0.9 ? AppTheme.accentRed : color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                child: LinearProgressIndicator(
                  value: percentage > 1 ? 1 : percentage,
                  minHeight: 8,
                  backgroundColor: AppTheme.borderGray.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage > 0.9 ? AppTheme.accentRed : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSavingsGoal(
    String name,
    double target,
    double saved,
    Color color,
  ) {
    double percentage = saved / target;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(
          color: AppTheme.borderGray.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryLight,
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
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              backgroundColor: AppTheme.borderGray.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KES ${saved.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  color: AppTheme.textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'KES ${target.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  color: AppTheme.textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
