import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for user-scoping
import '../models/account/account_model.dart';
import '../models/transaction/transaction_model.dart';
import '../models/account/account_snapshot.dart';
import 'app settings/app_settings.dart';
import 'message_pattern/message_pattern.dart';
import 'budget/budget_model.dart';
import 'savings/savings_goal_model.dart';
import 'notification/notification_model.dart';
import 'ai/chat_message_model.dart';
import 'ai/chat_session_model.dart';
import 'investment/investment_model.dart';


class BoxManager {
  static final BoxManager _instance = BoxManager._internal();
  factory BoxManager() => _instance;
  BoxManager._internal();

  static const String accountsBoxName = 'accounts';
  static const String transactionsBoxName = 'transactions';
  static const String settingsBoxName = 'appSettings';
  static const String accountSnapshotBoxName = 'account_snapshots';
  static const String patternsBoxName = 'message_patterns';
  static const String budgetsBoxName = 'budgets';
  static const String savingsGoalsBoxName = 'savings_goals';
  static const String notificationsBoxName = 'notifications';
  static const String chatBoxName = 'chat_messages';
  static const String chatSessionBoxName = 'chat_sessions';
  static const String investmentsBoxName = 'investments';

  // Helper to get the user-scoped box name
  static String _getScopedBoxName(String baseName, String userId) {
    return '${baseName}_$userId';
  }

  // Use a map to track open boxes per user ID to avoid opening twice
  final Map<String, Map<String, bool>> _openBoxes = {};

  // Register all adapters
  static void registerAdapters() {
    // IDs MUST match the @HiveType(typeId: X) in your models

    // Transaction Models
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionAdapter()); // ID 1
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TransactionTypeAdapter()); // ID 2
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TransactionCategoryAdapter()); // ID 3

    // App Settings
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(AppSettingsAdapter()); // ID 4

    // Account Models
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(AccountTypeAdapter()); // ID 6
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(AccountAdapter()); // ID 7

    // Snapshot
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(AccountSnapshotAdapter()); // ID 8 (Fixed from 5)
    
    // Message Pattern
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(MessagePatternAdapter()); // ID 9

    // Budgets & Savings (Phase 7)
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(BudgetAdapter()); // ID 5
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(SavingsGoalAdapter()); // ID 10
    
    // Notification (Phase 9)
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(NotificationModelAdapter()); // ID 11
    if (!Hive.isAdapterRegistered(21)) Hive.registerAdapter(ChatMessageModelAdapter()); // ID 21
    if (!Hive.isAdapterRegistered(22)) Hive.registerAdapter(ChatSessionModelAdapter()); // ID 22
    if (!Hive.isAdapterRegistered(23)) Hive.registerAdapter(InvestmentTypeAdapter()); // ID 23
    if (!Hive.isAdapterRegistered(24)) Hive.registerAdapter(InvestmentModelAdapter()); // ID 24
  }

  Future<void> openAllBoxes(String userId) async {
    _openBoxes[userId] = _openBoxes[userId] ?? {};

    await _openBoxInternal<Account>(accountsBoxName, userId);
    await _openBoxInternal<Transaction>(transactionsBoxName, userId);
    await _openBoxInternal<AppSettings>(settingsBoxName, userId);
    await _openBoxInternal<AccountSnapshot>(accountSnapshotBoxName, userId);
    await _openBoxInternal<MessagePattern>(patternsBoxName, userId);
    await _openBoxInternal<Budget>(budgetsBoxName, userId);
    await _openBoxInternal<SavingsGoal>(savingsGoalsBoxName, userId);
    await _openBoxInternal<NotificationModel>(notificationsBoxName, userId);
    await _openBoxInternal<ChatMessageModel>(chatBoxName, userId);
    await _openBoxInternal<ChatSessionModel>(chatSessionBoxName, userId);
    await _openBoxInternal<InvestmentModel>(investmentsBoxName, userId);
  }

  Future<void> _openBoxInternal<T>(String baseName, String userId) async {
    final scopedName = _getScopedBoxName(baseName, userId);

    // Only open if not already tracked as open AND Hive says it's closed
    if (!(_openBoxes[userId]?[baseName] ?? false) || !Hive.isBoxOpen(scopedName)) {
      try {
        await Hive.openBox<T>(scopedName);
        _openBoxes[userId]![baseName] = true;
      } catch (e) {
        print('Error opening Hive box $scopedName: $e');
        _openBoxes[userId]![baseName] = false;
        // In production, you might want to handle Hive corruption here (e.g., delete and recreate)
      }
    }
  }

  Box<T> getBox<T>(String baseName, String userId) {
    final scopedName = _getScopedBoxName(baseName, userId);
    if (!Hive.isBoxOpen(scopedName)) {
      // Fallback: attempt to open if closed (safety mechanism)
      // Note: This is async in reality, but getBox is sync.
      // Ideally, ensure openAllBoxes is called before this.
      throw Exception('Box $scopedName is not open for user $userId. Call openAllBoxes first.');
    }
    return Hive.box<T>(scopedName);
  }

  // Close all boxes for the current user (used on sign-out)
  Future<void> closeAllBoxes(String userId) async {
    if (_openBoxes.containsKey(userId)) {
      // We use a try-catch block for each to ensure one failure doesn't stop the others
      try { await Hive.box<Account>(_getScopedBoxName(accountsBoxName, userId)).close(); } catch(e) { print(e); }
      try { await Hive.box<Transaction>(_getScopedBoxName(transactionsBoxName, userId)).close(); } catch(e) { print(e); }
      try { await Hive.box<AppSettings>(_getScopedBoxName(settingsBoxName, userId)).close(); } catch(e) { print(e); }
      try { await Hive.box<AccountSnapshot>(_getScopedBoxName(accountSnapshotBoxName, userId)).close(); } catch(e) { print(e); }
      try { await Hive.box<MessagePattern>(_getScopedBoxName(patternsBoxName, userId)).close(); } catch(e) { print(e); }
      try { await Hive.box<ChatMessageModel>(_getScopedBoxName(chatBoxName, userId)).close(); } catch(e) { print(e); }
      try { await Hive.box<ChatSessionModel>(_getScopedBoxName(chatSessionBoxName, userId)).close(); } catch(e) { print(e); }
      try { await Hive.box<InvestmentModel>(_getScopedBoxName(investmentsBoxName, userId)).close(); } catch(e) { print(e); }

      _openBoxes.remove(userId);
    }
  }
}

// Global accessor
final BoxManager boxManager = BoxManager();