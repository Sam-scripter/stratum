import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/investment_model.dart';
import 'add_investment_screen.dart';

class InvestmentDetailScreen extends StatelessWidget {
  final Investment investment;

  const InvestmentDetailScreen({
    Key? key,
    required this.investment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = investment.isPositive;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Investment Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppTheme.primaryGold),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddInvestmentScreen(
                    investmentToEdit: investment,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.accentRed),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.surfaceGray,
                  title: Text(
                    'Delete Investment',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to delete this investment?',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textGray,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Investment deleted'),
                            backgroundColor: AppTheme.accentRed,
                          ),
                        );
                      },
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Investment Overview Card
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              hasGlow: true,
              child: Column(
                children: [
                  // Category Icon
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing20),
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
                  const SizedBox(height: AppTheme.spacing20),

                  // Investment Name
                  Text(
                    investment.name,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    investment.typeName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing24),

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
                      const SizedBox(height: AppTheme.spacing8),
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
                  const SizedBox(height: AppTheme.spacing16),

                  // Return Rate Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing20,
                      vertical: AppTheme.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? AppTheme.accentGreen.withOpacity(0.2)
                          : AppTheme.accentRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radius20),
                      border: Border.all(
                        color: isPositive
                            ? AppTheme.accentGreen.withOpacity(0.5)
                            : AppTheme.accentRed.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          color: isPositive
                              ? AppTheme.accentGreen
                              : AppTheme.accentRed,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Text(
                          investment.formattedReturnRate,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPositive
                                ? AppTheme.accentGreen
                                : AppTheme.accentRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Investment Information
            Text(
              'Investment Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Investment Type',
                    investment.typeName,
                    Icons.category,
                  ),
                  const Divider(color: AppTheme.borderGray, height: AppTheme.spacing24),
                  _buildInfoRow(
                    'Invested Amount',
                    investment.formattedInvestedAmount,
                    Icons.attach_money,
                  ),
                  const Divider(color: AppTheme.borderGray, height: AppTheme.spacing24),
                  _buildInfoRow(
                    'Current Value',
                    investment.formattedCurrentValue,
                    Icons.trending_up,
                  ),
                  const Divider(color: AppTheme.borderGray, height: AppTheme.spacing24),
                  _buildInfoRow(
                    'Gain/Loss',
                    investment.formattedGainLoss,
                    investment.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? AppTheme.accentGreen : AppTheme.accentRed,
                  ),
                  const Divider(color: AppTheme.borderGray, height: AppTheme.spacing24),
                  _buildInfoRow(
                    'Date Invested',
                    investment.formattedDate,
                    Icons.calendar_today,
                  ),
                  if (investment.provider != null && investment.provider!.isNotEmpty) ...[
                    const Divider(color: AppTheme.borderGray, height: AppTheme.spacing24),
                    _buildInfoRow(
                      'Provider/Bank',
                      investment.provider!,
                      Icons.business,
                    ),
                  ],
                  if (investment.referenceNumber != null && investment.referenceNumber!.isNotEmpty) ...[
                    const Divider(color: AppTheme.borderGray, height: AppTheme.spacing24),
                    _buildInfoRow(
                      'Reference Number',
                      investment.referenceNumber!,
                      Icons.qr_code,
                    ),
                  ],
                  if (investment.notes != null && investment.notes!.isNotEmpty) ...[
                    const Divider(color: AppTheme.borderGray, height: AppTheme.spacing24),
                    _buildInfoRow(
                      'Notes',
                      investment.notes!,
                      Icons.note_outlined,
                      isMultiLine: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Action Buttons
            Text(
              'Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildActionButton(
              context,
              'Edit Investment',
              Icons.edit_outlined,
              AppTheme.primaryGold,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddInvestmentScreen(
                      investmentToEdit: investment,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing12),
            _buildActionButton(
              context,
              'Share Investment',
              Icons.share_outlined,
              AppTheme.accentBlue,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share feature coming soon!'),
                    backgroundColor: AppTheme.accentBlue,
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing32),
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
          padding: const EdgeInsets.all(AppTheme.spacing8),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.primaryGold).withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radius8),
            border: Border.all(
              color: (color ?? AppTheme.primaryGold).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color ?? AppTheme.primaryGold,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
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
              const SizedBox(height: AppTheme.spacing4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppTheme.primaryLight,
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

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textGray,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

