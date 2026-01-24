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
import 'package:provider/provider.dart';
import '../../repositories/financial_repository.dart';

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
  bool _hasChanges = false;
  
  final List<TransactionCategory> incomeCategories = [
    TransactionCategory.salary,
    TransactionCategory.freelance,
    TransactionCategory.investment,
    TransactionCategory.gifts,
    TransactionCategory.familySupport,
    TransactionCategory.transfer,
    TransactionCategory.other,
  ];

  final List<TransactionCategory> expenseCategories = [
    TransactionCategory.utilities,
    TransactionCategory.groceries,
    TransactionCategory.transport,
    TransactionCategory.entertainment,
    TransactionCategory.dining,
    TransactionCategory.health,
    TransactionCategory.shopping,
    TransactionCategory.investment,
    TransactionCategory.transfer,
    TransactionCategory.general,
    TransactionCategory.other,
  ];

  final Map<TransactionCategory, Map<String, dynamic>> categoryInfo = {
    TransactionCategory.salary: {'icon': Icons.attach_money, 'description': 'Monthly salary'},
    TransactionCategory.freelance: {'icon': Icons.laptop_mac, 'description': 'Freelance/Business'},
    TransactionCategory.investment: {'icon': Icons.trending_up, 'description': 'Returns/Savings'},
    TransactionCategory.gifts: {'icon': Icons.card_giftcard, 'description': 'Received gifts'},
    TransactionCategory.familySupport: {'icon': Icons.family_restroom, 'description': 'Family support'},
    TransactionCategory.transfer: {'icon': Icons.swap_horiz, 'description': 'Transfers'},
    TransactionCategory.other: {'icon': Icons.category, 'description': 'Other'},
    TransactionCategory.utilities: {'icon': Icons.flash_on, 'description': 'Bills & Utilities'},
    TransactionCategory.groceries: {'icon': Icons.shopping_basket, 'description': 'Food & Supplies'},
    TransactionCategory.transport: {'icon': Icons.directions_bus, 'description': 'Commute/Fuel'},
    TransactionCategory.entertainment: {'icon': Icons.movie, 'description': 'Fun & Leisure'},
    TransactionCategory.dining: {'icon': Icons.restaurant, 'description': 'Eating out'},
    TransactionCategory.health: {'icon': Icons.local_hospital, 'description': 'Medical'},
    TransactionCategory.shopping: {'icon': Icons.shopping_bag, 'description': 'General shopping'},
    TransactionCategory.general: {'icon': Icons.receipt, 'description': 'General Expenses'},
  };

  @override
  void initState() {
    super.initState();
    transaction = widget.transaction;
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? 'anonymous_user';
    _boxManager = BoxManager();
  }

  void _updateCategory(TransactionCategory newCategory) async {
    setState(() {
      transaction.category = newCategory;
      _hasChanges = true;
    });
    await transaction.save();
    
    // Learn pattern if possible
    await _learnPattern(newCategory);

    // Trigger Reconciliation
    if (mounted) {
       await context.read<FinancialRepository>().reconcileAccount(transaction.accountId);
    }
    
    // Check for similar transactions to batch update
    if (transaction.recipient != null && transaction.recipient!.isNotEmpty) {
       _checkForSimilarTransactions(newCategory);
    }
  }

  Future<void> _learnPattern(TransactionCategory category) async {
    if (transaction.originalSms != null && transaction.originalSms!.isNotEmpty) {
      final patternStr = PatternLearningService.learnPattern(transaction.originalSms!, '');
      final pattern = MessagePattern(
        id: const Uuid().v4(),
        pattern: patternStr,
        category: PatternLearningService.categoryToString(category),
        accountType: 'UNKNOWN', // Ideally get from account but not critical for category match
        lastSeen: DateTime.now(),
      );
      await PatternLearningService.savePattern(pattern, _userId);
      print('Learned pattern for category: $category');
    }
  }

  Future<void> _checkForSimilarTransactions(TransactionCategory newCategory) async {
    await _boxManager.openAllBoxes(_userId);
    final transactionsBox = _boxManager.getBox<Transaction>(
      BoxManager.transactionsBoxName,
      _userId,
    );

    final recipientToCheck = transaction.recipient!.toUpperCase().trim();
    
    // Find candidates: Same recipient, different category, NOT the current transaction
    final candidates = transactionsBox.values.where((t) {
      if (t.id == transaction.id) return false; // Skip current
      if (t.category == newCategory) return false; // Already matches
      if (t.recipient == null) return false;
      
      return t.recipient!.toUpperCase().trim() == recipientToCheck;
    }).toList();

    if (candidates.isEmpty) return;

    if (!mounted) return;

    // Show Dialog
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: Text(
          'Update Similar Transactions?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We found ${candidates.length} other transactions with recipient:',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              transaction.recipient!,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Do you want to categorize them all as ${_getCategoryName(newCategory)}?',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No, Just This One',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.primaryDark,
            ),
            child: Text(
              'Yes, Update All',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldUpdate == true) {
      // Perform Batch Update
      int updatedCount = 0;
      for (final candidate in candidates) {
        candidate.category = newCategory;
        await candidate.save();
        updatedCount++;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated $updatedCount transactions'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    }
  }

  void _toggleTransactionType() async {
    final newType = transaction.type == TransactionType.income 
        ? TransactionType.expense 
        : TransactionType.income;
    
    setState(() {
      transaction.type = newType;
      // Reset category to 'other' or keep if valid? 
      // Safest is to switch to 'other' of the new type to avoid mismatch
      transaction.category = TransactionCategory.other;
      _hasChanges = true;
    });
    await transaction.save();
    
    if (mounted) {
       await context.read<FinancialRepository>().reconcileAccount(transaction.accountId);
    }
  }

  void _toggleRecurring() async {
    setState(() {
      transaction.isRecurring = !transaction.isRecurring;
      _hasChanges = true;
    });
    await transaction.save();
  }

  void _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: Text('Delete Transaction?', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          'This cannot be undone.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final accountId = transaction.accountId;
      await transaction.delete();
      
      if (mounted) {
         await context.read<FinancialRepository>().reconcileAccount(accountId);
         Navigator.pop(context, true); // Return true to indicate change/deletion
      }
    }
  }

  String _getCategoryName(TransactionCategory category) {
    if (categoryInfo.containsKey(category)) {
        // Use map description if available or formatted enum
    }
    return category.toString().split('.').last.toUpperCase();
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

            const SizedBox(height: 24),
            
            // Prominent Type Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                         if (!isIncome) _toggleTransactionType();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isIncome ? Colors.green.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isIncome ? Border.all(color: Colors.green) : null,
                        ),
                        child: Center(
                          child: Text(
                            'INCOME',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: isIncome ? Colors.green : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (isIncome) _toggleTransactionType();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isIncome ? Colors.red.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: !isIncome ? Border.all(color: Colors.red) : null,
                        ),
                        child: Center(
                          child: Text(
                            'EXPENSE',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: !isIncome ? Colors.red : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Details
            _buildDetailRow('Account', _getAccountName()),
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

            // Show relevant categories based on CURRENT type
            if (isIncome)
            _buildCategorySection(
              'Income Categories',
              incomeCategories,
              AppTheme.accentGreen,
            )
            else
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
            // Fallback for missing category info
            final info = categoryInfo[cat] ?? {'icon': Icons.help_outline, 'description': ''};
            
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
    return 'Account'; 
  }
}
