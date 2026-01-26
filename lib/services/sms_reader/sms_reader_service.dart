import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/box_manager.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/account/account_model.dart';
import '../pattern learning/pattern_learning_service.dart';
import '../pattern learning/pattern_learning_service.dart';
import 'unified_transaction_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notification/notification_model.dart';
import '../../services/ai/ai_detective.dart';

/// Progress data for SMS scanning
class SmsReadProgress {
  final int totalMessages;
  final int processedMessages;
  final int transactionsFound;
  final bool isComplete;
  final bool hasError;
  final String status;

  SmsReadProgress({
    required this.totalMessages,
    required this.processedMessages,
    required this.transactionsFound,
    this.isComplete = false,
    this.hasError = false,
    this.status = '',
  });

  double get progress =>
      totalMessages > 0 ? processedMessages / totalMessages : 0.0;
}

class SmsReaderService {
  final SmsQuery _query = SmsQuery();
  final BoxManager _boxManager = BoxManager();
  final String userId;
  final UnifiedTransactionParser _unifiedParser = UnifiedTransactionParser();

  SmsReaderService(this.userId);

  void setUserNames(List<String> names) {
    _unifiedParser.setUserNames(names);
  }

  /// Request SMS permission from user
  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Check if SMS permission is granted
  Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Scan all messages with progress updates (Main method for new design)
  Stream<SmsReadProgress> scanAllMessages() async* {
    try {
      await _boxManager.openAllBoxes(userId);

      // Get all SMS messages
      final List<SmsMessage> messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 10000, // Read up to 10k messages
      );

      yield SmsReadProgress(
        totalMessages: messages.length,
        processedMessages: 0,
        transactionsFound: 0,
        status: 'Starting scan...',
      );

      int processedCount = 0;
      int transactionsFound = 0;
      final List<Transaction> allTransactions = [];
      final Set<String> financialSenders = {
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

      // Process in batches for better performance
      const batchSize = 100;
      for (int i = 0; i < messages.length; i += batchSize) {
        final batch = messages.skip(i).take(batchSize).toList();

        for (final message in batch) {
          // Only process messages from financial institutions
          final address = message.address?.toUpperCase() ?? '';
          final isFinancial = financialSenders.any(
            (sender) => address.contains(sender),
          );

          if (isFinancial && message.body != null) {
            final transaction = await _parseSmsToTransaction(
              message.address!,
              message.body!,
              message.date ?? DateTime.now(),
            );

            if (transaction != null) {
              allTransactions.add(transaction);
              transactionsFound++;
            }
          }

          processedCount++;

          // Yield progress update every 50 messages or on last message
          if (processedCount % 50 == 0 || processedCount == messages.length) {
            yield SmsReadProgress(
              totalMessages: messages.length,
              processedMessages: processedCount,
              transactionsFound: transactionsFound,
              status: 'Processing messages...',
            );
          }
        }
      }

      // Save all transactions to database
      if (allTransactions.isNotEmpty) {
        await _saveTransactions(allTransactions);
      }

      // Final yield - complete
      yield SmsReadProgress(
        totalMessages: messages.length,
        processedMessages: messages.length,
        transactionsFound: transactionsFound,
        isComplete: true,
        status: 'Complete!',
      );
    } catch (e) {
      yield SmsReadProgress(
        totalMessages: 0,
        processedMessages: 0,
        transactionsFound: 0,
        hasError: true,
        status: 'Error: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Discover financial accounts from SMS history
  Future<List<Account>> discoverAccounts() async {
    try {
      await _boxManager.openAllBoxes(userId);
      final accountsBox = _boxManager.getBox<Account>(
        BoxManager.accountsBoxName,
        userId,
      );

      // Get recent messages (check enough to find banks, e.g. 500)
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500,
      );

      final Set<String> knownBanks = {
        'KCB',
        'EQUITY',
        'COOP',
        'CO-OP', // Maps to COOP
        'NCBA',
        'STANBIC',
        'ABSA',
        'MPESA', 
        'M-PESA'
      };

      final List<Account> newAccounts = [];
      final Set<String> processedSenders = {};

      for (final msg in messages) {
        final address = msg.address?.toUpperCase() ?? '';
        
        // Check if this is a known bank
        String? matchedBank;
        for (final bank in knownBanks) {
          if (address.contains(bank)) {
            matchedBank = bank;
            break;
          }
        }

        if (matchedBank != null && !processedSenders.contains(matchedBank)) {
          processedSenders.add(matchedBank);

          // normalize name
          String accountName = matchedBank;
          if (accountName == 'M-PESA') accountName = 'MPESA';
          if (accountName == 'CO-OP') accountName = 'COOP';

          // Check if we already have an account for this bank
          final exists = accountsBox.values.any((acc) => 
            acc.name.toUpperCase() == accountName || 
            (acc.senderAddress != null && acc.senderAddress!.toUpperCase().contains(accountName))
          );

          if (!exists) {
            // Found a NEW account candidates!
            // Validate Ownership: Do we have "Balance", "Your Account", "Credited/Debited to your" in any message?
            bool isOwnedAccount = false;
            
            // Check the messages from this sender
            final senderMessages = messages.where((m) => (m.address?.toUpperCase() ?? '').contains(matchedBank!));
            
            for (final m in senderMessages) {
              final body = m.body?.toLowerCase() ?? '';
              // STROK: Only consider it an account if we see explicit balance or account indicators
              // We avoid "Your M-Pesa payment" (which is just a receipt)
              if (body.contains('avail bal') || 
                  body.contains('available balance') ||
                  body.contains('new m-pesa balance') ||
                  (body.contains('balance') && (body.contains('is') || body.contains(':'))) ||
                  body.contains('credited to your account') ||
                  body.contains('debited from your account') ||
                  body.contains('withdraw') && body.contains('from')) {
                  isOwnedAccount = true;
                  break;
              }
            }

            if (isOwnedAccount) {
              final newAccount = Account(
                id: const Uuid().v4(),
                name: accountName, // Use the matched bank name as default
                balance: 0.0, // We can't know the balance yet without parsing
                type: accountName == 'MPESA' ? AccountType.Mpesa : AccountType.Bank,
                lastUpdated: DateTime.now(),
                senderAddress: address, // Store the specific sender address we found
                isAutomated: true,
              );
              
              accountsBox.put(newAccount.id, newAccount);
              newAccounts.add(newAccount);
            }
          }
        }
      }

      return newAccounts;

    } catch (e) {
      print('Error discovering accounts: $e');
      return [];
    }
  }

  /// Reconcile balances for a specific account using Anchor & Delta logic
  Future<void> reconcileBalances(String accountId) async {
    try {
      await _boxManager.openAllBoxes(userId);
      final transactionsBox = _boxManager.getBox<Transaction>(
        BoxManager.transactionsBoxName,
        userId,
      );
      final accountsBox = _boxManager.getBox<Account>(
        BoxManager.accountsBoxName,
        userId,
      );

      final account = accountsBox.get(accountId);
      if (account == null) return;

      // 1. Get all transactions for this account
      final transactions = transactionsBox.values
          .where((t) => t.accountId == accountId)
          .toList();

      // 2. Sort by date ASCENDING (oldest first)
      transactions.sort((a, b) => a.date.compareTo(b.date));

      double runningBalance = 0.0;
      bool hasAnchor = false;

      // 3. Replay history
      for (final t in transactions) {
        // If this transaction has an explicit balance (Anchor), use it.
        // We assume the explicit balance *includes* the effect of this transaction.
        if (t.newBalance != null && t.newBalance! > 0) {
          runningBalance = t.newBalance!;
          hasAnchor = true;
        } else {
          // No explicit balance, apply Delta
          // If we haven't found an anchor yet, we might be starting from 0 or unknown.
          // Ideally, we wait for the first anchor. But if we must show something:
          if (t.type == TransactionType.income) {
            runningBalance += t.amount;
          } else {
            runningBalance -= t.amount;
          }
        }
      }

      // 4. Update Account
      if (hasAnchor || transactions.isNotEmpty) {
        final updatedAccount = account.copyWith(
          balance: runningBalance,
          lastUpdated: DateTime.now(),
        );
        accountsBox.put(accountId, updatedAccount);
        print('Reconciled Account: ${account.name} -> KES $runningBalance');
      }

    } catch (e) {
      print('Error reconciling balances for $accountId: $e');
    }
  }

  /// Scan recent messages (e.g. last 20) and save any new ones found.
  /// Useful for Pull-to-Refresh or On-Resume checks.
  Future<int> scanRecentMessages({int count = 20}) async {
    try {
      await _boxManager.openAllBoxes(userId);
      const scanKey = 'last_sms_scan_timestamp';
      final prefs = await SharedPreferences.getInstance();
      final lastScanTimeMs = prefs.getInt(scanKey);
      final lastScanDate = lastScanTimeMs != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastScanTimeMs) 
          : null;

      // Always scan at least 5 minutes back to catch any delays, even if we scanned recently
      // Or if no scan time, fallback to count
      
      print('Scanning recent messages. Last scan: $lastScanDate');

      // Update parser with current user names for self-transfer detection
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
        _unifiedParser.setUserNames(user.displayName!.split(' '));
      }

      // Note: flutter_sms_inbox doesn't support server-side filtering by date reliably across all Android versions
      // So we fetch a batch and filter client-side.
      
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: count, // Still limit count for performance, but maybe increase default if optimizing
      );

      // Update scan time immediately after successful query
      await prefs.setInt(scanKey, DateTime.now().millisecondsSinceEpoch);

      int transactionsFound = 0;
      final List<Transaction> allTransactions = [];
      final Set<String> financialSenders = {
        'MPESA', 'M-PESA', 'SAFARICOM', 'KCB', 'EQUITY', 'COOP',
        'CO-OP', 'NCBA', 'STANBIC',
      };

      for (final message in messages) {
        // OPTIMIZATION: Stop if we reach a message older than our last scan
        // Add a small buffer (e.g. 1 minute) to account for processing time differences
        if (lastScanDate != null && 
            message.date != null && 
            message.date!.isBefore(lastScanDate.subtract(const Duration(minutes: 1)))) {
           // We reached messages we've likely already processed
           // continue; // Don't just break, we might have out-of-order delivery? 
           // actually, SMS inbox is usually sorted by date desc. 
           // But to be safe against slight time diffs, let's just ignore this one.
           continue; 
        }

        final address = message.address?.toUpperCase() ?? '';
        final isFinancial = financialSenders.any((s) => address.contains(s));

        if (isFinancial && message.body != null) {
          final transaction = await _parseSmsToTransaction(
            message.address!,
            message.body!,
            message.date ?? DateTime.now(),
          );
          
          if (transaction != null) {
            allTransactions.add(transaction);
            transactionsFound++;
          }
        }
      }

      if (allTransactions.isNotEmpty) {
        // Recent scan (Live) -> Enable Auto Transfers (Cash creation)
        await _saveTransactions(allTransactions, enableAutoTransfers: true);
      }
      
      return transactionsFound;
    } catch (e) {
      print('Error scanning recent messages: $e');
      return 0;
    }
  }

  /// Legacy method - kept for backward compatibility
  Stream<SmsReadProgress> readAllSms() async* {
    yield* scanAllMessages();
  }

  /// Normalize sender address to handle variations (MPESA, M-PESA, SAFARICOM all map to MPESA)
  String _getStandardizedAccountName(String accountType) {
    final upperType = accountType.toUpperCase();
    if (upperType.contains('MPESA') || upperType.contains('M-PESA')) {
      return 'MPESA';
    }
    return upperType;
  }

  /// Parse SMS to Transaction (public method for background service)
  Future<Transaction?> parseSmsToTransaction(
    String address,
    String body,
    DateTime date,
  ) async {
    return await _parseSmsToTransaction(address, body, date);
  }

  /// Parse SMS to Transaction (private implementation)
  Future<Transaction?> _parseSmsToTransaction(
    String address,
    String body,
    DateTime date,
  ) async {
    // Strict filtering for non-transactional messages
    final lowerBody = body.toLowerCase();
    if (lowerBody.contains('failed') || 
        lowerBody.contains('incomplete') || 
        lowerBody.contains('initiate') || 
        lowerBody.contains('incorrect') ||
        lowerBody.contains('insufficient funds')) {
      return null;
    }

    final normalizedAddress = address.toUpperCase().trim();
    // print('Parsing SMS from address: $address (normalized: $normalizedAddress)');

    String? accountType;
    if (normalizedAddress.contains('MPESA') || normalizedAddress == 'MPESA') {
      accountType = 'MPESA';
    } else if (normalizedAddress.contains('KCB')) {
      accountType = 'KCB';
    } else if (normalizedAddress.contains('EQUITY')) {
      accountType = 'EQUITY';
    } else if (normalizedAddress.contains('COOP') ||
        normalizedAddress.contains('CO-OP')) {
      accountType = 'COOP';
    } else if (normalizedAddress.contains('NCBA')) {
      accountType = 'NCBA';
    } else if (normalizedAddress.contains('STANBIC')) {
      accountType = 'STANBIC';
    } else {
      return null;
    }

    // Get or create account
    final accountsBox = _boxManager.getBox<Account>(
      BoxManager.accountsBoxName,
      userId,
    );

    // Standardize the name to find existing accounts reliably
    final standardizedName = _getStandardizedAccountName(accountType);
    
    // Find existing account by standardized name
    Account? account;
    try {
      account = accountsBox.values.firstWhere(
        (acc) => acc.name == standardizedName,
      );
    } catch (_) {
      // No account found
    }
    // SOURCE OF TRUTH CHECK
    // If it's a Bank (not MPESA) and we don't track it yet, IGNORE IT.
    // This prevents "Ghost Accounts" from duplicate confirmations.
    if (accountType != 'MPESA' && account == null) {
      // Exception: If the user specifically added a pattern for this sender, we might want to allow it?
      // For now, adhere to the strict rule: Valid Account MUST exist for Banks.
      return null;
    }

    if (account != null) {
      // Ensure account type is correct
      final correctType = accountType == 'MPESA'
          ? AccountType.Mpesa
          : AccountType.Bank;
          
      bool needsUpdate = false;
      Account updatedAccount = account;

      if (account.type != correctType) {
        updatedAccount = updatedAccount.copyWith(type: correctType);
        needsUpdate = true;
      }
      
      // Update sender address if we have a more specific one
      if (account.senderAddress != address) {
         updatedAccount = updatedAccount.copyWith(senderAddress: address);
         needsUpdate = true;
      }

      if (needsUpdate) {
        accountsBox.put(account.id, updatedAccount);
        account = updatedAccount;
      }
    } else {
      // Only create new account for MPESA automatically
      // OR if we implement a "Pending Review" bin later.
      if (accountType == 'MPESA') {
        print('Creating new account for $standardizedName');
        
        final newAccount = Account(
          id: const Uuid().v4(),
          name: standardizedName,
          balance: 0.0,
          type: AccountType.Mpesa,
          lastUpdated: DateTime.now().toLocal(),
          senderAddress: address,
          isAutomated: true,
        );
        accountsBox.put(newAccount.id, newAccount);
        account = newAccount;
      } else {
        return null; // Should be caught by Source of Truth check above, but safety first
      }
    }

    // Parse using unified parser
    final transaction = await _unifiedParser.parseMessage(
      address: address,
      body: body,
      date: date,
      accountId: account.id,
      userId: userId,
      accountType: accountType,
    );

    // we don't update balance here, we do it in saveTransactions to be safe and efficient
    
    return transaction;
  }



  /// Save transactions and update account balances
  Future<void> _saveTransactions(
    List<Transaction> transactions, {
    bool enableAutoTransfers = false,
  }) async {
    if (transactions.isEmpty) return;

    await _boxManager.openAllBoxes(userId);
    final transactionsBox = _boxManager.getBox<Transaction>(
      BoxManager.transactionsBoxName,
      userId,
    );
    final accountsBox = _boxManager.getBox<Account>(
      BoxManager.accountsBoxName,
      userId,
    );

    // Save all transactions
    final Set<String> affectedAccountIds = {};
    
    for (var transaction in transactions) {
      // Logic for Historical vs Future Transfers
      Transaction finalTransaction = transaction;

      if (!enableAutoTransfers && transaction.type == TransactionType.transfer) {
         // Downgrade Transfer -> Expense for historical data
         // This prevents creating Cash accounts for old withdrawals
         finalTransaction = transaction.copyWith(
           type: TransactionType.expense,
           // Keep category as 'transfer' or change to 'general'? 
           // Leave category as transfer so user sees "Transfer" icon but logic treats as Expense (No counterpart)
         );
      }

      // Check for duplicates using finalTransaction
      final isDuplicate = transactionsBox.values.any(
        (t) =>
            t.date.millisecondsSinceEpoch ==
                finalTransaction.date.millisecondsSinceEpoch &&
            t.amount == finalTransaction.amount &&
            t.accountId == finalTransaction.accountId,
      );

      if (!isDuplicate) {
        transactionsBox.put(finalTransaction.id, finalTransaction);
        if (finalTransaction.accountId != null) {
          affectedAccountIds.add(finalTransaction.accountId!);
        }

        // Handle Transfer Logic (Auto-create Cash Deposit) - ONLY IF ENABLED
        if (enableAutoTransfers && finalTransaction.type == TransactionType.transfer) {
          await _handleTransferCounterpart(finalTransaction, accountsBox, transactionsBox, affectedAccountIds);
        }
      }
    }
    
    // Trigger reconciliation for all affected accounts
    for (final accountId in affectedAccountIds) {
      await reconcileBalances(accountId);
      
      // Also force recalculation to be safe (since we might have added a counterpart)
      // This is slightly inefficient but specific to the updated accounts
      // _recalculateBalancesFromTransactions handles the "Anchor + Delta" logic correctly.
      // We can rely on _recalculateBalancesFromTransactions being called generally or just rely on this:
    }
    
    // Ensuring global consistency
    _recalculateBalancesFromTransactions(accountsBox, transactionsBox);
  }

  /// Helper to handle Transfer counterparts (e.g. MPESA Withdrawal -> Cash Deposit)
  Future<void> _handleTransferCounterpart(
    Transaction original,
    Box<Account> accountsBox,
    Box<Transaction> transactionsBox,
    Set<String> affectedAccountIds,
  ) async {
    // 1. Find or Create 'Cash' account
    Account? cashAccount;
    try {
      cashAccount = accountsBox.values.firstWhere(
        (a) => a.name.toUpperCase() == 'CASH' || a.name.toUpperCase() == 'WALLET',
      );
    } catch (_) {
      // Create if missing
      cashAccount = Account(
        id: const Uuid().v4(),
        name: 'Cash',
        balance: 0.0,
        type: AccountType.Cash,
        lastUpdated: DateTime.now(),
        senderAddress: 'MANUAL', // Required field
        isAutomated: true,
      );
      accountsBox.put(cashAccount.id, cashAccount);
    }

    // 2. Create Counterpart Transaction (Income)
    // Check if counterpart already exists to avoid duplication
    final isDuplicate = transactionsBox.values.any((t) => 
        t.reference == original.reference && 
        t.accountId == cashAccount!.id &&
        t.type == TransactionType.income
    );

    if (!isDuplicate) {
      final counterpart = Transaction(
        id: const Uuid().v4(),
        title: 'Transfer from ${original.recipient ?? "Account"}', 
        amount: original.amount, 
        type: TransactionType.income, 
        category: TransactionCategory.transfer,
        recipient: 'Self',
        date: original.date, 
        accountId: cashAccount!.id,
        description: 'Auto-transfer from Withdrawal',
        reference: original.reference,
      );
      
      transactionsBox.put(counterpart.id, counterpart);
      affectedAccountIds.add(cashAccount.id);
    }
  }

  /// Process a single new SMS message
  Future<Transaction?> processSingleSms(
    String address,
    String body,
    DateTime date,
  ) async {
    final transaction = await _parseSmsToTransaction(address, body, date);

    if (transaction != null) {
      await _boxManager.openAllBoxes(userId);
      final transactionsBox = _boxManager.getBox<Transaction>(
        BoxManager.transactionsBoxName,
        userId,
      );

      // Check for duplicates
      final isDuplicate = transactionsBox.values.any(
        (t) =>
            t.date.millisecondsSinceEpoch ==
                transaction.date.millisecondsSinceEpoch &&
            t.amount == transaction.amount &&
            t.accountId == transaction.accountId,
      );

      if (!isDuplicate) {
        transactionsBox.put(transaction.id, transaction);

        // Update account balance
        final accountsBox = _boxManager.getBox<Account>(
          BoxManager.accountsBoxName,
          userId,
        );

        try {
          final account = accountsBox.values.firstWhere(
            (acc) => acc.id == transaction.accountId,
          );

          if (transaction.newBalance != null) {
            final updated = account.copyWith(
              balance: transaction.newBalance!,
              lastUpdated: transaction.date,
            );
            accountsBox.put(account.id, updated);
          }
        } catch (e) {
          // Account not found
        }
        
        // Create Notification Record (Centralized Logic)
        final notificationsBox = _boxManager.getBox<NotificationModel>(
          BoxManager.notificationsBoxName,
          userId,
        );

        final notification = NotificationModel(
          id: const Uuid().v4(),
          title: 'New Transaction',
          body: '${transaction.type == TransactionType.income ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} from ${transaction.title}',
          timestamp: DateTime.now(),
          transactionId: transaction.id,
          isRead: false,
        );
        notificationsBox.put(notification.id, notification);

        // AI Watchdog Check (Fire and forget)
        AIDetective().checkBudgetVelocity(transaction, userId).catchError((e) {
          print('AI Watchdog Error: $e');
        });
      }
      return transaction;
    }
    return null;
  }

  /// Recalculate account balances from all transactions
  void _recalculateBalancesFromTransactions(
    Box<Account> accountsBox,
    Box<Transaction> transactionsBox,
  ) {
    // Group by account
    final Map<String, List<Transaction>> accountTransactions = {};
    for (var t in transactionsBox.values) {
      accountTransactions.putIfAbsent(t.accountId, () => []).add(t);
    }

    // Process each account
    for (var entry in accountTransactions.entries) {
      final accountId = entry.key;
      final txs = entry.value;
      
      // Sort chronological (Oldest First)
      txs.sort((a, b) => a.date.compareTo(b.date));

      double currentBalance = 0.0;
      DateTime? lastUpdate;
      
      // We need to find the *latest* anchor point to be efficient, or just replay all.
      // Replaying all is safer to ensure consistency.
      
      for (var t in txs) {
        if (t.newBalance != null) {
          // Anchor Point: Reset balance
          currentBalance = t.newBalance!;
        } else {
          // Delta Point: Apply change
          if (t.type == TransactionType.income) {
            currentBalance += t.amount;
          } else {
            currentBalance -= t.amount;
          }
        }
        lastUpdate = t.date;
      }

      try {
        final account = accountsBox.values.firstWhere(
          (acc) => acc.id == accountId,
        );

        // Only update if changed or newer
        // (Floating point comparison epsilon check ideally, but direct is fine for now)
        if (account.balance != currentBalance) {
           final updated = account.copyWith(
            balance: currentBalance,
            lastUpdated: lastUpdate ?? account.lastUpdated,
          );
          accountsBox.put(account.id, updated);
          print('Reconciled Account: ${account.name} -> KES $currentBalance');
        }
      } catch (e) {
        // Account not found, skip
      }
    }
  }
}
