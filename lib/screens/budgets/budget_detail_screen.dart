import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/budget/budget_model.dart';
import '../../models/transaction/transaction_model.dart';
import 'add_budget_screen.dart';

class BudgetDetailScreen extends StatelessWidget {
  final BudgetDetail budget;

  const BudgetDetailScreen({
    Key? key,
    required this.budget,
  }) : super(key: key);

  String _getCategoryEmoji(TransactionCategory category) {
    final transaction = Transaction(
      id: '',
      title: '',
      amount: 0,
      type: TransactionType.expense,
      category: category,
      date: DateTime.now(),
      accountId: '', // Empty account ID for display purposes only
    );
    return transaction.categoryEmoji;
  }

  String _getCategoryName(TransactionCategory category) {
    final transaction = Transaction(
      id: '',
      title: '',
      amount: 0,
      type: TransactionType.expense,
      category: category,
      date: DateTime.now(),
      accountId: '', // Empty account ID for display purposes only
    );
    return transaction.categoryName;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = budget.percentage.clamp(0.0, 1.0);
    final progressColor = budget.isOverBudget
        ? AppTheme.accentRed
        : (percentage > 0.8 ? AppTheme.accentOrange : AppTheme.accentGreen);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          budget.name.isEmpty ? 'Budget Details' : budget.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppTheme.primaryGold),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddBudgetScreen(
                    budgetToEdit: budget.toBudget(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.accentRed),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.surfaceGray,
                  title: Text(
                    'Delete Budget',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to delete this budget?',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textGray,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Budget deleted'),
                            backgroundColor: AppTheme.accentRed,
                          ),
                        );
                      },
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Budget Overview Card
            PremiumCard(
              hasGlow: true,
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radius16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGold.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryEmoji(budget.category),
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing20),
                  Text(
                    budget.name.isEmpty ? _getCategoryName(budget.category) : budget.name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'KES ${budget.spentAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: progressColor,
                            ),
                          ),
                          Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: AppTheme.spacing4,
                      ),
                            decoration: BoxDecoration(
                              color: progressColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppTheme.radius20),
                              border: Border.all(
                                color: progressColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: progressColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radius12),
                        child: LinearProgressIndicator(
                          value: percentage > 1 ? 1 : percentage,
                          minHeight: 12,
                          backgroundColor: AppTheme.borderGray.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'of KES ${budget.budgetAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Budget Statistics
            Row(
              children: [
                Expanded(
                  child: PremiumCard(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remaining',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textGray,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          budget.remaining >= 0
                              ? 'KES ${budget.remaining.toStringAsFixed(0)}'
                              : 'KES ${budget.remaining.abs().toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: budget.remaining >= 0
                                ? AppTheme.accentGreen
                                : AppTheme.accentRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: PremiumCard(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textGray,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: AppTheme.spacing4,
                      ),
                          decoration: BoxDecoration(
                            color: budget.isOverBudget
                                ? AppTheme.accentRed.withOpacity(0.2)
                                : (percentage > 0.8
                                    ? AppTheme.accentOrange.withOpacity(0.2)
                                    : AppTheme.accentGreen.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(AppTheme.radius20),
                            border: Border.all(
                              color: budget.isOverBudget
                                  ? AppTheme.accentRed.withOpacity(0.3)
                                  : (percentage > 0.8
                                      ? AppTheme.accentOrange.withOpacity(0.3)
                                      : AppTheme.accentGreen.withOpacity(0.3)),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            budget.isOverBudget
                                ? 'Over Budget'
                                : (percentage > 0.8 ? 'Warning' : 'On Track'),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: budget.isOverBudget
                                  ? AppTheme.accentRed
                                  : (percentage > 0.8
                                      ? AppTheme.accentOrange
                                      : AppTheme.accentGreen),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Budget Information
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing20),
                  _buildInfoRow(
                    'Category',
                    _getCategoryName(budget.category),
                    AppTheme.primaryGold,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildInfoRow(
                    'Budget Amount',
                    'KES ${budget.budgetAmount.toStringAsFixed(2)}',
                    AppTheme.primaryLight,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildInfoRow(
                    'Spent',
                    'KES ${budget.spentAmount.toStringAsFixed(2)}',
                    progressColor,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildInfoRow(
                    'Start Date',
                    '${budget.startDate.day}/${budget.startDate.month}/${budget.startDate.year}',
                    AppTheme.textGray,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildInfoRow(
                    'End Date',
                    '${budget.endDate.day}/${budget.endDate.month}/${budget.endDate.year}',
                    AppTheme.textGray,
                  ),
                  if (budget.notes != null && budget.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textGray,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          budget.notes!,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: AppTheme.primaryLight,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Actions
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildActionButton(
                    context,
                    'Edit Budget',
                    Icons.edit_outlined,
                    AppTheme.primaryGold,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddBudgetScreen(
                            budgetToEdit: budget.toBudget(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildActionButton(
                    context,
                    'View Transactions',
                    Icons.receipt_long,
                    AppTheme.accentBlue,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transactions feature coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textGray,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: AppTheme.spacing12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

