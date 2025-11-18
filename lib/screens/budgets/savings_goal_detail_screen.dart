import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import 'package:intl/intl.dart';
import 'edit_savings_goal_screen.dart';

class SavingsGoalDetailScreen extends StatefulWidget {
  final String name;
  final double targetAmount;
  final double savedAmount;
  final Color color;
  final DateTime? targetDate;

  const SavingsGoalDetailScreen({
    Key? key,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.color,
    this.targetDate,
  }) : super(key: key);

  @override
  State<SavingsGoalDetailScreen> createState() => _SavingsGoalDetailScreenState();
}

class _SavingsGoalDetailScreenState extends State<SavingsGoalDetailScreen> {
  late String _name;
  late double _targetAmount;
  late double _savedAmount;
  late Color _color;
  late DateTime? _targetDate;
  late List<_Contribution> _contributions;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _targetAmount = widget.targetAmount;
    _savedAmount = widget.savedAmount;
    _color = widget.color;
    _targetDate = widget.targetDate;
    _contributions = [
      _Contribution(DateTime.now().subtract(const Duration(days: 2)), 5000, 'Monthly savings'),
      _Contribution(DateTime.now().subtract(const Duration(days: 15)), 8000, 'Bonus allocation'),
      _Contribution(DateTime.now().subtract(const Duration(days: 30)), 10000, 'Initial deposit'),
      _Contribution(DateTime.now().subtract(const Duration(days: 45)), 9000, 'Extra income'),
    ];
    // Calculate saved amount from contributions
    _savedAmount = _contributions.fold<double>(0, (sum, c) => sum + c.amount);
    // Sort contributions by date (most recent first)
    _contributions.sort((a, b) => b.date.compareTo(a.date));
  }

  void _addContribution(double amount, String description) {
    setState(() {
      _contributions.insert(0, _Contribution(DateTime.now(), amount, description));
      _savedAmount += amount;
      // Keep contributions sorted by date (most recent first)
      _contributions.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void _editGoal() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSavingsGoalScreen(
          name: _name,
          targetAmount: _targetAmount,
          targetDate: _targetDate,
          color: _color,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _name = result['name'] as String;
        _targetAmount = result['targetAmount'] as double;
        _targetDate = result['targetDate'] as DateTime?;
        _color = result['color'] as Color;
      });
    }
  }

  void _showAddContributionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddContributionBottomSheet(
        onAdd: _addContribution,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _savedAmount / _targetAmount;
    final remaining = _targetAmount - _savedAmount;
    final daysRemaining = _targetDate != null
        ? _targetDate!.difference(DateTime.now()).inDays
        : null;
    final monthlyNeeded = daysRemaining != null && daysRemaining > 0
        ? remaining / (daysRemaining / 30)
        : null;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: GradientText(
          text: 'SAVINGS GOAL',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGold),
            onPressed: _editGoal,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated particles background
          Positioned.fill(
            child: AnimatedParticles(
              particleCount: 10,
              color: AppTheme.primaryGold.withOpacity(0.2),
              size: 2.0,
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal Header Card
                PremiumCard(
                  isGlassmorphic: true,
                  hasGlow: true,
                  padding: const EdgeInsets.all(AppTheme.spacing24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GradientText(
                                  text: _name.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                if (_targetDate != null) ...[
                                  const SizedBox(height: AppTheme.spacing8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: AppTheme.platinum.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: AppTheme.spacing8),
                                      Text(
                                        'Target: ${DateFormat('MMM dd, yyyy').format(_targetDate!)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: AppTheme.platinum.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing16,
                              vertical: AppTheme.spacing8,
                            ),
                            decoration: BoxDecoration(
                              color: _color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppTheme.radius20),
                              border: Border.all(
                                color: _color.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                color: _color,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing24),
                      // Progress Circle
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background circle
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.borderGray.withOpacity(0.3),
                                    width: 12,
                                  ),
                                ),
                              ),
                              // Progress circle
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  value: percentage > 1 ? 1 : percentage,
                                  strokeWidth: 12,
                                  valueColor: AlwaysStoppedAnimation<Color>(_color),
                                  backgroundColor: Colors.transparent,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              // Center content
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GradientText(
                                    text: 'KES ${_savedAmount.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacing4),
                                  Text(
                                    'of ${_targetAmount.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppTheme.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing24),
                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Remaining',
                              'KES ${remaining.toStringAsFixed(0)}',
                              Icons.trending_up,
                              AppTheme.accentGreen,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          if (monthlyNeeded != null)
                            Expanded(
                              child: _buildStatCard(
                                'Monthly Need',
                                'KES ${monthlyNeeded.toStringAsFixed(0)}',
                                Icons.calendar_month,
                                AppTheme.accentBlue,
                              ),
                            ),
                          if (daysRemaining != null)
                            Expanded(
                              child: _buildStatCard(
                                'Days Left',
                                '$daysRemaining',
                                Icons.access_time,
                                AppTheme.accentOrange,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),

                // Contribution History
                GradientText(
                  text: 'CONTRIBUTION HISTORY',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                ..._contributions.map((contribution) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                      child: PremiumCard(
                        isGlassmorphic: true,
                        padding: const EdgeInsets.all(AppTheme.spacing16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacing12),
                              decoration: BoxDecoration(
                                color: _color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radius12),
                                border: Border.all(
                                  color: _color.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.add_circle,
                                color: _color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contribution.description,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: AppTheme.primaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacing4),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(contribution.date),
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.textGray,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GradientText(
                              text: 'KES ${contribution.amount.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: AppTheme.spacing24),

                // Insights & Recommendations
                PremiumCard(
                  isGlassmorphic: true,
                  padding: const EdgeInsets.all(AppTheme.spacing20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacing12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(AppTheme.radius12),
                            ),
                            child: const Icon(
                              Icons.lightbulb,
                              color: AppTheme.primaryDark,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          GradientText(
                            text: 'AI INSIGHTS',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      _buildInsightItem(
                        'You\'re on track!',
                        'At your current saving rate, you\'ll reach your goal ${daysRemaining != null && monthlyNeeded != null && monthlyNeeded <= remaining / 3 ? 'ahead of schedule' : 'on time'}.',
                        Icons.check_circle,
                        AppTheme.accentGreen,
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      if (monthlyNeeded != null)
                        _buildInsightItem(
                          'Monthly Target',
                          'Save KES ${monthlyNeeded.toStringAsFixed(0)} per month to reach your goal on time.',
                          Icons.trending_up,
                          AppTheme.accentBlue,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing32),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddContributionBottomSheet,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.primaryDark,
          icon: const Icon(Icons.add),
          label: Text(
            'Add Contribution',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textGray,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textGray,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Contribution {
  final DateTime date;
  final double amount;
  final String description;

  _Contribution(this.date, this.amount, this.description);
}

// Add Contribution Bottom Sheet
class _AddContributionBottomSheet extends StatefulWidget {
  final Function(double amount, String description) onAdd;

  const _AddContributionBottomSheet({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<_AddContributionBottomSheet> createState() => _AddContributionBottomSheetState();
}

class _AddContributionBottomSheetState extends State<_AddContributionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius24),
          topRight: Radius.circular(AppTheme.radius24),
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryGold.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius24),
          topRight: Radius.circular(AppTheme.radius24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: AppTheme.spacing12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textGray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GradientText(
                        text: 'ADD CONTRIBUTION',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textGray),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount
                        GradientText(
                          text: 'AMOUNT (KES)',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                        PremiumCard(
                          isGlassmorphic: true,
                          padding: EdgeInsets.zero,
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(
                              color: AppTheme.primaryLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter amount',
                              hintStyle: GoogleFonts.poppins(
                                color: AppTheme.textGray,
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(Icons.attach_money, color: AppTheme.primaryGold),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter an amount';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing24),
                        // Description
                        GradientText(
                          text: 'DESCRIPTION',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                        PremiumCard(
                          isGlassmorphic: true,
                          padding: EdgeInsets.zero,
                          child: TextFormField(
                            controller: _descriptionController,
                            style: GoogleFonts.poppins(
                              color: AppTheme.primaryLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter description',
                              hintStyle: GoogleFonts.poppins(
                                color: AppTheme.textGray,
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(Icons.description, color: AppTheme.primaryGold),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing32),
                      ],
                    ),
                  ),
                ),
                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg.withOpacity(0.3),
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.primaryGold.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppTheme.textGray.withOpacity(0.3)),
                                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.goldGradient,
                                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryGold.withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      widget.onAdd(
                                        double.parse(_amountController.text),
                                        _descriptionController.text.trim(),
                                      );
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'KES ${_amountController.text} added successfully!',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: AppTheme.accentGreen,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                                    ),
                                  ),
                                  child: Text(
                                    'Add Contribution',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.primaryDark,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

