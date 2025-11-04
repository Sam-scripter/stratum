import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({Key? key}) : super(key: key);

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  String _selectedFormat = 'CSV';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _includeTransactions = true;
  bool _includeBudgets = true;
  bool _includeInvestments = true;
  bool _isExporting = false;

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
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
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _endDate) {
      setState(() => _endDate = picked);
    }
  }

  void _handleExport() {
    setState(() => _isExporting = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data export completed! Check your downloads folder.'),
            backgroundColor: AppTheme.accentGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Export Data',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            PremiumCard(
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
                          Icons.file_download_outlined,
                          color: AppTheme.primaryDark,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing16),
                      Expanded(
                        child: Text(
                          'Export Your Data',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Text(
                    'Download a copy of your financial data in your preferred format.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Export Format
            Text(
              'Export Format',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: _buildFormatOption('CSV', Icons.table_chart),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildFormatOption('JSON', Icons.code),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildFormatOption('PDF', Icons.picture_as_pdf),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Date Range
            Text(
              'Date Range',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
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
                            fontSize: 12,
                            color: AppTheme.textGray,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                            Icon(Icons.calendar_today, color: AppTheme.primaryGold, size: 20),
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
                            fontSize: 12,
                            color: AppTheme.textGray,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                            Icon(Icons.calendar_today, color: AppTheme.primaryGold, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Data Types
            Text(
              'What to Export',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildCheckboxTile('Transactions', _includeTransactions, (value) {
              setState(() => _includeTransactions = value);
            }),
            _buildCheckboxTile('Budgets', _includeBudgets, (value) {
              setState(() => _includeBudgets = value);
            }),
            _buildCheckboxTile('Investments', _includeInvestments, (value) {
              setState(() => _includeInvestments = value);
            }),
            const SizedBox(height: AppTheme.spacing32),

            // Export Button
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
                onPressed: _isExporting ? null : _handleExport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius16),
                  ),
                ),
                child: _isExporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDark),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.file_download, color: AppTheme.primaryDark),
                          const SizedBox(width: AppTheme.spacing8),
                          Text(
                            'Export Data',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(String format, IconData icon) {
    final isSelected = _selectedFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = format),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        hasGlow: isSelected,
        backgroundColor: isSelected
            ? AppTheme.primaryGold.withOpacity(0.1)
            : AppTheme.surfaceGray,
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryGold : AppTheme.textGray,
              size: 32,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              format,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryGold : AppTheme.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            Checkbox(
              value: value,
              onChanged: (newValue) => onChanged(newValue ?? false),
              activeColor: AppTheme.primaryGold,
            ),
          ],
        ),
      ),
    );
  }
}

