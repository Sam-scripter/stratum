// transactions_screen.dart(stratum):

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import '../../models/transaction/transaction_model.dart';

enum TransactionFilter { all, income, expenses }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _selectedFilter = TransactionFilter.all;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  // Sample transactions with dates - using outlined icons
  final List<_TransactionExample> _allTransactions = [
    _TransactionExample('Coffee at Java', 'Food & Dining', -350, Icons.local_cafe_outlined, AppTheme.accentOrange, DateTime.now(), '10:30 AM'),
    _TransactionExample('Freelance Payment', 'Income', 15000, Icons.work_outline, AppTheme.accentGreen, DateTime.now(), '09:15 AM'),
    _TransactionExample('Electricity Bill', 'Utilities', -2500, Icons.flash_on_outlined, AppTheme.accentOrange, DateTime.now().subtract(const Duration(days: 1)), '6:00 PM'),
    _TransactionExample('Grocery Shopping', 'Food & Dining', -4200, Icons.shopping_cart_outlined, AppTheme.accentBlue, DateTime.now().subtract(const Duration(days: 1)), '2:30 PM'),
    _TransactionExample('Salary', 'Income', 85000, Icons.account_balance_outlined, AppTheme.accentGreen, DateTime.now().subtract(const Duration(days: 1)), '8:00 AM'),
    _TransactionExample('Netflix Subscription', 'Entertainment', -1200, Icons.movie_outlined, AppTheme.accentRed, DateTime.now().subtract(const Duration(days: 2)), '11:45 AM'),
    _TransactionExample('Uber Ride', 'Transport', -650, Icons.local_taxi_outlined, AppTheme.accentBlue, DateTime.now().subtract(const Duration(days: 2)), '9:20 AM'),
  ];

  List<_TransactionExample> get _filteredTransactions {
    var transactions = _allTransactions;

    // Apply filter
    switch (_selectedFilter) {
      case TransactionFilter.income:
        transactions = transactions.where((t) => t.amount >= 0).toList();
        break;
      case TransactionFilter.expenses:
        transactions = transactions.where((t) => t.amount < 0).toList();
        break;
      case TransactionFilter.all:
      default:
        break;
    }

    // Apply search
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      transactions = transactions.where((t) {
        return t.title.toLowerCase().contains(searchQuery) ||
               t.category.toLowerCase().contains(searchQuery);
      }).toList();
    }

    return transactions;
  }

  Map<String, List<_TransactionExample>> get _groupedTransactions {
    final grouped = <String, List<_TransactionExample>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final transaction in _filteredTransactions) {
      final transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      String sectionTitle;
      if (transactionDate == today) {
        sectionTitle = 'Today';
      } else if (transactionDate == yesterday) {
        sectionTitle = 'Yesterday';
      } else {
        sectionTitle = _formatDate(transactionDate);
      }

      grouped.putIfAbsent(sectionTitle, () => []).add(transaction);
    }

    // Sort transactions within each group by time (most recent first)
    grouped.forEach((key, value) {
      value.sort((a, b) => b.date.compareTo(a.date));
    });

    return grouped;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[date.weekday - 1];
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Deep navy - clean design
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.close_outlined : Icons.search_outlined,
              color: Colors.white.withOpacity(0.6),
            ),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // M-Pesa Auto-Detection Card
                CleanCard(
                  backgroundColor: AppTheme.accentGreen.withOpacity(0.15),
                  child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sms_outlined,
                      color: AppTheme.accentGreen,
                      size: 24,
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
                const SizedBox(height: 24),

                // Filter Tabs
                Text(
                  'Filter',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterTab('All', TransactionFilter.all),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterTab('Income', TransactionFilter.income),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterTab('Expenses', TransactionFilter.expenses),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Search Bar
                if (_isSearchVisible)
                  CleanCard(
                    padding: EdgeInsets.zero,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search_outlined,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_outlined,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                if (_isSearchVisible) const SizedBox(height: 16),

                // Transactions List
                if (_filteredTransactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppTheme.textGray.withOpacity(0.3),
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          Text(
                            'No transactions found',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textGray,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._groupedTransactions.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: 12,
                            top: entry.key == _groupedTransactions.keys.first ? 0 : 20,
                          ),
                          child: Text(
                            entry.key,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.5),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        ...entry.value.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildTransactionItem(t),
                            )),
                      ],
                    );
                  }),
              ],
            ),
          ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient, // Keep gold for FAB only
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddTransactionScreen(),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.primaryDark,
          icon: const Icon(Icons.add),
          label: Text(
            'Add Transaction',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String title, TransactionFilter filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.accentBlue.withOpacity(0.2)
              : const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.accentBlue.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: isSelected ? AppTheme.accentBlue : Colors.white.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
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
      accountId: 'mock_account', // Mock account ID for display purposes
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
      child: CleanCard(
        padding: const EdgeInsets.all(16),
        child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: transaction.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: transaction.color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(transaction.icon, color: transaction.color, size: 22),
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.category,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.6),
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
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: transaction.amount >= 0 ? AppTheme.accentGreen : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.time,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    ),);
  }
}

class _TransactionExample {
  final String title;
  final String category;
  final double amount;
  final IconData icon;
  final Color color;
  final DateTime date;
  final String time;

  _TransactionExample(this.title, this.category, this.amount, this.icon, this.color, this.date, this.time);
}

