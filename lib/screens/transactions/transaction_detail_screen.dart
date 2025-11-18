import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/transaction/transaction_model.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Transaction Details',
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
                  builder: (context) => AddTransactionScreen(
                    transactionToEdit: transaction,
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
                    'Delete Transaction',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to delete this transaction?',
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
                            content: const Text('Transaction deleted'),
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
            // Amount Card
            PremiumCard(
              hasGlow: true,
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (isIncome ? AppTheme.accentGreen : AppTheme.accentRed)
                              .withOpacity(0.3),
                          (isIncome ? AppTheme.accentGreen : AppTheme.accentRed)
                              .withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radius16),
                      border: Border.all(
                        color: (isIncome ? AppTheme.accentGreen : AppTheme.accentRed)
                            .withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isIncome ? AppTheme.accentGreen : AppTheme.accentRed)
                              .withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        transaction.categoryEmoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing20),
                  Text(
                    transaction.title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncome ? '+' : '-',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: isIncome
                              ? AppTheme.accentGreen.withOpacity(0.8)
                              : AppTheme.primaryLight.withOpacity(0.8),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        transaction as String,
                        style: GoogleFonts.poppins(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: isIncome
                              ? AppTheme.accentGreen
                              : AppTheme.primaryLight,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isIncome
                          ? LinearGradient(
                              colors: [
                                AppTheme.accentGreen.withOpacity(0.2),
                                AppTheme.accentGreen.withOpacity(0.15),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                AppTheme.accentRed.withOpacity(0.2),
                                AppTheme.accentRed.withOpacity(0.15),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(AppTheme.radius20),
                      border: Border.all(
                        color: (isIncome ? AppTheme.accentGreen : AppTheme.accentRed)
                            .withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      transaction.categoryName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? AppTheme.accentGreen : AppTheme.accentRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Transaction Information
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing20),
                  _buildInfoRow(
                    'Type',
                    isIncome ? 'Income' : 'Expense',
                    isIncome ? AppTheme.accentGreen : AppTheme.accentRed,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildInfoRow(
                    'Date',
                    transaction as String,
                    AppTheme.textGray,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildInfoRow(
                    'Time',
                    transaction as String,
                    AppTheme.textGray,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildInfoRow(
                    'Category',
                    transaction.categoryName,
                    AppTheme.primaryGold,
                  ),
                  if (transaction.description != null) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textGray,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          transaction.description!,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: AppTheme.primaryLight,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (transaction.mpesaCode != null) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    _buildInfoRow(
                      'M-Pesa Code',
                      transaction.mpesaCode!,
                      AppTheme.primaryGold,
                    ),
                  ],
                  if (transaction.recipient != null) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    _buildInfoRow(
                      'Recipient',
                      transaction.recipient!,
                      AppTheme.textGray,
                    ),
                  ],
                  if (transaction.isRecurring) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          color: AppTheme.primaryGold,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Text(
                          'Recurring Transaction',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.w600,
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
                    'Edit Transaction',
                    Icons.edit_outlined,
                    AppTheme.primaryGold,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddTransactionScreen(
                            transactionToEdit: transaction,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildActionButton(
                    context,
                    'Share Transaction',
                    Icons.share_outlined,
                    AppTheme.accentBlue,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share feature coming soon!')),
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

