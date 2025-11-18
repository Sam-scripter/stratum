import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/investment/investment_model.dart';

class AddInvestmentScreen extends StatefulWidget {
  final Investment? investmentToEdit;
  final InvestmentOpportunity? opportunity;

  const AddInvestmentScreen({
    Key? key,
    this.investmentToEdit,
    this.opportunity,
  }) : super(key: key);

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _investedAmountController;
  late final TextEditingController _currentValueController;
  late final TextEditingController _returnRateController;
  late final TextEditingController _providerController;
  late final TextEditingController _notesController;
  late final TextEditingController _referenceController;

  late InvestmentType _selectedType;
  late DateTime _selectedDate;
  bool _isLoading = false;
  bool get _isEditing => widget.investmentToEdit != null;
  bool get _isFromOpportunity => widget.opportunity != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final investment = widget.investmentToEdit!;
      _nameController = TextEditingController(text: investment.name);
      _investedAmountController = TextEditingController(text: investment.investedAmount.toStringAsFixed(2));
      _currentValueController = TextEditingController(text: investment.currentValue.toStringAsFixed(2));
      _returnRateController = TextEditingController(text: investment.returnRate.toStringAsFixed(2));
      _providerController = TextEditingController(text: investment.provider ?? '');
      _notesController = TextEditingController(text: investment.notes ?? '');
      _referenceController = TextEditingController(text: investment.referenceNumber ?? '');
      _selectedType = investment.type;
      _selectedDate = investment.dateInvested;
    } else if (_isFromOpportunity) {
      final opportunity = widget.opportunity!;
      _nameController = TextEditingController(text: opportunity.name);
      _investedAmountController = TextEditingController();
      _currentValueController = TextEditingController();
      _returnRateController = TextEditingController(text: opportunity.expectedReturn.replaceAll('%', '').replaceAll(' p.a.', '').trim());
      _providerController = TextEditingController(text: opportunity.provider ?? '');
      _notesController = TextEditingController(text: opportunity.description ?? '');
      _referenceController = TextEditingController();
      _selectedType = opportunity.type;
      _selectedDate = DateTime.now();
    } else {
      _nameController = TextEditingController();
      _investedAmountController = TextEditingController();
      _currentValueController = TextEditingController();
      _returnRateController = TextEditingController();
      _providerController = TextEditingController();
      _notesController = TextEditingController();
      _referenceController = TextEditingController();
      _selectedType = InvestmentType.moneyMarket;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _investedAmountController.dispose();
    _currentValueController.dispose();
    _returnRateController.dispose();
    _providerController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
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

  String _getTypeName(InvestmentType type) {
    switch (type) {
      case InvestmentType.moneyMarket:
        return 'Money Market';
      case InvestmentType.sacco:
        return 'SACCO Shares';
      case InvestmentType.bonds:
        return 'Government Bonds';
      case InvestmentType.stocks:
        return 'Stocks';
      case InvestmentType.realEstate:
        return 'Real Estate';
      case InvestmentType.other:
        return 'Other';
    }
  }

  String _getTypeEmoji(InvestmentType type) {
    switch (type) {
      case InvestmentType.moneyMarket:
        return '💰';
      case InvestmentType.sacco:
        return '🏦';
      case InvestmentType.bonds:
        return '📜';
      case InvestmentType.stocks:
        return '📈';
      case InvestmentType.realEstate:
        return '🏠';
      case InvestmentType.other:
        return '💼';
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate saving investment
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing
                  ? 'Investment updated successfully!'
                  : 'Investment added successfully!'),
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
          _isEditing
              ? 'Edit Investment'
              : _isFromOpportunity
                  ? 'Add Investment'
                  : 'Add Investment',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Investment Type Selection
              Text(
                'Investment Type',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Wrap(
                spacing: AppTheme.spacing8,
                runSpacing: AppTheme.spacing8,
                children: InvestmentType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: AppTheme.spacing12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGold.withOpacity(0.2)
                            : AppTheme.surfaceGray,
                        borderRadius: BorderRadius.circular(AppTheme.radius12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGold
                              : AppTheme.borderGray.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getTypeEmoji(type),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Text(
                            _getTypeName(type),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primaryGold
                                  : AppTheme.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Investment Name
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Investment Name',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.primaryGold,
                    ),
                    hintText: 'e.g., CIC Money Market Fund',
                    hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray.withOpacity(0.5),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter investment name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Invested Amount
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _investedAmountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Invested Amount',
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
                    hintText: '0.00',
                    hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray.withOpacity(0.5),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter invested amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Current Value
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _currentValueController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Current Value',
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
                    hintText: '0.00',
                    hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray.withOpacity(0.5),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter current value';
                    }
                    final currentValue = double.tryParse(value);
                    if (currentValue == null || currentValue <= 0) {
                      return 'Please enter a valid value';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Return Rate
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _returnRateController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Return Rate (%)',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Icon(
                      Icons.percent,
                      color: AppTheme.primaryGold,
                    ),
                    suffixText: '%',
                    suffixStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    hintText: '0.00',
                    hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray.withOpacity(0.5),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter return rate';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Date Invested
              PremiumCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date Invested',
                      labelStyle: GoogleFonts.poppins(
                        color: AppTheme.textGray,
                      ),
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: AppTheme.primaryGold,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryLight,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Provider/Bank
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _providerController,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Provider/Bank (Optional)',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Icon(
                      Icons.business,
                      color: AppTheme.primaryGold,
                    ),
                    hintText: 'e.g., CIC Asset Management',
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

              // Reference Number
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _referenceController,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Reference Number (Optional)',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Icon(
                      Icons.qr_code,
                      color: AppTheme.primaryGold,
                    ),
                    hintText: 'e.g., ACC-123456',
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

              // Notes
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
                    prefixIcon: Icon(
                      Icons.note_outlined,
                      color: AppTheme.primaryGold,
                    ),
                    hintText: 'Additional notes about this investment',
                    hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray.withOpacity(0.5),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing32),

              // Submit Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDark),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Investment' : 'Add Investment',
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

