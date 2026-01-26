import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/transaction/transaction_model.dart';
import '../../theme/app_theme.dart';
import '../transactions/transaction_detail_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;
  final TransactionCategory categoryEnum;
  final List<Transaction> transactions;

  const CategoryDetailScreen({
    Key? key,
    required this.categoryName,
    required this.categoryEnum,
    required this.transactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);
    
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          categoryName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacing20),
            color: AppTheme.surfaceGray,
            child: Column(
              children: [
                Text(
                  'Total Spending',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textGray,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'KES ${NumberFormat('#,##0').format(totalAmount)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transactions.length} transactions',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryGold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionDetailScreen(transaction: transaction),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.accentRed.withOpacity(0.1),
                    child: Icon(
                      _getCategoryIcon(transaction.category),
                      color: AppTheme.accentRed,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    transaction.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(transaction.date),
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Text(
                    '-${NumberFormat('#,##0').format(transaction.amount)}',
                    style: GoogleFonts.poppins(
                      color: AppTheme.accentRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.salary: return Icons.attach_money;
      case TransactionCategory.freelance: return Icons.laptop_mac;
      case TransactionCategory.utilities: return Icons.flash_on;
      case TransactionCategory.groceries: return Icons.shopping_basket;
      case TransactionCategory.transport: return Icons.directions_bus;
      case TransactionCategory.entertainment: return Icons.movie;
      case TransactionCategory.dining: return Icons.restaurant;
      case TransactionCategory.health: return Icons.local_hospital;
      case TransactionCategory.shopping: return Icons.shopping_bag;
      case TransactionCategory.transfer: return Icons.swap_horiz;
      default: return Icons.category;
    }
  }
}
