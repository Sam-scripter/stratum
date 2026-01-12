import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/sms_reader/sms_reader_service.dart';
import '../../theme/app_theme.dart';
import '../../models/box_manager.dart';
import '../../models/app settings/app_settings.dart';
import '../../models/account/account_model.dart';
import '../../models/transaction/transaction_model.dart';
import '../../widgets/sms_reading_dialog.dart';
import '../../widgets/sms_processing_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';

class SmsScanningScreen extends StatefulWidget {
  const SmsScanningScreen({Key? key}) : super(key: key);

  @override
  State<SmsScanningScreen> createState() => _SmsScanningScreenState();
}

class _SmsScanningScreenState extends State<SmsScanningScreen> {
  late SmsReaderService _smsReaderService;
  late String _userId;
  late BoxManager _boxManager;
  bool _hasPermission = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? 'anonymous_user';
    _smsReaderService = SmsReaderService(_userId);
    _boxManager = BoxManager();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.sms.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
    
    if (!_hasPermission) {
      _requestPermission();
    } else {
      _startScanning();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _startScanning();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('SMS permission is required to track your finances'),
            backgroundColor: AppTheme.accentRed,
            action: SnackBarAction(
              label: 'Open Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _startScanning() async {
    if (!_hasPermission) return;
    
    setState(() {
      _isScanning = true;
    });

    // Show scanning dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SmsReadingDialog(
        smsReaderService: _smsReaderService,
        onComplete: () async {
          // Mark as complete
          await _boxManager.openAllBoxes(_userId);
          final settingsBox = _boxManager.getBox<AppSettings>(
            BoxManager.settingsBoxName,
            _userId,
          );
          final appSettings = settingsBox.get(_userId) ?? AppSettings();
          final updated = appSettings.copyWith(
            lastMpesaSmsTimestamp: DateTime.now().millisecondsSinceEpoch,
            initialScanComplete: true,
          );
          settingsBox.put(_userId, updated);

          // Load detected accounts
          final accountsBox = _boxManager.getBox<Account>(
            BoxManager.accountsBoxName,
            _userId,
          );
          final transactionsBox = _boxManager.getBox<Transaction>(
            BoxManager.transactionsBoxName,
            _userId,
          );

          final Map<String, int> accountCounts = {};
          for (var account in accountsBox.values) {
            final count = transactionsBox.values
                .where((t) => t.accountId == account.id)
                .length;
            if (count > 0) {
              accountCounts[account.name] = count;
            }
          }

          if (mounted) {
            Navigator.of(context).pop(); // Close scanning dialog
            
            // Show completion dialog
            showDialog(
              context: context,
              builder: (context) => SmsProcessingCompleteDialog(
                detectedAccounts: accountCounts,
              ),
            ).then((_) {
              // Navigate to home after completion dialog is dismissed
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(),
                  ),
                );
              }
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentBlue,
                      AppTheme.accentBlue.withOpacity(0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentBlue.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title
              Text(
                'Grant SMS Permission',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'To automatically track your financial transactions, Stratum needs permission to read SMS messages from your financial institutions.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppTheme.textGray,
                  height: 1.6,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Info Cards
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGray,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.lock_outline,
                      text: 'Your data stays on your device',
                      color: AppTheme.accentGreen,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.filter_alt_outlined,
                      text: 'Only financial messages are read',
                      color: AppTheme.accentBlue,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.shield_outlined,
                      text: 'No data is shared with third parties',
                      color: AppTheme.primaryGold,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Grant Permission Button
              if (!_hasPermission && !_isScanning)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Grant Permission',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ),
              
              if (_isScanning)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textGray,
            ),
          ),
        ),
      ],
    );
  }
}

