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

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? 'anonymous_user';
    _boxManager = BoxManager();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    await _boxManager.openAllBoxes(_userId);
    final transactionsBox = _boxManager.getBox<Transaction>(
      BoxManager.transactionsBoxName,
      _userId,
    );

    // Filter transactions for this account
    final allTransactions = transactionsBox.values.toList();
    print(
      'Account Detail: Loading transactions for account ${widget.account.name} (ID: ${widget.account.id})',
    );
    print('Total transactions in box: ${allTransactions.length}');

    _transactions = allTransactions
        .where((t) => t.accountId == widget.account.id)
        .toList();

    print(
      'Filtered transactions for ${widget.account.name}: ${_transactions.length}',
    );
    if (_transactions.isEmpty && allTransactions.isNotEmpty) {
      // Debug: Check what account IDs exist
      final accountIds = allTransactions.map((t) => t.accountId).toSet();
      print('Available account IDs in transactions: $accountIds');

      // Debug: Check account details
      final accountsBox = _boxManager.getBox<Account>(
        BoxManager.accountsBoxName,
        _userId,
      );
      final allAccounts = accountsBox.values.toList();
      print(
        'All accounts: ${allAccounts.map((a) => '${a.name} (${a.id}) - sender: ${a.senderAddress}').toList()}',
      );

      // Check if there are transactions with this account's sender address
      final transactionsWithMatchingSender = allTransactions.where((t) {
        final account = allAccounts.firstWhere(
          (a) => a.id == t.accountId,
          orElse: () => Account(
            id: '',
            name: '',
            balance: 0,
            type: AccountType.Bank,
            lastUpdated: DateTime.now(),
            senderAddress: '',
            isAutomated: false,
          ),
        );
        return account.senderAddress.toUpperCase() ==
            widget.account.senderAddress.toUpperCase();
      }).toList();
      print(
        'Transactions with matching sender address (${widget.account.senderAddress}): ${transactionsWithMatchingSender.length}',
      );
    }

    // Sort by date descending (newest first)
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    // Group transactions by time periods
    _groupedTransactions.clear();
    for (var transaction in _transactions) {
      final key = _getGroupKey(transaction);
      _groupedTransactions.putIfAbsent(key, () => []).add(transaction);
    }

    setState(() {
      _isLoading = false;
    });
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.account.name,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (widget.account.isAutomated)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: AppTheme.primaryGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AUTO',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            )
          : Column(
              children: [
                // Balance Card
                _buildBalanceCard(),
                const SizedBox(height: 20),
                // Transactions List
                Expanded(
                  child: _transactions.isEmpty
                      ? _buildEmptyState()
                      : _buildTransactionsList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                preSelectedAccount: widget.account,
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
    final isLiability = widget.account.type == AccountType.Liability;
    final accentColor = isLiability
        ? AppTheme.accentRed
        : (widget.account.type == AccountType.Mpesa
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
            'KES ${widget.account.balance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
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

  Widget _buildTransactionsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'All Transactions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _groupedTransactions.length,
              itemBuilder: (context, index) {
                final groupKey = _groupedTransactions.keys.elementAt(index);
                final groupTransactions = _groupedTransactions[groupKey]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      child: Text(
                        '$groupKey (${groupTransactions.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                    ),
                    // Transactions in this group
                    ...groupTransactions.map(
                      (transaction) => Column(
                        children: [
                          _buildTransactionItem(transaction),
                          if (groupTransactions.last != transaction)
                            const Divider(color: Color(0xFF0A1628), height: 1),
                        ],
                      ),
                    ),
                    // Divider between groups
                    if (index < _groupedTransactions.length - 1)
                      Container(height: 8, color: const Color(0xFF0A1628)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppTheme.accentGreen : AppTheme.accentRed;

    return ListTile(
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
          size: 20,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        transaction.recipient ?? transaction.title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          DateFormat('MMM dd, yyyy • HH:mm').format(transaction.date),
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            transaction.categoryName.toUpperCase(),
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.4),
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
