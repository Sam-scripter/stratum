import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../theme/app_theme.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/box_manager.dart';
import '../../services/pattern learning/pattern_learning_service.dart';
import '../../models/message_pattern/message_pattern.dart';
import '../../models/account/account_model.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({Key? key, required this.transaction})
    : super(key: key);

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Transaction transaction;
  late BoxManager _boxManager;
  late String _userId;

  final List<TransactionCategory> incomeCategories = [
    TransactionCategory.salary,
    TransactionCategory.freelance,
    TransactionCategory.investment,
    TransactionCategory.gifts,
    TransactionCategory.familySupport,
  ];

  final List<TransactionCategory> expenseCategories = [
    TransactionCategory.utilities,
    TransactionCategory.groceries,
    TransactionCategory.transport,
    TransactionCategory.entertainment,
    TransactionCategory.dining,
    TransactionCategory.health,
    TransactionCategory.shopping,
    TransactionCategory.other,
  ];

  final Map<TransactionCategory, Map<String, dynamic>> categoryInfo = {
    TransactionCategory.salary: {
      'icon': Icons.work,
      'description': 'Regular income from employment or salary payments',
      'examples': 'Monthly paycheck, bi-weekly salary',
    },
    TransactionCategory.freelance: {
      'icon': Icons.business_center,
      'description': 'Income from freelance work or project-based payments',
      'examples': 'Client payments, gig economy earnings',
    },
    TransactionCategory.investment: {
      'icon': Icons.trending_up,
      'description': 'Returns from investments or financial gains',
      'examples': 'Dividends, stock sales, interest income',
    },
    TransactionCategory.gifts: {
      'icon': Icons.card_giftcard,
      'description': 'Money received as gifts from friends or others',
      'examples': 'Birthday gifts, holiday presents, donations',
    },
    TransactionCategory.familySupport: {
      'icon': Icons.family_restroom,
      'description': 'Financial support from family members',
      'examples': 'Parental contributions, allowances, family upkeep',
    },
    TransactionCategory.utilities: {
      'icon': Icons.flash_on,
      'description': 'Bills for essential services',
      'examples': 'Electricity, water, internet, phone',
    },
    TransactionCategory.groceries: {
      'icon': Icons.shopping_cart,
      'description': 'Food and household supplies',
      'examples': 'Supermarket purchases, fresh produce',
    },
    TransactionCategory.transport: {
      'icon': Icons.directions_car,
      'description': 'Transportation costs and vehicle expenses',
      'examples': 'Fuel, public transport, parking, car maintenance',
    },
    TransactionCategory.entertainment: {
      'icon': Icons.movie,
      'description': 'Leisure and recreational activities',
      'examples': 'Movies, games, concerts, hobbies',
    },
    TransactionCategory.dining: {
      'icon': Icons.restaurant,
      'description': 'Food and beverages consumed outside home',
      'examples': 'Restaurants, cafes, takeout, delivery',
    },
    TransactionCategory.health: {
      'icon': Icons.local_hospital,
      'description': 'Medical and healthcare expenses',
      'examples': 'Doctor visits, medications, insurance',
    },
    TransactionCategory.shopping: {
      'icon': Icons.shopping_bag,
      'description': 'General purchases and consumer goods',
      'examples': 'Clothing, electronics, personal items',
    },
    TransactionCategory.other: {
      'icon': Icons.category,
      'description': 'Miscellaneous expenses not covered by other categories',
      'examples': 'Unexpected costs, one-time purchases',
    },
  };

  @override
  void initState() {
    super.initState();
    transaction = widget.transaction;
    _boxManager = BoxManager();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? 'anonymous_user';
  }

  bool _hasChanges = false;

  Future<void> _updateCategory(TransactionCategory newCategory) async {
    if (transaction.category == newCategory) return; // No change
    _hasChanges = true;
    await _boxManager.openAllBoxes(_userId);
    final transactionsBox = _boxManager.getBox<Transaction>(
      BoxManager.transactionsBoxName,
      _userId,
    );

    // Update current transaction
    final updated = Transaction(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type, // Maintain current type
      category: newCategory,
      date: transaction.date,
      description: transaction.description,
      recipient: transaction.recipient,
      mpesaCode: transaction.mpesaCode,
      isRecurring: transaction.isRecurring,
      accountId: transaction.accountId,
      originalSms: transaction.originalSms,
      newBalance: transaction.newBalance,
      reference: transaction.reference,
    );

    transactionsBox.put(updated.id, updated);

    // Learn this pattern if we have original SMS
    if (transaction.originalSms != null &&
        transaction.originalSms!.isNotEmpty) {
      // ... (existing pattern learning logic)
       final pattern = PatternLearningService.learnPattern(
        transaction.originalSms!,
        PatternLearningService.categoryToString(newCategory),
      );

      // Get account type
      final accountsBox = _boxManager.getBox<Account>(
        BoxManager.accountsBoxName,
        _userId,
      );
      final account = accountsBox.values.firstWhere(
        (acc) => acc.id == transaction.accountId,
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

      String accountType = 'MPESA';
      if (account.type == AccountType.Mpesa) {
        accountType = 'MPESA';
      } else if (account.type == AccountType.Bank) {
        accountType = account.name.toUpperCase();
      }

      final messagePattern = MessagePattern(
        id: const Uuid().v4(),
        pattern: pattern,
        category: PatternLearningService.categoryToString(newCategory),
        accountType: accountType,
        lastSeen: DateTime.now(),
      );

      await PatternLearningService.savePattern(messagePattern, _userId);
    }

    setState(() {
      transaction = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Category updated and learned!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Check for similar transactions (Retroactive Update)
    if (transaction.recipient != null && transaction.recipient!.isNotEmpty) {
      _checkForSimilarTransactions(newCategory, transactionsBox);
    }
  }

  Future<void> _checkForSimilarTransactions(
      TransactionCategory newCategory, Box<Transaction> box) async {
    final recipient = transaction.recipient!;
    
    // Find matching transactions (exclude current one)
    final similar = box.values.where((t) => 
      t.id != transaction.id && 
      t.recipient == recipient && 
      t.category != newCategory // Only ones needing update
    ).toList();

    if (similar.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1D1E33),
          title: Text('Update Similar Transactions?', style: GoogleFonts.poppins(color: Colors.white)),
          content: Text(
            'We found ${similar.length} other transactions with recipient "$recipient".\n\nDo you want to update them to "${_getCategoryName(newCategory)}" as well?',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No, just this one'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Yes, update all', style: TextStyle(color: AppTheme.accentGreen)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        int count = 0;
        for (final t in similar) {
          final updatedSim = Transaction(
            id: t.id,
            title: t.title,
            amount: t.amount,
            type: t.type,
            category: newCategory, // Update category
            date: t.date,
            description: t.description,
            recipient: t.recipient,
            mpesaCode: t.mpesaCode,
            isRecurring: t.isRecurring,
            accountId: t.accountId,
            originalSms: t.originalSms,
            newBalance: t.newBalance,
            reference: t.reference,
          );
          box.put(updatedSim.id, updatedSim);
          count++;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count transactions updated!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    }
  }

  Future<void> _toggleTransactionType() async {
    final newType = transaction.type == TransactionType.income 
        ? TransactionType.expense 
        : TransactionType.income;
    
    // Default category for new type
    final newCategory = newType == TransactionType.income 
        ? TransactionCategory.other // or salary
        : TransactionCategory.other;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text('Switch to ${newType == TransactionType.income ? "Income" : "Expense"}?', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          'This will change the transaction type and reset its category.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _boxManager.openAllBoxes(_userId);
    final transactionsBox = _boxManager.getBox<Transaction>(
      BoxManager.transactionsBoxName,
      _userId,
    );

    final updated = Transaction(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      type: newType, // new type
      category: newCategory, // reset category
      date: transaction.date,
      description: transaction.description,
      recipient: transaction.recipient,
      mpesaCode: transaction.mpesaCode,
      isRecurring: transaction.isRecurring,
      accountId: transaction.accountId,
      originalSms: transaction.originalSms,
      newBalance: transaction.newBalance,
      reference: transaction.reference,
    );

    transactionsBox.put(updated.id, updated);
    
    setState(() {
      transaction = updated;
      _hasChanges = true;
    });
  }

  Future<void> _toggleRecurring() async {
    await _boxManager.openAllBoxes(_userId);
    final transactionsBox = _boxManager.getBox<Transaction>(
      BoxManager.transactionsBoxName,
      _userId,
    );

    final updated = Transaction(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type,
      category: transaction.category,
      date: transaction.date,
      description: transaction.description,
      recipient: transaction.recipient,
      mpesaCode: transaction.mpesaCode,
      isRecurring: !transaction.isRecurring,
      accountId: transaction.accountId,
      originalSms: transaction.originalSms,
      newBalance: transaction.newBalance,
      reference: transaction.reference,
    );

    transactionsBox.put(updated.id, updated);

    setState(() {
      transaction = updated;
      _hasChanges = true; // Mark that changes were made
    });
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(
          'Delete Transaction?',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.poppins(color: Colors.white70),
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
      await _boxManager.openAllBoxes(_userId);
      final transactionsBox = _boxManager.getBox<Transaction>(
        BoxManager.transactionsBoxName,
        _userId,
      );
      transactionsBox.delete(transaction.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
        backgroundColor: const Color(0xFF0A0E21),
        title: Text(
          'Transaction Details',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.primaryGold),
            onPressed: _toggleTransactionType,
            tooltip: 'Switch Income/Expense',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card (Red/Green gradient)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isIncome
                      ? [Colors.green, Colors.green.shade700]
                      : [Colors.red, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${isIncome ? '+' : '-'}KES ${NumberFormat('#,##0.00').format(transaction.amount)}',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat(
                      'EEEE, MMMM dd, yyyy • hh:mm a',
                    ).format(transaction.date),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Details
            _buildDetailRow('Account', _getAccountName()),
            _buildDetailRow(
              'Type',
              transaction.type == TransactionType.income ? 'Income' : 'Expense',
            ),
            if (transaction.recipient != null)
              _buildDetailRow('Recipient', transaction.recipient!),
            if (transaction.newBalance != null)
              _buildDetailRow(
                'New Balance',
                'KES ${NumberFormat('#,##0.00').format(transaction.newBalance!)}',
              ),
            if (transaction.reference != null)
              _buildDetailRow('Reference', transaction.reference!),

            const SizedBox(height: 30),

            // Category Selection
            Text(
              'Category',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            // Income Categories
            if (isIncome)
            _buildCategorySection(
              'Income Categories',
              incomeCategories,
              AppTheme.accentGreen,
            ),

            if (isIncome)
            const SizedBox(height: 20),

            // Expense Categories
            if (!isIncome)
            _buildCategorySection(
              'Expense Categories',
              expenseCategories,
              AppTheme.accentRed,
            ),

            const SizedBox(height: 30),

            // Recurring Toggle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recurring Transaction',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Mark as a regular expense',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: transaction.isRecurring,
                    onChanged: (value) => _toggleRecurring(),
                    activeColor: const Color(0xFF667EEA),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Original SMS
            if (transaction.originalSms != null &&
                transaction.originalSms!.isNotEmpty) ...[
              Text(
                'Original Message',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1E33),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  transaction.originalSms!,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white60),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 2,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.familySupport:
        return 'FAMILY SUPPORT';
      case TransactionCategory.gifts:
        return 'GIFTS';
      default:
        return category.toString().split('.').last.toUpperCase();
    }
  }

  Widget _buildCategorySection(
    String title,
    List<TransactionCategory> categories,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final isSelected = cat == transaction.category;
            final info = categoryInfo[cat]!;
            return GestureDetector(
              onTap: () => _updateCategory(cat),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.4, // Two per row
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withOpacity(0.2)
                      : const Color(0xFF1D1E33),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: accentColor, width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          info['icon'],
                          color: isSelected ? accentColor : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getCategoryName(cat),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info['description'],
                      style: GoogleFonts.poppins(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getAccountName() {
    // This would ideally fetch from accounts box, but for now return a placeholder
    return 'Account'; // You can enhance this to fetch actual account name
  }
}
