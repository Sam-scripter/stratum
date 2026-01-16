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

    _initialized = true;
  }

  /// Request notification permissions (Android 13+)
  Future<void> _requestPermissions() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
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
      'transaction_channel',
      'Transaction Notifications',
      channelDescription: 'Notifications when transactions are automatically detected',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
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

    // Use transaction ID as notification ID to avoid duplicates
    final notificationId = transaction.id.hashCode;

    await _notifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: transaction.id, // Pass transaction ID as payload for deep linking
    );
  }



  /// Handle notification tap - navigate to transaction detail
  void _onNotificationTapped(NotificationResponse response) async {
    if (response.payload != null && navigatorKey.currentState != null) {
      final transactionId = response.payload!;
      print('Notification tapped for transaction: $transactionId');
      
      try {
        // We need to fetch the transaction object
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final boxManager = BoxManager();
          await boxManager.openAllBoxes(userId);
          final box = boxManager.getBox<Transaction>(BoxManager.transactionsBoxName, userId);
          final transaction = box.get(transactionId);
          
          if (transaction != null) {
             navigatorKey.currentState!.push(
               MaterialPageRoute(
                 builder: (context) => TransactionDetailScreen(transaction: transaction),
               ),
             );
          }
        }
      } catch (e) {
        print('Error navigating to transaction: $e');
      }
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

