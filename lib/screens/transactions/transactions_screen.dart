// transactions_screen.dart(stratum):

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/box_manager.dart';

enum TransactionFilter { all, income, expenses }

class TransactionsScreen extends StatefulWidget {
  final TransactionFilter? initialFilter;
  
  const TransactionsScreen({Key? key, this.initialFilter}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _selectedFilter = TransactionFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearchVisible = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final int _pageSize = 20;
  
  // All transactions from DB (sorted)
  List<Transaction> _allTransactions = [];
  // Currently displayed transactions (subset)
  List<Transaction> _displayedTransactions = [];
  
  late BoxManager _boxManager;
  late String _userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? 'anonymous_user';
    _boxManager = BoxManager();
    if (widget.initialFilter != null) {
      _selectedFilter = widget.initialFilter!;
    }
    
    _scrollController.addListener(_onScroll);
    _loadTransactions();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    await _boxManager.openAllBoxes(_userId);
    final transactionsBox = _boxManager.getBox<Transaction>(
      BoxManager.transactionsBoxName,
      _userId,
    );
    
    // Load and sort all transactions once
    _allTransactions = transactionsBox.values.toList();
    _allTransactions.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    
    // Apply initial filter/search and take first page
    _applyFiltersAndPagination(reset: true);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || _displayedTransactions.length >= _getFilteredList().length) return;
    
    setState(() => _isLoadingMore = true);
    
    // Simulate small delay for smooth UX
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      _applyFiltersAndPagination(reset: false);
      setState(() => _isLoadingMore = false);
    }
  }

  // Get full filtered list based on current selection
  List<Transaction> _getFilteredList() {
    var transactions = _allTransactions;

    // Apply filter
    switch (_selectedFilter) {
      case TransactionFilter.income:
        transactions = transactions.where((t) => t.type == TransactionType.income).toList();
        break;
      case TransactionFilter.expenses:
        transactions = transactions.where((t) => t.type == TransactionType.expense).toList();
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
               (t.description?.toLowerCase().contains(searchQuery) ?? false) ||
               (t.recipient?.toLowerCase().contains(searchQuery) ?? false) ||
               t.categoryName.toLowerCase().contains(searchQuery);
      }).toList();
    }
    
    return transactions;
  }

  void _applyFiltersAndPagination({bool reset = false}) {
    final filtered = _getFilteredList();
    
    if (reset) {
      _displayedTransactions = filtered.take(_pageSize).toList();
    } else {
      final currentLen = _displayedTransactions.length;
      final nextChunk = filtered.skip(currentLen).take(_pageSize).toList();
      _displayedTransactions.addAll(nextChunk);
    }
    setState(() {});
  }

  List<Transaction> get _filteredTransactions => _displayedTransactions;

  Map<String, List<Transaction>> get _groupedTransactions {
    final grouped = <String, List<Transaction>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final transaction in _displayedTransactions) {
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this screen
    _loadTransactions();
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
            controller: _scrollController,
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
                      onChanged: (_) => _applyFiltersAndPagination(reset: true),
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
                                  _searchController.clear();
                                  _applyFiltersAndPagination(reset: true);
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
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacing48),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_displayedTransactions.isEmpty)
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
                  
                // Loading more indicator
                if (_isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
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
        _applyFiltersAndPagination(reset: true);
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

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppTheme.accentGreen : AppTheme.accentRed;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(transaction: transaction),
          ),
        );
        if (result == true && mounted) {
          _loadTransactions();
        }
      },
      child: CleanCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                transaction.categoryEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.recipient ?? transaction.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.categoryName,
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
                  '${isIncome ? '+' : '-'}KES ${NumberFormat('#,##0').format(transaction.amount)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(transaction.date),
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
    );
  }
}

