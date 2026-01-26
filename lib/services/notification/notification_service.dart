import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../models/account/account_model.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/box_manager.dart';
import 'package:intl/intl.dart';
import 'package:stratum/main.dart';
import 'package:stratum/screens/transactions/transaction_detail_screen.dart';

/// Service for sending local notifications when transactions are detected
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
    FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  // Pending ID for cold start or unauthenticated state
  String? _pendingTransactionId;
  String? get pendingTransactionId => _pendingTransactionId;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    // Check if app was launched by notification
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp && details.notificationResponse?.payload != null) {
      _pendingTransactionId = details.notificationResponse!.payload;
      print("App launched via notification for transaction: $_pendingTransactionId");
    }

    _initialized = true;
  }

  /// Request notification permissions (Android 13+)
  Future<void> _requestPermissions() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      // await androidImplementation.requestExactAlarmsPermission(); // Not strictly needed unless scheduling
    }
  }

  /// Show a notification when a transaction is detected
  Future<void> showTransactionNotification({
    required Transaction transaction,
    required Account account,
  }) async {
    await initialize();

    final isIncome = transaction.type == TransactionType.income;
    final amount = transaction.amount;
    final formattedAmount = NumberFormat.currency(
      symbol: 'KES ',
      decimalDigits: 0,
    ).format(amount);

    final title = isIncome 
      ? '💰 Payment Received'
      : '💸 Payment Made';
    
    final body = isIncome
      ? 'You received $formattedAmount from ${transaction.title}'
      : 'You paid $formattedAmount to ${transaction.title}';

    const androidDetails = AndroidNotificationDetails(
      'transaction_alert', // Must match Background Service Channel ID if possible, or be distinct
      'Transaction Alerts',
      channelDescription: 'Notifications when transactions are automatically detected',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher', // Ensure resource exists
      color: Color(0xFFD4AF37), // Gold color
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use transaction ID hash as notification ID to avoid duplicates
    final notificationId = transaction.id.hashCode;

    await _notifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: transaction.id, // Pass transaction ID as payload for deep linking
    );
  }

  /// Handle notification tap - navigate to transaction detail or queue it
  void _onNotificationTapped(NotificationResponse response) async {
    if (response.payload != null) {
      final transactionId = response.payload!;
      print('Notification tapped for transaction: $transactionId');
      
      final user = FirebaseAuth.instance.currentUser;
      
      // If user is logged in and navigator is ready, go immediately.
      // Otherwise, store it as pending.
      if (user != null && navigatorKey.currentState != null) {
         _navigateToTransaction(transactionId);
      } else {
        _pendingTransactionId = transactionId;
        print('Queued transaction navigation (Auth/Nav not ready)');
      }
    }
  }

  /// Consume and clear the pending transaction ID
  void consumePendingTransaction() {
    if (_pendingTransactionId != null) {
      final id = _pendingTransactionId!;
      _pendingTransactionId = null;
      // Small delay to ensure UI frame is ready if called during build
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToTransaction(id);
      });
    }
  }
  
  Future<void> _navigateToTransaction(String transactionId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print("Notification Nav: User not logged in, queueing.");
        _pendingTransactionId = transactionId;
        return;
      }
      
      final boxManager = BoxManager();
      // Ensure box is open (might be redundant but safe)
      if (!Hive.isBoxOpen(BoxManager.transactionsBoxName + '_$userId')) {
         await boxManager.openAllBoxes(userId);
      }
      
      final box = boxManager.getBox<Transaction>(BoxManager.transactionsBoxName, userId);
      final transaction = box.get(transactionId);
      
      // Retry logic for navigation context
      int retries = 0;
      while (navigatorKey.currentState == null && retries < 3) {
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
      }

      if (navigatorKey.currentState != null) {
        if (transaction != null) {
          print("Notification Nav: Navigating to transaction $transactionId");
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(transaction: transaction),
            ),
          );
        } else {
             print("Notification Nav: Transaction not found in Hive (ID: $transactionId)");
             // Optionally fetch from backend if strictly needed, but local-first means it should be there.
        }
      } else {
        print("Notification Nav: Navigator State is null after retries.");
        _pendingTransactionId = transactionId; // Queue for next usable state
      }
    } catch (e) {
      print('Error navigating to transaction: $e');
    }
  }
  
  /// Get the notification service instance
  static NotificationService get instance => _instance;

  /// Cancel a notification
  Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

