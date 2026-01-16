import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/box_manager.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/account/account_model.dart';
import '../../models/app settings/app_settings.dart';
import '../../models/message_pattern/message_pattern.dart';
import '../sms_reader/sms_reader_service.dart';
import '../notification/notification_service.dart';
import '../pattern learning/pattern_learning_service.dart';

@pragma('vm:entry-point')
class BackgroundSmsService {
  static const String notificationChannelId = 'sms_monitoring_channel';
  static const int notificationId = 888;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId, // id
      'SMS Monitoring', // title
      description: 'Monitoring financial SMS messages in real-time', // description
      importance: Importance.low, // Low importance to avoid sound/vibration
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (await Permission.notification.isGranted) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // This will be executed in the isolate
        onStart: onStart,
        // Auto start service on boot
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Stratum Service',
        initialNotificationContent: 'Monitoring financial SMS...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> startMonitoring([String? userId]) async {
    final service = FlutterBackgroundService();
    
    // Store userId if provided
    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('background_service_user_id', userId);
    }
    
    if (!(await service.isRunning())) {
      await service.startService();
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    // iOS background fetch logic if needed
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Basic service setup
    DartPluginRegistrant.ensureInitialized();
    
    // Initialize things needed in background
    await Hive.initFlutter();
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('background_service_user_id');
    
    if (userId == null) {
      print('Background Service: checking for user ID...');
    }

    // Identify this service notification
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Bring to foreground
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Start the periodic check
    // 15 seconds is a good balance between "Real-time" and battery
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      await _checkForNewSms(service, userId, flutterLocalNotificationsPlugin);
    });
    
    print('Background Service: Started monitoring loop');
  }

  static Future<void> _checkForNewSms(
    ServiceInstance service, 
    String? userId,
    FlutterLocalNotificationsPlugin notificationsPlugin,
  ) async {
    // Logic to check SMS
    try {
      // Re-fetch userId if null (might have been set later)
      if (userId == null) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('background_service_user_id');
        if (userId == null) return; // Still no user, skip
      }

      // Update notification to show we are active (optional, maybe just once)
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Stratum Active",
          content: "Monitoring for financial SMS...",
        );
      }

      // Query SMS
      final query = SmsQuery();
      final messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 10, // Just check the very latest messages
      );

      if (messages.isEmpty) return;

      // Get last checked time
      final prefs = await SharedPreferences.getInstance();
      final lastCheckMillis = prefs.getInt('last_sms_check_time') ?? 
          DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
      final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMillis);

      // Filter new financial messages
      final financialSenders = {
        'MPESA', 'M-PESA', 'SAFARICOM', 'KCB', 'EQUITY', 'COOP',
        'CO-OP', 'NCBA', 'STANBIC'
      };

      final newMessages = messages.where((msg) {
        if (msg.date == null || msg.body == null) return false;
        
        // Strict date check: Only process messages strictly NEWER than last check
        final isNew = msg.date!.millisecondsSinceEpoch > lastCheckMillis;
        if (!isNew) return false;

        final address = msg.address?.toUpperCase() ?? '';
        return financialSenders.any((s) => address.contains(s));
      }).toList();

      if (newMessages.isNotEmpty) {
        print('Background Service: Found ${newMessages.length} new financial messages');
        
        // Initialize BoxManager for this isolate
        final boxManager = BoxManager();
        // Ensure boxes are open - passing userId is crucial
        await boxManager.openAllBoxes(userId);
        
        final smsReader = SmsReaderService(userId);

        for (final msg in newMessages) {
          final transaction = await smsReader.parseSmsToTransaction(
            msg.address!,
            msg.body!,
            msg.date!,
          );

          if (transaction != null) {
            // Save logic is handled inside parseSmsToTransaction -> saveTransactions?
            // Actually, in the refactored SmsReaderService, `parseSmsToTransaction` returns the object
            // but `_saveTransactions` is private. 
            // Wait, I refactored `parseSmsToTransaction` to just RETURN the transaction.
            // It calls `_parseSmsToTransaction` which calls `_parseFinancialSms`.
            // It DOES NOT save it to the database automatically in the public method I exposed?
            // Let's check the code I wrote in Step 88.
            // In Step 88, `parseSmsToTransaction` calls `_parseSmsToTransaction`.
            // `_parseSmsToTransaction` returns `Transaction?`.
            // Does it save? 
            // `_parseSmsToTransaction` finds/creates account, updates account balance, but...
            // It calls `_parseFinancialSms`.
            // It DOES update existing account with balance.
            // BUT it does NOT put the TRANSACTION into the `transactionsBox`.
            
            // I need to save it manually here!
            final transactionBox = boxManager.getBox<Transaction>(
              BoxManager.transactionsBoxName,
              userId,
            );
            
            // Check duplications again just to be safe (idempotency)
            if (!transactionBox.containsKey(transaction.id)) {
               transactionBox.put(transaction.id, transaction);
               
               // Show a rich notification
               _showLocalNotification(notificationsPlugin, transaction);
            }
          }
        }
        
        // Update last check time to the Date of the NEWEST message found
        // This prevents double processing
        final newestMsgTime = newMessages
            .map((m) => m.date!.millisecondsSinceEpoch)
            .reduce((a, b) => a > b ? a : b);
            
        await prefs.setInt('last_sms_check_time', newestMsgTime);
      } else {
        // If no new messages, update time to now to avoid scanning old stuff next boot
        // Actually, better to ONLY update if we processed something, OR if we want to move the window forward.
        // If we simply move forward, we might miss messages that arrived during the 15s sleep if we use `now()`.
        // Safe bet: Don't update `last_sms_check_time` if empty, just let it stay at last successful process 
        // OR update it to `now` ONLY if we are sure we didn't miss anything.
        // Since we query `count: 10`, if we receive 11 messages in 15 seconds we miss one. Unlikely.
        // Safe strategy: Update to `DateTime.now()`? No, keeping strict reference to message timestamps is safer.
        // But if I never receive a message, `last_sms_check_time` stays old, and I keep scanning the same old 10 messages?
        // Yes, `isNew` check handles that.
      }
      
    } catch (e) {
      print('Background Service Error: $e');
    }
  }

  static Future<void> _showLocalNotification(
    FlutterLocalNotificationsPlugin plugin,
    Transaction transaction,
  ) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'transaction_alert',
      'Transaction Alerts',
      channelDescription: 'Notifications for new transactions',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await plugin.show(
      transaction.id.hashCode,
      'New Transaction Detected',
      '${transaction.type == TransactionType.income ? '+' : '-'}${transaction.amount} from ${transaction.category}',
      platformDetails,
      payload: transaction.id,
    );
  }
}
