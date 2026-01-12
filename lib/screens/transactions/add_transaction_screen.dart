import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/account/account_model.dart';
import '../../models/box_manager.dart';

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
  final _uuid = const Uuid();
  final BoxManager _boxManager = BoxManager();

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
  String? _selectedAccountId;
  bool _isLoading = false;
  bool _isLoadingAccounts = true;
  List<Account> _accounts = [];

  bool get _isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
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
      _selectedAccountId = transaction.accountId;
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

  Future<void> _loadAccounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isLoadingAccounts = true);
      }
    });
    
    await _boxManager.openAllBoxes(user.uid);
    
    final accountsBox = _boxManager.getBox<Account>(BoxManager.accountsBoxName, user.uid);
    final accounts = accountsBox.values.toList();
    
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _isLoadingAccounts = false;
          // Set default account if none selected and accounts exist
          if (_selectedAccountId == null && accounts.isNotEmpty) {
            _selectedAccountId = accounts.first.id;
          }
        });
      }
    });
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
            primaryColor: AppTheme.accentBlue,
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentBlue,
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
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedDate = picked);
          }
        });
      }
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: AppTheme.accentBlue,
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentBlue,
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
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedTime = picked);
          }
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _boxManager.openAllBoxes(user.uid);
      final transactionsBox = _boxManager.getBox<Transaction>(
          BoxManager.transactionsBoxName, user.uid);
      final accountsBox = _boxManager.getBox<Account>(
          BoxManager.accountsBoxName, user.uid);

      // Combine date and time
      final transactionDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final amount = double.parse(_amountController.text);
      final transactionId = _isEditing
          ? widget.transactionToEdit!.id
          : _uuid.v4();

      // Get old transaction if editing
      Transaction? oldTransaction;
      Account? account = accountsBox.get(_selectedAccountId!);
      if (account == null) {
        throw Exception('Account not found');
      }

      if (_isEditing) {
        oldTransaction = transactionsBox.get(transactionId);
        // Revert old transaction's effect on balance
        if (oldTransaction != null) {
          if (oldTransaction.type == TransactionType.income) {
            account = account.copyWith(balance: account.balance - oldTransaction.amount);
          } else {
            account = account.copyWith(balance: account.balance + oldTransaction.amount);
          }
        }
      }

      // Create or update transaction
      final transaction = Transaction(
        id: transactionId,
        title: _titleController.text.trim(),
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        date: transactionDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        recipient: _recipientController.text.trim().isEmpty
            ? null
            : _recipientController.text.trim(),
        mpesaCode: _mpesaCodeController.text.trim().isEmpty
            ? null
            : _mpesaCodeController.text.trim(),
        isRecurring: _isRecurring,
        accountId: _selectedAccountId!,
      );

      // Update account balance
      if (_selectedType == TransactionType.income) {
        account = account.copyWith(
          balance: account.balance + amount,
          lastUpdated: DateTime.now(),
        );
      } else {
        account = account.copyWith(
          balance: account.balance - amount,
          lastUpdated: DateTime.now(),
        );
      }

      // Save to Hive
      transactionsBox.put(transactionId, transaction);
      accountsBox.put(_selectedAccountId!, account);

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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _showCategoryDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Category',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: TransactionCategory.values.length,
                  itemBuilder: (context, index) {
                    final category = TransactionCategory.values[index];
                    final isSelected = _selectedCategory == category;
                    final tempTransaction = Transaction(
                      id: '',
                      title: '',
                      amount: 0,
                      type: _selectedType,
                      category: category,
                      date: DateTime.now(),
                      accountId: '',
                    );

                    return ListTile(
                      leading: Text(
                        tempTransaction.categoryEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        tempTransaction.categoryName,
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? AppTheme.accentBlue
                              : AppTheme.primaryLight,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: AppTheme.accentBlue)
                          : null,
                      onTap: () {
                        if (mounted) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _selectedCategory = category);
                            }
                          });
                        }
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.accentBlue),
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
                        onTap: () {
                          if (mounted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => _selectedType = TransactionType.income);
                              }
                            });
                          }
                        },
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
                        onTap: () {
                          if (mounted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => _selectedType = TransactionType.expense);
                              }
                            });
                          }
                        },
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

              // Account Selection
              if (_isLoadingAccounts)
                const Center(child: CircularProgressIndicator())
              else if (_accounts.isEmpty)
                PremiumCard(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Text(
                    'No accounts available. Please add an account first.',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    decoration: InputDecoration(
                      labelText: 'Account',
                      labelStyle: GoogleFonts.poppins(
                        color: AppTheme.textGray,
                      ),
                      prefixIcon: Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.accentBlue,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                    ),
                    dropdownColor: AppTheme.surfaceGray,
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryLight,
                      fontSize: 15,
                    ),
                    items: _accounts.map((account) {
                      return DropdownMenuItem<String>(
                        value: account.id,
                        child: Row(
                          children: [
                            Icon(
                              account.type == AccountType.Mpesa
                                  ? Icons.phone_android
                                  : account.type == AccountType.Bank
                                      ? Icons.account_balance
                                      : Icons.wallet,
                              color: AppTheme.accentBlue,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.spacing8),
                            Text(account.name),
                            const Spacer(),
                            Text(
                              'KES ${account.balance.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => _selectedAccountId = value);
                          }
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an account';
                      }
                      return null;
                    },
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
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than 0';
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
                      color: AppTheme.accentBlue,
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

              // Category Selection (Dropdown Button)
              PremiumCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: _showCategoryDropdown,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: GoogleFonts.poppins(
                        color: AppTheme.textGray,
                      ),
                      prefixIcon: Text(
                        Transaction(
                          id: '',
                          title: '',
                          amount: 0,
                          type: _selectedType,
                          category: _selectedCategory,
                          date: DateTime.now(),
                          accountId: '',
                        ).categoryEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                      suffixIcon: Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    child: Text(
                      Transaction(
                        id: '',
                        title: '',
                        amount: 0,
                        type: _selectedType,
                        category: _selectedCategory,
                        date: DateTime.now(),
                        accountId: '',
                      ).categoryName,
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryLight,
                        fontSize: 15,
                      ),
                    ),
                  ),
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
                            color: AppTheme.accentBlue,
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
                            color: AppTheme.accentBlue,
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
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // M-Pesa Code and Recipient Fields (Optional, shown for transfer category)
              if (_selectedCategory == TransactionCategory.transfer) ...[
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _mpesaCodeController,
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryLight,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: 'M-Pesa Code (Optional)',
                      labelStyle: GoogleFonts.poppins(
                        color: AppTheme.textGray,
                      ),
                      prefixIcon: Icon(
                        Icons.qr_code,
                        color: AppTheme.accentBlue,
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
                      labelText: 'Recipient (Optional)',
                      labelStyle: GoogleFonts.poppins(
                        color: AppTheme.textGray,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppTheme.accentBlue,
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
                          color: AppTheme.accentBlue,
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
                      onChanged: (value) {
                        if (mounted) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _isRecurring = value);
                            }
                          });
                        }
                      },
                      activeColor: AppTheme.accentBlue,
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
