import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import '../../models/transaction_model.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.primaryGold),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.primaryGold),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // M-Pesa Auto-Detection Card
            PremiumCard(
              backgroundColor: AppTheme.accentGreen.withOpacity(0.2),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.successGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                    ),
                    child: const Icon(
                      Icons.sms,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'M-Pesa Auto-Detection',
                          style: GoogleFonts.poppins(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          'Automatically track transactions',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textGray,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: true,
                    onChanged: (val) {},
                    activeColor: AppTheme.accentGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Tabs
            Row(
              children: [
                _buildTab('All', true),
                const SizedBox(width: AppTheme.spacing12),
                _buildTab('Income', false),
                const SizedBox(width: AppTheme.spacing12),
                _buildTab('Expenses', false),
              ],
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Transactions by date
            _buildDateSection('Today', [
              _TransactionExample('Coffee at Java', 'Food & Dining', -350, Icons.local_cafe, AppTheme.accentOrange, '10:30 AM'),
              _TransactionExample('Freelance Payment', 'Income', 15000, Icons.work, AppTheme.accentGreen, '09:15 AM'),
            ]),
            _buildDateSection('Yesterday', [
              _TransactionExample('Electricity Bill', 'Utilities', -2500, Icons.flash_on, AppTheme.accentOrange, '6:00 PM'),
              _TransactionExample('Grocery Shopping', 'Food & Dining', -4200, Icons.shopping_cart, AppTheme.accentBlue, '2:30 PM'),
              _TransactionExample('Salary', 'Income', 85000, Icons.account_balance, AppTheme.accentGreen, '8:00 AM'),
            ]),
            _buildDateSection('Nov 12, 2025', [
              _TransactionExample('Netflix Subscription', 'Entertainment', -1200, Icons.movie, AppTheme.accentRed, '11:45 AM'),
              _TransactionExample('Uber Ride', 'Transport', -650, Icons.local_taxi, AppTheme.accentBlue, '9:20 AM'),
            ]),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.primaryDark,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Transaction',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing20,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryGold : AppTheme.surfaceGray,
        borderRadius: BorderRadius.circular(AppTheme.radius20),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primaryGold.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: isSelected ? AppTheme.primaryDark : AppTheme.textGray,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDateSection(String date, List<_TransactionExample> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
          child: Text(
            date,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGray,
            ),
          ),
        ),
        ...transactions.map((t) => _buildTransactionItem(t)),
        const SizedBox(height: AppTheme.spacing20),
      ],
    );
  }

  Widget _buildTransactionItem(_TransactionExample transaction) {
    // Create a mock Transaction object for navigation
    final mockTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: transaction.title,
      amount: transaction.amount.abs(),
      type: transaction.amount >= 0 ? TransactionType.income : TransactionType.expense,
      category: TransactionCategory.other,
      date: DateTime.now(),
    );

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(transaction: mockTransaction),
            ),
          );
        },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceGray,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
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
              color: transaction.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radius12),
              border: Border.all(
                color: transaction.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(transaction.icon, color: transaction.color, size: 24),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  transaction.category,
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
                '${transaction.amount >= 0 ? '+' : ''}KES ${transaction.amount.abs().toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: transaction.amount >= 0 ? AppTheme.accentGreen : AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                transaction.time,
                style: GoogleFonts.poppins(
                  color: AppTheme.textGray,
                  fontSize: 12,
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

class _TransactionExample {
  final String title;
  final String category;
  final double amount;
  final IconData icon;
  final Color color;
  final String time;

  _TransactionExample(this.title, this.category, this.amount, this.icon, this.color, this.time);
}

