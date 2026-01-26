import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 
import '../../theme/app_theme.dart';
// import '../../widgets/custom_widgets.dart'; // Assume this might be missing or valid, but I'll use standard widgets if unsure. 
// Using standard widgets for safety since I haven't seen custom_widgets.dart recently.
import '../../models/investment/investment_model.dart';
import 'add_investment_screen.dart';

class InvestmentDetailScreen extends StatelessWidget {
  final InvestmentModel investment;

  const InvestmentDetailScreen({
    Key? key,
    required this.investment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = investment.profitOrLoss >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // backgroundDeep
      appBar: AppBar(
        title: Text(
          'Investment Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A2332), // backgroundLight
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primaryGold),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddInvestmentScreen(
                    existingInvestment: investment,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Investment Overview Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGold.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: Column(
                children: [
                  // Category Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGold.withOpacity(0.3),
                          AppTheme.primaryGold.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryGold.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      investment.typeEmoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Investment Name
                  Text(
                    investment.name,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    investment.type.name.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Current Value
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Current Value',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textGray,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        investment.formattedCurrentValue,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Return Rate Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPositive
                            ? Colors.green.withOpacity(0.5)
                            : Colors.red.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          color: isPositive
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          investment.formattedReturnRate,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPositive
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Investment Information
            Text(
              'Investment Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2332),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Invested Amount',
                    investment.formattedInvestedAmount,
                    Icons.attach_money,
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildInfoRow(
                    'Gain/Loss',
                    investment.formattedGainLoss,
                    investment.profitOrLoss >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildInfoRow(
                    'Last Updated',
                    DateFormat('MMM d, yyyy').format(investment.lastUpdated),
                    Icons.calendar_today,
                  ),
                  if (investment.notes.isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 24),
                    _buildInfoRow(
                      'Notes',
                      investment.notes,
                      Icons.note_outlined,
                      isMultiLine: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.primaryGold).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color ?? AppTheme.primaryGold,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.white,
                ),
                maxLines: isMultiLine ? null : 1,
                overflow: isMultiLine ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Extensions for formatting
extension InvestmentModelDisplay on InvestmentModel {
  String get typeEmoji {
    switch (type) {
      case InvestmentType.stock: return '📈';
      case InvestmentType.mmf: return '💰';
      case InvestmentType.crypto: return '₿';
      case InvestmentType.bond: return '📜';
      case InvestmentType.property: return '🏠';
      case InvestmentType.other: return '📦';
    }
  }

  String get formattedCurrentValue {
    return 'KES ${NumberFormat("#,##0.00").format(currentValue)}';
  }

  String get formattedInvestedAmount {
    return 'KES ${NumberFormat("#,##0.00").format(principalAmount)}';
  }

  String get formattedReturnRate {
    final profit = profitOrLoss;
    final percent = profitOrLossPercentage;
    final sign = profit >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }
  
  String get formattedGainLoss {
     final profit = profitOrLoss;
     final sign = profit >= 0 ? '+' : '';
     return '$sign${NumberFormat("#,##0.00").format(profit)}';
  }
}
