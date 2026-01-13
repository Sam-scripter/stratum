import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SmsProcessingDialog extends StatefulWidget {
  final Future<Map<String, int>> Function() processingTask;
  final Function(Map<String, int>)? onComplete;

  const SmsProcessingDialog({
    Key? key,
    required this.processingTask,
    this.onComplete,
  }) : super(key: key);

  @override
  State<SmsProcessingDialog> createState() => _SmsProcessingDialogState();
}

class _SmsProcessingDialogState extends State<SmsProcessingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  String _statusText = 'Reading messages...';
  double _progress = 0.0;
  Map<String, int>? _detectedAccounts;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _startProcessing();
  }

  Future<void> _startProcessing() async {
    // Simulate progress updates
    _updateProgress(0.1, 'Scanning SMS inbox...');
    await Future.delayed(const Duration(milliseconds: 300));

    _updateProgress(0.3, 'Filtering financial messages...');
    await Future.delayed(const Duration(milliseconds: 400));

    _updateProgress(0.5, 'Extracting transactions...');
    await Future.delayed(const Duration(milliseconds: 300));

    _updateProgress(0.7, 'Calculating balances...');
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // Execute the actual processing task
      final result = await widget.processingTask();
      _detectedAccounts = result;

      _updateProgress(0.9, 'Finalizing...');
      await Future.delayed(const Duration(milliseconds: 200));

      _updateProgress(1.0, 'Complete!');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(_detectedAccounts);
        if (widget.onComplete != null && _detectedAccounts != null) {
          widget.onComplete!(_detectedAccounts!);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing messages: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _updateProgress(double progress, String status) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _statusText = status;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing during processing
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          decoration: BoxDecoration(
            gradient: AppTheme.premiumGradient,
            borderRadius: BorderRadius.circular(AppTheme.radius20),
            border: Border.all(
              color: AppTheme.primaryGold.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGold.withOpacity(0.3),
                          AppTheme.primaryGold,
                        ],
                        stops: [
                          _progressAnimation.value,
                          _progressAnimation.value + 0.1,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.sms_outlined,
                      size: 40,
                      color: AppTheme.primaryDark,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacing24),
              
              // Title
              Text(
                'Processing Messages',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              
              // Status Text
              Text(
                _statusText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing24),
              
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radius8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: AppTheme.surfaceGray,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              
              // Progress Percentage
              Text(
                '${(_progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Completion Dialog
class SmsProcessingCompleteDialog extends StatelessWidget {
  final Map<String, int> detectedAccounts;

  const SmsProcessingCompleteDialog({
    Key? key,
    required this.detectedAccounts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accountList = detectedAccounts.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key}: ${e.value} messages')
        .join('\n');

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        decoration: BoxDecoration(
          gradient: AppTheme.premiumGradient,
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          border: Border.all(
            color: AppTheme.accentGreen.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.successGradient,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            
            // Title
            Text(
              'Sync Complete!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            
            // Message
            Text(
              'We\'ve detected and processed messages from your financial accounts. Your balances have been automatically calculated based on the transactions found.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing20),
            
            // Detected Accounts
            if (accountList.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGray.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Accounts:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      accountList,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
            ],
            
            // Info Text
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppTheme.accentBlue,
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Text(
                      'You can review and edit transactions in the Transactions section if any calculations need correction.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textGray,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            
            // OK Button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

