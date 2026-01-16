import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../../models/box_manager.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/account/account_model.dart';
import '../pattern learning/pattern_learning_service.dart';

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

  SmsReaderService(this.userId);

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

  /// Scan recent messages (e.g. last 20) and save any new ones found.
  /// Useful for Pull-to-Refresh or On-Resume checks.
  Future<int> scanRecentMessages({int count = 20}) async {
    try {
      await _boxManager.openAllBoxes(userId);
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: count,
      );

      int transactionsFound = 0;
      final List<Transaction> allTransactions = [];
      final Set<String> financialSenders = {
        'MPESA', 'M-PESA', 'SAFARICOM', 'KCB', 'EQUITY', 'COOP',
        'CO-OP', 'NCBA', 'STANBIC',
      };

      for (final message in messages) {
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
        await _saveTransactions(allTransactions);
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

  /// Normalize sender address for account matching purposes
  String _normalizeSenderAddress(String address, String? accountType) {
    // For now, normalize by account type to match accounts of the same type
    return accountType ?? 'UNKNOWN';
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
      // No matching account found, create new one
      print('Creating new account for $standardizedName');
      
      final newAccount = Account(
        id: const Uuid().v4(),
        name: standardizedName,
        balance: 0.0,
        type: accountType == 'MPESA' ? AccountType.Mpesa : AccountType.Bank,
        lastUpdated: DateTime.now().toLocal(),
        senderAddress: address,
        isAutomated: true,
      );
      accountsBox.put(newAccount.id, newAccount);
      account = newAccount;
    }

    // Parse using patterns
    final transaction = _parseFinancialSms(
      address,
      body,
      date,
      account.id,
      accountType,
    );

    // we don't update balance here, we do it in saveTransactions to be safe and efficient
    
    return transaction;
  }

  /// Parse financial SMS using patterns
  Transaction? _parseFinancialSms(
    String address,
    String body,
    DateTime date,
    String accountId,
    String accountType,
  ) {
    // Check for learned pattern first
    final pattern = PatternLearningService.learnPattern(body, '');
    final learnedCategory = PatternLearningService.getCategoryForPattern(
      pattern,
      accountType,
      userId,
    );

    if (accountType == 'MPESA') {
      return _parseMpesaSms(body, date, accountId, learnedCategory);
    } else if (accountType == 'KCB') {
      return _parseKcbSms(body, date, accountId, learnedCategory);
    }

    return null;
  }

  /// Parse MPESA SMS
  Transaction? _parseMpesaSms(
    String body,
    DateTime date,
    String accountId,
    String? learnedCategory,
  ) {
    const uuid = Uuid();

    // M-PESA Patterns
    final mpesaSentPattern = RegExp(
      r'([A-Z0-9]+)\s+Confirmed\.\s*Ksh([\d,]+\.\d{2})\s+(?:paid to|sent to)\s+([^.]+?)(?:\s+on\s+[\d/]+\s+at\s+[\d:]+\s+[AP]M)?\.?\s*New M-PESA balance is Ksh([\d,]+\.\d{2})',
      caseSensitive: false,
    );

    final mpesaReceivedPattern = RegExp(
      r'([A-Z0-9]+)\s+Confirmed\.?\s*You have received Ksh([\d,]+\.\d{2})\s+from\s+([^.]+?)(?:\s+[\d/]+\s+at\s+[\d:]+\s+[AP]M)?\.?\s*New M-PESA balance is Ksh([\d,]+\.\d{2})',
      caseSensitive: false,
    );

    final mpesaWithdrawPattern = RegExp(
      r'([A-Z0-9]+)\s+[Cc]onfirmed\.?\s*Ksh([\d,]+\.\d{2})\s+withdrawn from\s+([^.]+?)(?:\s+on\s+[\d/]+)?\.?\s*New M-PESA balance is Ksh([\d,]+\.\d{2})',
      caseSensitive: false,
    );

    final mpesaBuyPattern = RegExp(
      r'([A-Z0-9]+)\s+confirmed\.?\s*You bought Ksh([\d,]+\.\d{2})\s+of\s+([^.]+?)(?:\s+on\s+[\d/]+\s+at\s+[\d:]+)?\.?\s*New M-PESA balance is Ksh([\d,]+\.\d{2})',
      caseSensitive: false,
    );
    
    // New regex for simple airtime purchase: "You bought Ksh 20.00 of airtime on..."
    final mpesaAirtimePattern = RegExp(
      r'([A-Z0-9]+)\s+Confirmed\.?\s*You\s+bought\s+Ksh([\d,]+\.\d{2})\s+of\s+airtime\s+on\s+[\d/]+\s+at\s+[\d:]+\s+[AP]M\.?\s*New M-PESA balance is Ksh([\d,]+\.\d{2})',
      caseSensitive: false,
    );

    double parseAmount(String amountStr) {
      return double.parse(amountStr.replaceAll(',', ''));
    }

    TransactionCategory categorizeRecipient(String recipient) {
      final lower = recipient.toLowerCase();
      if (lower.contains('safaricom') || lower.contains('airtime')) {
        return TransactionCategory.utilities;
      }
      if (lower.contains('kplc') ||
          lower.contains('power') ||
          lower.contains('electricity')) {
        return TransactionCategory.utilities;
      }
      if (lower.contains('water')) return TransactionCategory.utilities;
      if (lower.contains('rent')) return TransactionCategory.other;
      if (lower.contains('pharmacy') ||
          lower.contains('hospital') ||
          lower.contains('clinic')) {
        return TransactionCategory.health;
      }
      if (lower.contains('school') ||
          lower.contains('university') ||
          lower.contains('college')) {
        return TransactionCategory.other;
      }
      if (lower.contains('supermarket') ||
          lower.contains('shop') ||
          lower.contains('store')) {
        return TransactionCategory.shopping;
      }
      if (lower.contains('restaurant') ||
          lower.contains('cafe') ||
          lower.contains('hotel')) {
        return TransactionCategory.dining;
      }
      if (lower.contains('agent')) return TransactionCategory.other;
      return TransactionCategory.general;
    }

    // Try sent/paid pattern
    var match = mpesaSentPattern.firstMatch(body);
    if (match != null) {
      final reference = match.group(1)!;
      final amount = parseAmount(match.group(2)!);
      final recipient = match.group(3)!.trim();
      final balance = parseAmount(match.group(4)!);

      TransactionCategory category = learnedCategory != null
          ? (PatternLearningService.categoryFromString(learnedCategory) ??
                categorizeRecipient(recipient))
          : categorizeRecipient(recipient);

      return Transaction(
        id: uuid.v4(),
        title: recipient,
        amount: amount,
        type: TransactionType.expense,
        category: category,
        recipient: recipient,
        originalSms: body,
        newBalance: balance,
        date: date,
        accountId: accountId,
        reference: reference,
      );
    }

    // Try received pattern
    match = mpesaReceivedPattern.firstMatch(body);
    if (match != null) {
      final reference = match.group(1)!;
      final amount = parseAmount(match.group(2)!);
      final sender = match.group(3)!.trim();
      final balance = parseAmount(match.group(4)!);

      return Transaction(
        id: uuid.v4(),
        title: 'Received from $sender',
        amount: amount,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        recipient: sender,
        originalSms: body,
        newBalance: balance,
        date: date,
        accountId: accountId,
        reference: reference,
      );
    }

    // Try withdraw pattern
    match = mpesaWithdrawPattern.firstMatch(body);
    if (match != null) {
      final reference = match.group(1)!;
      final amount = parseAmount(match.group(2)!);
      final agent = match.group(3)!.trim();
      final balance = parseAmount(match.group(4)!);

      return Transaction(
        id: uuid.v4(),
        title: 'Withdrawn from $agent',
        amount: amount,
        type: TransactionType.expense,
        category: TransactionCategory.other,
        recipient: agent,
        originalSms: body,
        newBalance: balance,
        date: date,
        accountId: accountId,
        reference: reference,
      );
    }


    
    // Try simple airtime pattern first
    match = mpesaAirtimePattern.firstMatch(body);
    if (match != null) {
      final reference = match.group(1)!;
      final amount = parseAmount(match.group(2)!);
      final balance = parseAmount(match.group(3)!);
      
      return Transaction(
        id: uuid.v4(),
        title: 'Airtime Purchase',
        amount: amount,
        type: TransactionType.expense,
        category: TransactionCategory.utilities,
        recipient: 'Safaricom Airtime',
        originalSms: body,
        newBalance: balance,
        date: date,
        accountId: accountId,
        reference: reference,
      );
    }

    // Try buy airtime/bundles pattern
    match = mpesaBuyPattern.firstMatch(body);
    if (match != null) {
      final reference = match.group(1)!;
      final amount = parseAmount(match.group(2)!);
      final item = match.group(3)!.trim();
      final balance = parseAmount(match.group(4)!);

      return Transaction(
        id: uuid.v4(),
        title: item,
        amount: amount,
        type: TransactionType.expense,
        category: item.toLowerCase().contains('airtime')
            ? TransactionCategory.utilities
            : TransactionCategory.shopping,
        recipient: item,
        originalSms: body,
        newBalance: balance,
        date: date,
        accountId: accountId,
        reference: reference,
      );
    }

    return null;
  }

  /// Parse KCB SMS
  Transaction? _parseKcbSms(
    String body,
    DateTime date,
    String accountId,
    String? learnedCategory,
  ) {
    const uuid = Uuid();

    final kcbBalancePattern = RegExp(
      r'Avail(?:able)?\.?\s*Bal(?:ance)?\s*(?:is|:)?\s*(?:KES|Ksh)\.?\s*([\d,]+\.\d{2})',
      caseSensitive: false,
    );

    double? balance;
    final balanceMatch = kcbBalancePattern.firstMatch(body);
    if (balanceMatch != null) {
      balance = double.parse(balanceMatch.group(1)!.replaceAll(',', ''));
    }

    // Extract amount
    final amountPattern = RegExp(
      r'(?:KES|Ksh)\.?\s*([\d,]+\.\d{2})',
      caseSensitive: false,
    );
    final amountMatch = amountPattern.firstMatch(body);
    if (amountMatch == null) return null;

    final amount = double.parse(amountMatch.group(1)!.replaceAll(',', ''));

    TransactionType type = TransactionType.expense;
    if (body.toLowerCase().contains('credited') ||
        body.toLowerCase().contains('received')) {
      type = TransactionType.income;
    }

    TransactionCategory category = learnedCategory != null
        ? (PatternLearningService.categoryFromString(learnedCategory) ??
              TransactionCategory.general)
        : TransactionCategory.general;

    return Transaction(
      id: uuid.v4(),
      title: 'KCB Transaction',
      amount: amount,
      type: type,
      category: category,
      originalSms: body,
      newBalance: balance ?? 0.0,
      date: date,
      accountId: accountId,
    );
  }

  /// Save transactions and update account balances
  Future<void> _saveTransactions(List<Transaction> transactions) async {
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
    for (var transaction in transactions) {
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
      }
    }

    // Update account balances
    final Map<String, Transaction> mostRecentByAccount = {};

    for (var transaction in transactionsBox.values) {
      if (transaction.newBalance == null || transaction.accountId.isEmpty)
        continue;

      final existing = mostRecentByAccount[transaction.accountId];
      if (existing == null || transaction.date.isAfter(existing.date)) {
        mostRecentByAccount[transaction.accountId] = transaction;
      }
    }

    // Update balance for each account
    for (var entry in mostRecentByAccount.entries) {
      try {
        final account = accountsBox.values.firstWhere(
          (acc) => acc.id == entry.key,
        );

        if (entry.value.newBalance != null && entry.value.newBalance! > 0) {
          final updated = account.copyWith(
            balance: entry.value.newBalance!,
            lastUpdated: entry.value.date,
          );
          accountsBox.put(account.id, updated);
        }
      } catch (e) {
        // Account not found, skip
      }
    }

    // Recalculate balances as fallback
    _recalculateBalancesFromTransactions(accountsBox, transactionsBox);
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
    final Map<String, Transaction> latestWithBalance = {};

    for (var transaction in transactionsBox.values) {
      if (transaction.newBalance == null || transaction.newBalance! <= 0)
        continue;

      final existing = latestWithBalance[transaction.accountId];
      if (existing == null || transaction.date.isAfter(existing.date)) {
        latestWithBalance[transaction.accountId] = transaction;
      }
    }

    for (var entry in latestWithBalance.entries) {
      try {
        final account = accountsBox.values.firstWhere(
          (acc) => acc.id == entry.key,
        );

        if (entry.value.newBalance != null) {
          final updated = account.copyWith(
            balance: entry.value.newBalance!,
            lastUpdated: entry.value.date,
          );
          accountsBox.put(account.id, updated);
        }
      } catch (e) {
        // Account not found, skip
      }
    }
  }
}
