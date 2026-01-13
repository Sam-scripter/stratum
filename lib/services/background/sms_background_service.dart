import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/box_manager.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/account/account_model.dart';
import '../../models/message_pattern/message_pattern.dart';
import '../../models/app settings/app_settings.dart';
import '../sms_reader/sms_reader_service.dart';
import '../notification/notification_service.dart';
import '../pattern learning/pattern_learning_service.dart';

// Top-level callback for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Check if foreground service is running
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (!isRunning) {
        // Restart the foreground service (fire and forget)
        BackgroundSmsService.startMonitoring();
      }
      return Future.value(true);
    } catch (e) {
      print('WorkManager error: $e');
      return Future.value(false);
    }
  });
}

// Background SMS monitoring service
class BackgroundSmsService {
  static const String taskId = 'sms_monitoring_task';
  static const String workTag = 'sms_monitoring_work';

  static Future<void> initialize() async {
    // Initialize foreground task
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sms_monitoring_channel',
        channelName: 'SMS Monitoring',
        channelDescription: 'Monitoring financial SMS messages',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          5000,
        ), // Check every 5 seconds
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    // Initialize WorkManager
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> startMonitoring([String? userId]) async {
    // Check SMS permission
    final smsPermission = await Permission.sms.isGranted;
    if (!smsPermission) return;

    // Store user ID for background service
    if (userId != null) {
      // Store user ID in shared preferences for background service
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('background_service_user_id', userId);
    }

    // Start foreground task
    await FlutterForegroundTask.startService(
      notificationTitle: 'Stratum - Financial Monitor',
      notificationText: 'Monitoring your financial transactions',
      callback: smsMonitoringCallback,
    );

    // Schedule WorkManager to check service health
    await Workmanager().registerPeriodicTask(
      workTag,
      workTag,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  static Future<void> stopMonitoring() async {
    await FlutterForegroundTask.stopService();
    await Workmanager().cancelByTag(workTag);
  }

  @pragma('vm:entry-point')
  static void smsMonitoringCallback() {
    FlutterForegroundTask.setTaskHandler(SmsMonitoringTaskHandler());
  }
}

class SmsMonitoringTaskHandler extends TaskHandler {
  final SmsQuery _query = SmsQuery();
  DateTime? _lastSmsCheck;
  String? _userId;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('SMS Monitoring started');

    // Get user ID from shared preferences (stored by main app)
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('background_service_user_id');

    if (_userId == null || _userId == 'anonymous_user') {
      print(
        'ERROR: No valid user ID found for background service. User must be logged in.',
      );
      return;
    }

    print('Background service user ID: $_userId');

    // Initialize Hive
    await BoxManager().openAllBoxes(_userId!);

    // Set last check time to 1 hour ago to catch recent messages
    _lastSmsCheck = DateTime.now().subtract(const Duration(hours: 1));
    print('Last SMS check initialized to: $_lastSmsCheck');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Check for new SMS messages
    _checkForNewSms();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isDestroyed) async {
    print('SMS Monitoring stopped');
  }

  @override
  void onNotificationPressed() {
    // Handle notification tap - could navigate to app
    FlutterForegroundTask.launchApp();
  }

  Future<void> _checkForNewSms() async {
    if (_userId == null || _userId == 'anonymous_user') {
      print('Skipping SMS check - no valid user ID');
      return;
    }

    print('Checking for new SMS messages...');

    try {
      // Get recent SMS (last 24 hours)
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 50, // Check last 50 messages
      );

      print('Found ${messages.length} total SMS messages');

      // Filter for financial messages received after last check
      final financialSenders = {
        'MPESA',
        'M-PESA',
        'SAFARICOM',
        'KCB',
        'EQUITY',
        'COOP',
        'CO-OP',
        'NCBA',
        'STANBIC',
      };

      final newFinancialMessages = messages.where((msg) {
        final address = msg.address?.toUpperCase() ?? '';
        final isFinancial = financialSenders.any(
          (sender) => address.contains(sender),
        );
        final isNew = msg.date != null && msg.date!.isAfter(_lastSmsCheck!);
        return isFinancial && isNew && msg.body != null;
      }).toList();

      print(
        'Found ${newFinancialMessages.length} new financial messages after $_lastSmsCheck',
      );

      if (newFinancialMessages.isNotEmpty) {
        await _processNewMessages(newFinancialMessages);
      }

      _lastSmsCheck = DateTime.now();
    } catch (e) {
      print('Error checking SMS: $e');
    }
  }

