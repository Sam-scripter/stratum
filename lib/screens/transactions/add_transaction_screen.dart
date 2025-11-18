import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/transaction/transaction_model.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transactionToEdit;

  const AddTransactionScreen({
    Key? key,
    this.transactionToEdit,
  }) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _mpesaCodeController;
  late final TextEditingController _recipientController;

  late TransactionType _selectedType;
  late TransactionCategory _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _isRecurring;
  bool _isLoading = false;
  bool get _isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final transaction = widget.transactionToEdit!;
      _titleController = TextEditingController(text: transaction.title);
      _amountController = TextEditingController(text: transaction.amount.toStringAsFixed(2));
      _descriptionController = TextEditingController(text: transaction.description ?? '');
      _mpesaCodeController = TextEditingController(text: transaction.mpesaCode ?? '');
      _recipientController = TextEditingController(text: transaction.recipient ?? '');
      _selectedType = transaction.type;
      _selectedCategory = transaction.category;
      _selectedDate = transaction.date;
      _selectedTime = TimeOfDay.fromDateTime(transaction.date);
      _isRecurring = transaction.isRecurring;
    } else {
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
      _mpesaCodeController = TextEditingController();
      _recipientController = TextEditingController();
      _selectedType = TransactionType.expense;
      _selectedCategory = TransactionCategory.other;
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _isRecurring = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _mpesaCodeController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
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
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // Simulate saving transaction
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing
                  ? 'Transaction updated successfully!'
                  : 'Transaction added successfully!'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Transaction' : 'Add Transaction',
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
              // Transaction Type Toggle
              PremiumCard(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = TransactionType.income),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacing16),
                          decoration: BoxDecoration(
                            gradient: _selectedType == TransactionType.income
                                ? AppTheme.goldGradient
                                : null,
                            color: _selectedType == TransactionType.income
                                ? null
                                : AppTheme.surfaceGray,
                            borderRadius: BorderRadius.circular(AppTheme.radius12),
                            border: Border.all(
                              color: _selectedType == TransactionType.income
                                  ? AppTheme.primaryGold
                                  : AppTheme.borderGray,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: _selectedType == TransactionType.income
                                    ? AppTheme.primaryDark
                                    : AppTheme.accentGreen,
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              Text(
                                'Income',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: _selectedType == TransactionType.income
                                      ? AppTheme.primaryDark
                                      : AppTheme.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = TransactionType.expense),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacing16),
                          decoration: BoxDecoration(
                            gradient: _selectedType == TransactionType.expense
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.accentRed.withOpacity(0.8),
                                      AppTheme.accentRed,
                                    ],
                                  )
                                : null,
                            color: _selectedType == TransactionType.expense
                                ? null
                                : AppTheme.surfaceGray,
                            borderRadius: BorderRadius.circular(AppTheme.radius12),
                            border: Border.all(
                              color: _selectedType == TransactionType.expense
                                  ? AppTheme.accentRed
                                  : AppTheme.borderGray,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                color: _selectedType == TransactionType.expense
                                    ? Colors.white
                                    : AppTheme.accentRed,
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              Text(
                                'Expense',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: _selectedType == TransactionType.expense
                                      ? Colors.white
                                      : AppTheme.accentRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Amount Field
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (KES)',
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
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Title Field
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Icon(
                      Icons.title,
                      color: AppTheme.primaryGold,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
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
                      children: TransactionCategory.values.map((category) {
                        final isSelected = _selectedCategory == category;
                        final transaction = Transaction(
                          id: '',
                          title: '',
                          amount: 0,
                          type: TransactionType.expense,
                          category: category,
                          date: DateTime.now(),
                        );
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = category),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing12,
                              vertical: AppTheme.spacing8,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? (_selectedType == TransactionType.income
                                      ? AppTheme.goldGradient
                                      : LinearGradient(
                                          colors: [
                                            AppTheme.accentRed.withOpacity(0.8),
                                            AppTheme.accentRed,
                                          ],
                                        ))
                                  : null,
                              color: isSelected ? null : AppTheme.surfaceGray,
                              borderRadius: BorderRadius.circular(AppTheme.radius12),
                              border: Border.all(
                                color: isSelected
                                    ? (isSelected ? AppTheme.primaryGold : AppTheme.accentRed)
                                    : AppTheme.borderGray,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  transaction.categoryEmoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                Text(
                                  transaction.categoryName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? (isSelected
                                            ? AppTheme.primaryDark
                                            : Colors.white)
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

              // Date and Time Selection
              Row(
                children: [
                  Expanded(
                    child: PremiumCard(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      onTap: _selectDate,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textGray,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDate),
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.calendar_today,
                            color: AppTheme.primaryGold,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: PremiumCard(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      onTap: _selectTime,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textGray,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing4),
                              Text(
                                _selectedTime.format(context),
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.access_time,
                            color: AppTheme.primaryGold,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Description Field
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Icon(
                        Icons.description_outlined,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // M-Pesa Fields (Optional)
              if (_selectedCategory == TransactionCategory.mpesa) ...[
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _mpesaCodeController,
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryLight,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: 'M-Pesa Code',
                      labelStyle: GoogleFonts.poppins(
                        color: AppTheme.textGray,
                      ),
                      prefixIcon: Icon(
                        Icons.qr_code,
                        color: AppTheme.primaryGold,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _recipientController,
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryLight,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Recipient',
                      labelStyle: GoogleFonts.poppins(
                        color: AppTheme.textGray,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppTheme.primaryGold,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
              ],

              // Recurring Transaction Toggle
              PremiumCard(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          color: AppTheme.primaryGold,
                          size: 24,
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recurring Transaction',
                              style: GoogleFonts.poppins(
                                color: AppTheme.primaryLight,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Repeat this transaction',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _isRecurring,
                      onChanged: (value) => setState(() => _isRecurring = value),
                      activeColor: AppTheme.primaryGold,
                    ),
                  ],
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
                          _isEditing ? 'Update Transaction' : 'Add Transaction',
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

