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
import 'package:uuid/uuid.dart';
import '../../models/notification/notification_model.dart';
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

  static bool _isRequestingBatteryExemption = false;

  static Future<void> requestBatteryExemption() async {
    if (_isRequestingBatteryExemption) return;
    _isRequestingBatteryExemption = true;

    try {
      // Request to disable battery optimization ensuring the service persists
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isDenied || status.isRestricted || status.isLimited) {
         await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      print("Warning: Could not request battery exemption: $e");
    } finally {
      _isRequestingBatteryExemption = false;
    }
  }

  static Future<void> startMonitoring([String? userId]) async {
    final service = FlutterBackgroundService();
    
    // Store userId if provided
    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('background_service_user_id', userId);
      
      // Notify running service about the user ID change immediately
      service.invoke('setUserId', {'userId': userId});
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
    BoxManager.registerAdapters();
    
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('background_service_user_id');
    
    // Listen for dynamic user ID updates from the UI isolate
    service.on('setUserId').listen((event) async {
      if (event != null && event.containsKey('userId')) {
        userId = event['userId'] as String?;
        print('Background Service: Updated User ID to $userId');
        
        // Persist it as well
        if (userId != null) {
           final p = await SharedPreferences.getInstance();
           await p.setString('background_service_user_id', userId!);
        }
      }
    });
    
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
        count: 50, // Increased from 10 to catch rapid messages or spam overflow
      );

      if (messages.isEmpty) return;

      // Get last checked time
      final prefs = await SharedPreferences.getInstance();
      final lastCheckMillis = prefs.getInt('last_sms_check_time') ?? 
          DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
      // Sanity check: If lastCheck is in the future (clock skew), reset it
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final safeLastCheckMillis = lastCheckMillis > nowMillis ? nowMillis - 3600000 : lastCheckMillis;
      
      // Filter new financial messages
      final financialSenders = {
        'MPESA', 'M-PESA', 'SAFARICOM', 'KCB', 'EQUITY', 'COOP',
        'CO-OP', 'NCBA', 'STANBIC'
      };

      final newMessages = messages.where((msg) {
        if (msg.date == null || msg.body == null) return false;
        
        // Strict date check: Only process messages strictly NEWER than last check
        final isNew = msg.date!.millisecondsSinceEpoch > safeLastCheckMillis;
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
          // Use the robust processSingleSms method which handles duplicates, 
          // account updates, and saving to Hive correctly.
          final transaction = await smsReader.processSingleSms(
            msg.address!,
            msg.body!,
            msg.date!,
          );

          if (transaction != null) {
               // Show a rich notification
               // Note: The NotificationModel is now saved inside processSingleSms
               _showLocalNotification(notificationsPlugin, transaction);
          }
        }
        
        // Update last check time to the Date of the NEWEST message found
        if (newMessages.isNotEmpty) {
           final newestMsgTime = newMessages
              .map((m) => m.date!.millisecondsSinceEpoch)
              .reduce((a, b) => a > b ? a : b);
           await prefs.setInt('last_sms_check_time', newestMsgTime);
        }
      } 
      
    } catch (e, stack) {
      print('Background Service Error: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_background_error', '${DateTime.now()}: $e\n$stack');
      } catch (_) {}
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
