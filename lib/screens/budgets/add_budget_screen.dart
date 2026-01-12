import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/budget/budget_model.dart';

class AddBudgetScreen extends StatefulWidget {
  final BudgetDetail? budgetToEdit;

  const AddBudgetScreen({
    Key? key,
    this.budgetToEdit,
  }) : super(key: key);

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _budgetAmountController;
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  late TransactionCategory _selectedCategory;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;
  bool get _isEditing => widget.budgetToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final budget = widget.budgetToEdit!;
      _budgetAmountController = TextEditingController(text: budget.budgetAmount.toStringAsFixed(2));
      _nameController = TextEditingController(text: budget.name);
      _notesController = TextEditingController(text: budget.notes ?? '');
      _selectedCategory = budget.category;
      _startDate = budget.startDate;
      _endDate = budget.endDate;
    } else {
      _budgetAmountController = TextEditingController();
      _nameController = TextEditingController();
      _notesController = TextEditingController();
      _selectedCategory = TransactionCategory.groceries;
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _budgetAmountController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: AppTheme.primaryGold,
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryGold,
              onPrimary: AppTheme.primaryDark,
              surface: AppTheme.surfaceGray,
              onSurface: AppTheme.primaryLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
      if (_endDate.isBefore(_startDate)) {
        setState(() => _endDate = _startDate.add(const Duration(days: 30)));
      }
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: AppTheme.primaryGold,
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryGold,
              onPrimary: AppTheme.primaryDark,
              surface: AppTheme.surfaceGray,
              onSurface: AppTheme.primaryLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate && picked.isAfter(_startDate)) {
      setState(() => _endDate = picked);
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // Simulate saving budget
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing
                  ? 'Budget updated successfully!'
                  : 'Budget created successfully!'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      });
    }
  }

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
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Budget' : 'Create Budget',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryGold),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Budget Amount Field
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _budgetAmountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Budget Amount (KES)',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(AppTheme.spacing12),
                      padding: const EdgeInsets.all(AppTheme.spacing8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radius8),
                      ),
                      child: Text(
                        'KES',
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a budget amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Budget Name Field
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Budget Name (Optional)',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Icon(
                      Icons.label_outline,
                      color: AppTheme.primaryGold,
                    ),
                    hintText: 'e.g., Monthly Groceries',
                    hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray.withOpacity(0.5),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Category Selection
              PremiumCard(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    Wrap(
                      spacing: AppTheme.spacing8,
                      runSpacing: AppTheme.spacing8,
                      children: TransactionCategory.values
                          .where((cat) => cat != TransactionCategory.salary &&
                              cat != TransactionCategory.freelance &&
                              cat != TransactionCategory.investment)
                          .map((category) {
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = category),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing12,
                              vertical: AppTheme.spacing8,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppTheme.goldGradient : null,
                              color: isSelected ? null : AppTheme.surfaceGray,
                              borderRadius: BorderRadius.circular(AppTheme.radius12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryGold
                                    : AppTheme.borderGray,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getCategoryEmoji(category),
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                Text(
                                  _getCategoryName(category),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.primaryDark
                                        : AppTheme.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Date Range Selection
              Row(
                children: [
                  Expanded(
                    child: PremiumCard(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      onTap: _selectStartDate,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textGray,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: AppTheme.primaryGold,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: PremiumCard(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      onTap: _selectEndDate,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textGray,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: AppTheme.primaryGold,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Notes Field
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Icon(
                        Icons.notes_outlined,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Submit Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryDark,
                            ),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Budget' : 'Create Budget',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}

