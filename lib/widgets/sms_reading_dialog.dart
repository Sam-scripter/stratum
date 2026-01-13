import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/sms_reader/sms_reader_service.dart';

class SmsReadingDialog extends StatefulWidget {
  final SmsReaderService smsReaderService;
  final VoidCallback onComplete;

  const SmsReadingDialog({
    Key? key,
    required this.smsReaderService,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<SmsReadingDialog> createState() => _SmsReadingDialogState();
}

class _SmsReadingDialogState extends State<SmsReadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  String _statusText = 'Reading messages...';
  double _progress = 0.0;
  int _transactionsFound = 0;

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

    _startReading();
  }

  Future<void> _startReading() async {
    try {
      await for (var progress in widget.smsReaderService.readAllSms()) {
        if (!mounted) break;

        setState(() {
          _progress = progress.progress;
          _statusText = progress.status;
          _transactionsFound = progress.transactionsFound;
        });

        if (progress.isComplete) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop();
            widget.onComplete();
          }
          break;
        }

        if (progress.hasError) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${progress.status}'),
                backgroundColor: AppTheme.accentRed,
              ),
            );
          }
          break;
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading messages: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
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
      canPop: false,
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
              if (_transactionsFound > 0) ...[
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Found $_transactionsFound transactions',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ],
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

