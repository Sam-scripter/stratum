import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/app settings/app_settings.dart';
import '../../services/sms_reader/sms_reader_service.dart';
import '../../theme/app_theme.dart';
import '../../models/box_manager.dart';
import '../../models/account/account_model.dart';
import '../../models/transaction/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/background/sms_background_service.dart';
import '../../models/account/account_model.dart';
import '../../models/transaction/transaction_model.dart';
import 'package:hive/hive.dart';

enum ScanningState { requestPermission, scanning, processing, complete }

class SmsScanningScreen extends StatefulWidget {
  const SmsScanningScreen({Key? key}) : super(key: key);

  @override
  State<SmsScanningScreen> createState() => _SmsScanningScreenState();
}

class _SmsScanningScreenState extends State<SmsScanningScreen>
    with SingleTickerProviderStateMixin {
  late SmsReaderService _smsReaderService;
  late String _userId;
  late BoxManager _boxManager;
  late AnimationController _animationController;

  ScanningState _currentState = ScanningState.requestPermission;

  // Progress tracking
  int _totalMessages = 0;
  int _processedMessages = 0;
  int _transactionsFound = 0;
  Map<String, int> _detectedAccounts = {};

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? 'anonymous_user';
    _smsReaderService = SmsReaderService(_userId);
    _boxManager = BoxManager();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _checkPermission();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.sms.status;
    if (status.isGranted) {
      _startScanning();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();

    if (status.isGranted) {
      _startScanning();
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('SMS permission is required'),
            backgroundColor: AppTheme.accentRed,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _requestPermission,
            ),
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Permission Required',
          style: GoogleFonts.poppins(
            color: AppTheme.primaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Please enable SMS permission in settings to continue.',
          style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppTheme.textGray),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startScanning() async {
    setState(() {
      _currentState = ScanningState.scanning;
    });

    try {
      // Start scanning with progress updates
      await for (final progress in _smsReaderService.scanAllMessages()) {
        if (!mounted) break;

        setState(() {
          _totalMessages = progress.totalMessages;
          _processedMessages = progress.processedMessages;
          _transactionsFound = progress.transactionsFound;
        });
      }

      // Move to processing state
      setState(() {
        _currentState = ScanningState.processing;
      });

      // Give UI time to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Mark as complete
      await _boxManager.openAllBoxes(_userId);
      final settingsBox = _boxManager.getBox<AppSettings>(
        BoxManager.settingsBoxName,
        _userId,
      );
      final accountsBox = _boxManager.getBox<Account>(
        BoxManager.accountsBoxName,
        _userId,
      );
      final transactionsBox = _boxManager.getBox<Transaction>(
        BoxManager.transactionsBoxName,
        _userId,
      );
      
      // Merge duplicate accounts immediately after scanning
      print('Merging duplicate accounts after SMS scan...');
      await _mergeAccountsAfterScan(accountsBox, transactionsBox);
      
      final appSettings = settingsBox.get(_userId) ?? AppSettings();
      final updated = appSettings.copyWith(
        lastMpesaSmsTimestamp: DateTime.now().millisecondsSinceEpoch,
        initialScanComplete: true,
        accountsMerged: true, // Mark as merged
      );
      settingsBox.put(_userId, updated);
      print('Account merging completed and marked in settings');

      // Mark SMS onboarding as completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedSmsOnboarding', true);

      // Accounts and transactions boxes already loaded above

      final Map<String, int> accountCounts = {};
      for (var account in accountsBox.values) {
        final count = transactionsBox.values
            .where((t) => t.accountId == account.id)
            .length;
        if (count > 0) {
          accountCounts[account.name] = count;
        }
      }

      setState(() {
        _detectedAccounts = accountCounts;
        _currentState = ScanningState.complete;
      });

      // Start background SMS monitoring
      await BackgroundSmsService.startMonitoring(_userId);

      // Auto-navigate after showing complete state
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
        setState(() {
          _currentState = ScanningState.requestPermission;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildCurrentStateWidget(),
        ),
      ),
    );
  }

  Widget _buildCurrentStateWidget() {
    switch (_currentState) {
      case ScanningState.requestPermission:
        return _buildPermissionRequest();
      case ScanningState.scanning:
        return _buildScanningProgress();
      case ScanningState.processing:
        return _buildProcessingState();
      case ScanningState.complete:
        return _buildCompleteState();
    }
  }

  Widget _buildPermissionRequest() {
    return Padding(
      key: const ValueKey('permission'),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon
          RotationTransition(
            turns: _animationController,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentBlue,
                    AppTheme.accentBlue.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentBlue.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.sms_outlined,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 48),

          Text(
            'Setup Automatic Tracking',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Grant SMS permission to automatically track transactions from M-PESA, KCB, and other banks',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppTheme.textGray,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 40),

          // Privacy badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPrivacyBadge(Icons.lock_outline, 'Secure'),
              _buildPrivacyBadge(Icons.phone_android, 'Local Only'),
              _buildPrivacyBadge(Icons.verified_user, 'Private'),
            ],
          ),

          const Spacer(),

          // Grant Permission Button
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
                'Continue',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              // Skip for now - navigate to main
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            },
            child: Text(
              'Skip for now',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningProgress() {
    final progress = _totalMessages > 0
        ? _processedMessages / _totalMessages
        : 0.0;

    return Padding(
      key: const ValueKey('scanning'),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress Circle
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.textGray.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentBlue,
                    ),
                  ),
                ),
                // Percentage
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    Text(
                      'Scanning',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          Text(
            'Reading Messages',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),

          const SizedBox(height: 24),

          // Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  'Messages',
                  '$_processedMessages / $_totalMessages',
                  Icons.mail_outline,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.textGray.withOpacity(0.2),
                ),
                _buildStat('Found', '$_transactionsFound', Icons.receipt_long),
              ],
            ),
          ),

          const Spacer(),

          Text(
            'This may take a moment...',
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Padding(
      key: const ValueKey('processing'),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated processing icon
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(seconds: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentGreen.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.speed,
                    size: 50,
                    color: AppTheme.accentGreen,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          Text(
            'Processing Transactions',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Categorizing and organizing your data...',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textGray),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteState() {
    return Padding(
      key: const ValueKey('complete'),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success icon with animation
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentGreen.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: AppTheme.accentGreen,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          Text(
            'All Set!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryLight,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Found $_transactionsFound transactions',
            style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textGray),
          ),

          if (_detectedAccounts.isNotEmpty) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: _detectedAccounts.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        Text(
                          '${entry.value} transactions',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const Spacer(),

          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Taking you to your dashboard...',
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBadge(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.accentGreen, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGray),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryLight,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGray),
        ),
      ],
    );
  }

  // Merge duplicate accounts after SMS scanning
  Future<void> _mergeAccountsAfterScan(
    Box<Account> accountsBox,
    Box<Transaction> transactionsBox,
  ) async {
    final allAccounts = accountsBox.values.toList();
    final allTransactions = transactionsBox.values.toList();

    // Group accounts by standardized name
    final Map<String, List<Account>> accountsByKey = {};
    for (var account in allAccounts) {
      final key = _getAccountKey(account);
      if (!accountsByKey.containsKey(key)) {
        accountsByKey[key] = [];
      }
      accountsByKey[key]!.add(account);
    }

    int totalMerged = 0;
    int totalTransactionsMigrated = 0;

    // For each group with duplicates, merge them
    for (var entry in accountsByKey.entries) {
      if (entry.value.length <= 1) continue; // No duplicates

      final duplicates = entry.value;

      // Find the primary account (prefer correct type, then most transactions)
      Account primaryAccount = duplicates.reduce((a, b) {
        final aName = a.name.toUpperCase().trim();
        final bName = b.name.toUpperCase().trim();
        final aIsCorrectType = (aName == 'MPESA' && a.type == AccountType.Mpesa) ||
                               (aName != 'MPESA' && a.type == AccountType.Bank);
        final bIsCorrectType = (bName == 'MPESA' && b.type == AccountType.Mpesa) ||
                               (bName != 'MPESA' && b.type == AccountType.Bank);
        
        if (aIsCorrectType && !bIsCorrectType) return a;
        if (bIsCorrectType && !aIsCorrectType) return b;
        
        final aTxCount = allTransactions.where((t) => t.accountId == a.id).length;
        final bTxCount = allTransactions.where((t) => t.accountId == b.id).length;
        if (aTxCount > bTxCount) return a;
        if (bTxCount > aTxCount) return b;
        return a.balance >= b.balance ? a : b;
      });

      // Ensure primary account has correct type and name
      final normalizedName = primaryAccount.name.toUpperCase().trim();
      Account updatedPrimary = primaryAccount;
      if (normalizedName == 'MPESA' || normalizedName.contains('MPESA')) {
        if (primaryAccount.type != AccountType.Mpesa) {
          updatedPrimary = updatedPrimary.copyWith(type: AccountType.Mpesa);
        }
        if (primaryAccount.name != 'MPESA') {
          updatedPrimary = updatedPrimary.copyWith(name: 'MPESA');
        }
        if (updatedPrimary.type != primaryAccount.type ||
            updatedPrimary.name != primaryAccount.name) {
          accountsBox.put(primaryAccount.id, updatedPrimary);
          primaryAccount = updatedPrimary;
        }
      }

      // Get accounts to merge (excluding primary)
      final toMerge = duplicates.where((acc) => acc.id != primaryAccount.id).toList();
      if (toMerge.isEmpty) continue;

      print('Merging ${toMerge.length} duplicate ${entry.key} accounts into ${primaryAccount.name}');

      // Migrate transactions from duplicate accounts to primary
      int migratedCount = 0;
      for (var duplicateAccount in toMerge) {
        // Get transactions from the box directly
        final duplicateTransactions = transactionsBox.values
            .where((t) => t.accountId == duplicateAccount.id)
            .toList();

        for (var transaction in duplicateTransactions) {
          final updatedTransaction = transaction.copyWith(
            accountId: primaryAccount.id,
          );
          transactionsBox.put(updatedTransaction.id, updatedTransaction);
          migratedCount++;
        }

        // Delete duplicate account
        await accountsBox.delete(duplicateAccount.id);
      }

      totalMerged += toMerge.length;
      totalTransactionsMigrated += migratedCount;

      // Update primary account balance from most recent transaction
      final primaryTransactions = transactionsBox.values
          .where((t) => t.accountId == primaryAccount.id)
          .toList();

      Transaction? mostRecentWithBalance;
      for (var transaction in primaryTransactions) {
        if (transaction.newBalance != null && transaction.newBalance! > 0) {
          if (mostRecentWithBalance == null ||
              transaction.date.isAfter(mostRecentWithBalance.date)) {
            mostRecentWithBalance = transaction;
          }
        }
      }

      if (mostRecentWithBalance != null) {
        final updatedAccount = primaryAccount.copyWith(
          balance: mostRecentWithBalance.newBalance!,
          lastUpdated: mostRecentWithBalance.date,
        );
        accountsBox.put(primaryAccount.id, updatedAccount);
      }
    }

    print('Merge complete: Deleted $totalMerged duplicate accounts, migrated $totalTransactionsMigrated transactions');
  }

  // Helper to create unique key for account deduplication (same as home screen)
  String _getAccountKey(Account account) {
    final normalizedName = account.name.toUpperCase().trim();
    if (normalizedName == 'MPESA' || 
        normalizedName == 'M-PESA' ||
        normalizedName.contains('MPESA') ||
        normalizedName.contains('M-PESA')) {
      return 'MPESA';
    }
    return normalizedName;
  }
}
