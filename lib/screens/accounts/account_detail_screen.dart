import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/account/account_model.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/box_manager.dart';
import '../../theme/app_theme.dart';
import '../transactions/transaction_detail_screen.dart';
import '../transactions/add_transaction_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;

  const AccountDetailScreen({Key? key, required this.account})
    : super(key: key);

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late BoxManager _boxManager;
  late String _userId;
  List<Transaction> _transactions = [];
  Map<String, List<Transaction>> _groupedTransactions = {};
  bool _isLoading = true;

  // Flattened list for SliverList
  List<dynamic> _flatList = [];
  
  late Account _liveAccount;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? 'anonymous_user';
    _boxManager = BoxManager();
    _liveAccount = widget.account; // Initialize with passed account
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    await _boxManager.openAllBoxes(_userId);
    final transactionsBox = _boxManager.getBox<Transaction>(
      BoxManager.transactionsBoxName,
      _userId,
    );
    final accountsBox = _boxManager.getBox<Account>(
      BoxManager.accountsBoxName,
      _userId,
    );
    
    // Refresh account data from box
    final freshAccount = accountsBox.get(widget.account.id);
    if (freshAccount != null) {
      _liveAccount = freshAccount;
    }

    // Filter transactions for this account
    final allTransactions = transactionsBox.values.toList();
    _transactions = allTransactions
        .where((t) => t.accountId == widget.account.id)
        .toList();

    // Sort by date descending (newest first)
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    // Group transactions by time periods
    _groupedTransactions.clear();
    for (var transaction in _transactions) {
      final key = _getGroupKey(transaction);
      _groupedTransactions.putIfAbsent(key, () => []).add(transaction);
    }
    
    // Flatten for UI
    _flatList.clear();
    _groupedTransactions.forEach((key, transactions) {
      _flatList.add(key); // Header (String)
      _flatList.addAll(transactions); // Items (Transactions)
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: const Text('Delete Account?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete this account and all its transactions.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    await _boxManager.openAllBoxes(_userId);
    
    // 1. Delete Account
    final accountsBox = _boxManager.getBox<Account>(BoxManager.accountsBoxName, _userId);
    await accountsBox.delete(widget.account.id);
    
    // 2. Delete Transactions
    final transactionsBox = _boxManager.getBox<Transaction>(BoxManager.transactionsBoxName, _userId);
    final toDelete = transactionsBox.values.where((t) => t.accountId == widget.account.id).map((t) => t.id).toList();
    await transactionsBox.deleteAll(toDelete);
    
    if (mounted) {
      Navigator.pop(context, true); // Return true to trigger refresh
    }
  }

  String _getGroupKey(Transaction transaction) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    final difference = today.difference(transactionDate).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference <= 7) return 'This Week';
    if (transactionDate.month == now.month && transactionDate.year == now.year)
      return 'This Month';
    return DateFormat('MMM yyyy').format(transaction.date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            )
          : CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: const Color(0xFF0A1628),
                  pinned: true,
                  expandedHeight: 0, 
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    _liveAccount.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  actions: [
                     if (_liveAccount.isAutomated)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryGold.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'AUTO',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      
                    // Delete Option
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: const Color(0xFF1A2332),
                      onSelected: (value) {
                         if (value == 'delete') _confirmDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Account', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),

                // Balance Card
                SliverToBoxAdapter(
                  child: _buildBalanceCard(),
                ),
                
                // Transactions Header
                if (_transactions.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'All Transactions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Transactions List
                if (_transactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _flatList[index];
                          if (item is String) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
                              child: Text(
                                item,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGold,
                                ),
                              ),
                            );
                          } else if (item is Transaction) {
                            return Column(
                              children: [
                                _buildTransactionItem(item),
                                const SizedBox(height: 8), 
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        childCount: _flatList.length,
                      ),
                    ),
                  ),
                  
                 // Bottom padding
                 const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                preSelectedAccount: _liveAccount,
              ),
            ),
          );
          if (result == true && mounted) {
            _loadTransactions();
          }
        },
        backgroundColor: AppTheme.accentBlue,
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

  Widget _buildBalanceCard() {
    final isLiability = _liveAccount.type == AccountType.Liability;
    final accentColor = isLiability
        ? AppTheme.accentRed
        : (_liveAccount.type == AccountType.Mpesa
              ? const Color(0xFF43B02A)
              : AppTheme.accentBlue);

    // Calculate Income and Expense
    final totalIncome = _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Current Balance',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'KES ${_liveAccount.balance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Income', totalIncome, AppTheme.accentGreen),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.1),
              ),
              _buildSummaryItem('Expense', totalExpense, AppTheme.accentRed),
            ],
          ),
          const SizedBox(height: 16),

          // Disclaimer Info
            Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.white30, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Income/Expense based on detected transactions',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white30,
                    fontStyle: FontStyle.italic
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'KES ${NumberFormat('#,##0').format(amount)}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transactions will appear here once detected',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    // ... item building logic (same as before but maybe slightly polished cards)
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppTheme.accentGreen : AppTheme.accentRed;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
         border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TransactionDetailScreen(transaction: transaction),
            ),
          ).then((result) {
            // Always reload when returning to ensure UI is up to date
            _loadTransactions();
          });
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isIncome
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 20,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          transaction.recipient ?? transaction.title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('HH:mm').format(transaction.date),
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              if (transaction.description != null && transaction.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  transaction.description!,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 10,
                    fontStyle: FontStyle.italic
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}KES ${NumberFormat('#,##0').format(transaction.amount)}',
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              transaction.categoryName.toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