  Future<void> _processNewMessages(List<SmsMessage> messages) async {
    final smsReader = SmsReaderService(_userId!);

    for (final message in messages) {
      try {
        print('Processing SMS from ${message.address}: ${message.body}');
        // Parse the SMS
        final transaction = await smsReader.parseSmsToTransaction(
          message.address!,
          message.body!,
          message.date ?? DateTime.now(),
        );

        if (transaction != null) {
          print(
            'Parsed transaction: ${transaction.amount} ${transaction.type} for account ${transaction.accountId}',
          );
          // Save transaction
          final boxManager = BoxManager();
          await boxManager.openAllBoxes(_userId!);
          final transactionBox = boxManager.getBox<Transaction>(
            BoxManager.transactionsBoxName,
            _userId!,
          );

          // Check for duplicates
          final existing = transactionBox.values.firstWhere(
            (t) =>
                t.mpesaCode == transaction.mpesaCode &&
                transaction.mpesaCode != null,
            orElse: () => transaction,
          );

          if (existing.id == transaction.id) {
            // New transaction
            transactionBox.put(transaction.id, transaction);
            print('Saved new transaction with ID: ${transaction.id}');

            // Update account balance
            await _updateAccountBalance(transaction);

            // Show notification
            await _showTransactionNotification(transaction);

            // Learn from this transaction
            await _learnFromTransaction(transaction, message.body!);
          }
        }
      } catch (e) {
        print('Error processing SMS: $e');
      }
    }
  }

  Future<void> _updateAccountBalance(Transaction transaction) async {
    final boxManager = BoxManager();
    final accountBox = boxManager.getBox<Account>(
      BoxManager.accountsBoxName,
      _userId!,
    );

    final account = accountBox.get(transaction.accountId);
    if (account != null) {
      final updatedBalance = transaction.type == TransactionType.income
          ? account.balance + transaction.amount
          : account.balance - transaction.amount;

      final updatedAccount = account.copyWith(
        balance: updatedBalance,
        lastUpdated: DateTime.now(),
      );

      accountBox.put(account.id, updatedAccount);
      print(
        'Updated account ${account.name} (${account.id}) balance from ${account.balance} to $updatedBalance',
      );
    } else {
      print(
        'Account not found for transaction account ID: ${transaction.accountId}',
      );
      // List all accounts to debug
      final allAccounts = accountBox.values.toList();
      print(
        'Available accounts: ${allAccounts.map((a) => '${a.name} (${a.id})').join(', ')}',
      );
    }
  }

  Future<void> _showTransactionNotification(Transaction transaction) async {
    // Check if transaction notifications are enabled
    final settingsBox = BoxManager().getBox<AppSettings>(
      BoxManager.settingsBoxName,
      _userId!,
    );
    final appSettings = settingsBox.get('app_settings');

    // Only show notification if enabled (default to true if not set)
    if (appSettings?.transactionNotificationsEnabled ?? true) {
      // Get the account for the transaction
      final boxManager = BoxManager();
      final accountBox = boxManager.getBox<Account>(
        BoxManager.accountsBoxName,
        _userId!,
      );

      final account = accountBox.get(transaction.accountId);
      if (account != null) {
        final notificationService = NotificationService();
        await notificationService.showTransactionNotification(
          transaction: transaction,
          account: account,
        );
      }
    }
  }

  Future<void> _learnFromTransaction(
    Transaction transaction,
    String smsBody,
  ) async {
    // Create pattern and save learning
    final pattern = PatternLearningService.learnPattern(
      smsBody,
      transaction.category.toString().split('.').last,
    );
    final messagePattern = MessagePattern(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pattern: pattern,
      category: transaction.category.toString().split('.').last,
      accountType: 'MPESA', // Could be enhanced to detect account type
      lastSeen: DateTime.now(),
    );

    await PatternLearningService.savePattern(messagePattern, _userId!);
  }
}
