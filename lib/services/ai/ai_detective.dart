import 'package:hive/hive.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stratum/services/ai/ai_service.dart';
import '../../models/budget/budget_model.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/box_manager.dart';
import '../../models/notification/notification_model.dart';
import 'package:uuid/uuid.dart';

class AIDetective {
  static final AIDetective _instance = AIDetective._internal();
  factory AIDetective() => _instance;
  AIDetective._internal();

  final BoxManager _boxManager = BoxManager();
  final AIService _aiService = AIService();
  
  // Throttle alerts to avoid spamming (Map<Category, LastAlertTime>)
  final Map<String, DateTime> _lastAlerts = {};

  Future<void> checkBudgetVelocity(Transaction transaction, String userId) async {
    // 1. Skip non-expenses
    if (transaction.type != TransactionType.expense) return;
    
    // 2. Get Budget for Category
    final budgetsBox = _boxManager.getBox<Budget>(BoxManager.budgetsBoxName, userId);
    
    // Match by category name
    Budget? budget;
    try {
      budget = budgetsBox.values.firstWhere(
        (b) => b.categoryName == transaction.categoryName
      );
    } catch (_) {
      return; // No budget for this category
    }

    // 3. Calculate Velocity
    // Note: Budget 'spentAmount' might not be updated yet if this runs concurrently?
    // We should rely on what's in the budget + this transaction if needed, 
    // BUT usually budget service updates 'spentAmount' on load. 
    // Ideally we query all transactions for this month to be accurate.
    // For MVP efficiency: Use Budget's last known 'spentAmount' + this transaction.amount
    
    final currentSpent = budget.spentAmount + transaction.amount; // Optimistic calculation
    final limit = budget.limitAmount;
    
    if (limit == 0) return;

    final percentSpent = currentSpent / limit;
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final percentMonthElapsed = dayOfMonth / 30.0; // Approx

    // Threshold: Spending is 15% ahead of time
    // e.g. Day 1 (3%) -> Spent 20% -> Trigger
    // e.g. Day 15 (50%) -> Spent 70% -> Trigger
    // Also ignore small amounts or if budget is nearly done at end of month
    
    if (percentSpent > (percentMonthElapsed + 0.15)) {
       // TRIGGER ALERT
       await _triggerAlert(
         userId: userId,
         category: budget.categoryName,
         spent: currentSpent,
         limit: limit,
         day: dayOfMonth,
         transactionId: transaction.id
       );
    }
  }

  Future<void> _triggerAlert({
    required String userId,
    required String category,
    required double spent,
    required double limit,
    required int day,
    required String transactionId,
  }) async {
    // Throttle: Don't alert same category more than once every 3 days
    final lastAlert = _lastAlerts[category];
    if (lastAlert != null && DateTime.now().difference(lastAlert).inDays < 3) {
      return;
    }
    
    // Generate Text
    final message = await _aiService.generateBudgetAlert(
      category: category,
      spent: spent,
      limit: limit,
      dayOfMonth: day,
    );
    
    if (message == null) return;
    
    // Create Notification Record
    final notificationsBox = _boxManager.getBox<NotificationModel>(
      BoxManager.notificationsBoxName,
      userId,
    );
    
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: 'Budget Alert: $category',
      body: message,
      timestamp: DateTime.now(),
      transactionId: transactionId, // Link to the causing transaction
      isRead: false,
    );
    
    notificationsBox.put(notification.id, notification);
    _lastAlerts[category] = DateTime.now();
    
    // Show Visual Notification
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'AI Budget Warnings',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(
      notification.id.hashCode,
      'Budget Watchdog 🐶',
      message,
      platformDetails,
      payload: transactionId,
    );
  }
}
