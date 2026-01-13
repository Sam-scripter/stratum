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

  /// Legacy method - kept for backward compatibility
  Stream<SmsReadProgress> readAllSms() async* {
    yield* scanAllMessages();
  }

  /// Normalize sender address to handle variations (MPESA, M-PESA, SAFARICOM all map to MPESA)
  String _getStandardizedAccountName(String accountType) {
    switch (accountType) {
      case 'MPESA':
        return 'MPESA';
      case 'KCB':
        return 'KCB';
      case 'EQUITY':
        return 'EQUITY';
      case 'COOP':
        return 'COOP';
      case 'NCBA':
        return 'NCBA';
      case 'STANBIC':
        return 'STANBIC';
      default:
        return accountType;
    }
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
    print(
      'Parsing SMS from address: $address (normalized: $normalizedAddress)',
    );

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

    print('Looking for account type: $accountType');
    print(
      'Existing accounts: ${accountsBox.values.map((a) => '${a.name} (${a.id}) - sender: ${a.senderAddress}').toList()}',
    );

    Account? account;

    // Normalize sender address for matching
    final normalizedSenderAddress = _normalizeSenderAddress(
      address,
      accountType,
    );
    print('Normalized sender address for matching: $normalizedSenderAddress');

    try {
      // Try to find account by standardized name
      final standardizedName = _getStandardizedAccountName(accountType!);
      account = accountsBox.values.firstWhere(
        (acc) => acc.name == standardizedName,
      );
      print('Found existing account: ${account.name} (${account.id})');

      // Ensure account type is correct
      final correctType = accountType == 'MPESA'
          ? AccountType.Mpesa
          : AccountType.Bank;
      if (account.type != correctType) {
        print('Updating account type from ${account.type} to $correctType');
        final updatedAccount = account.copyWith(type: correctType);
        accountsBox.put(account.id, updatedAccount);
        account = updatedAccount;
      }

      // Update sender address if different
      if (account.senderAddress.toUpperCase() != address.toUpperCase()) {
        print(
          'Updating sender address from ${account.senderAddress} to $address',
        );
        final updatedAccount = account.copyWith(senderAddress: address);
        accountsBox.put(account.id, updatedAccount);
        account = updatedAccount;
      }
    } catch (e) {
      // Create new account
      print('Creating new account for $accountType');
      final standardizedName = _getStandardizedAccountName(accountType!);
      final newAccount = Account(
        id: const Uuid().v4(),
        name: standardizedName,
        balance: 0.0,
        type: accountType == 'MPESA' ? AccountType.Mpesa : AccountType.Bank,
        lastUpdated: DateTime.now(),
        senderAddress: address,
        isAutomated: true,
      );
      accountsBox.put(newAccount.id, newAccount);
      account = newAccount;
      print('Created new account: ${account.name} (${account.id})');
    }

    // Merge any duplicate accounts with the same name
    await _mergeDuplicateAccounts(accountsBox, account);

    // Parse using patterns
    final transaction = _parseFinancialSms(
      address,
      body,
      date,
      account.id,
      accountType,
    );

    // Update account balance if transaction has balance
    if (transaction != null && transaction.newBalance != null) {
      final updatedAccount = account.copyWith(
        balance: transaction.newBalance!,
        lastUpdated: transaction.date,
      );
      accountsBox.put(account.id, updatedAccount);
    }

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

  /// Merge duplicate accounts into a primary account
  /// Migrates all transactions from duplicates to the primary account
  /// Ensures M-Pesa accounts are named "MPESA" (all caps)
  Future<void> _mergeDuplicateAccounts(
    Box<Account> accountsBox,
    Account primaryAccount,
  ) async {
    // Find all accounts with the same name as the primary account
    final duplicateAccounts = accountsBox.values
        .where(
          (acc) =>
              acc.name == primaryAccount.name && acc.id != primaryAccount.id,
        )
        .toList();

    if (duplicateAccounts.isEmpty) return;

    print(
      'Merging ${duplicateAccounts.length} duplicate accounts into ${primaryAccount.name} (${primaryAccount.id})',
    );

    // Get transactions box
    final transactionsBox = _boxManager.getBox<Transaction>(
      BoxManager.transactionsBoxName,
      userId,
    );

    // Migrate all transactions from duplicate accounts to primary account
    int migratedCount = 0;
    for (var duplicateAccount in duplicateAccounts) {
      final duplicateTransactions = transactionsBox.values
          .where((t) => t.accountId == duplicateAccount.id)
          .toList();

      for (var transaction in duplicateTransactions) {
        // Update transaction to use primary account ID
        final updatedTransaction = transaction.copyWith(
          accountId: primaryAccount.id,
        );
        transactionsBox.put(updatedTransaction.id, updatedTransaction);
        migratedCount++;
      }

      // Delete the duplicate account
      await accountsBox.delete(duplicateAccount.id);
      print(
        'Merged and deleted duplicate account: ${duplicateAccount.name} (${duplicateAccount.id})',
      );
    }

    print(
      'Migrated $migratedCount transactions to primary account ${primaryAccount.name}',
    );

    // Recalculate primary account balance from all transactions
    final allTransactions = transactionsBox.values
        .where((t) => t.accountId == primaryAccount.id)
        .toList();

    // Find the most recent transaction with a balance
    Transaction? mostRecentWithBalance;
    for (var transaction in allTransactions) {
      if (transaction.newBalance != null && transaction.newBalance! > 0) {
        if (mostRecentWithBalance == null ||
            transaction.date.isAfter(mostRecentWithBalance.date)) {
          mostRecentWithBalance = transaction;
        }
      }
    }

    // Update primary account balance and ensure name is "MPESA" for M-Pesa accounts
    Account updatedAccount = primaryAccount;
    if (primaryAccount.type == AccountType.Mpesa &&
        primaryAccount.name != 'MPESA') {
      updatedAccount = updatedAccount.copyWith(name: 'MPESA');
      print('Renaming M-Pesa account to MPESA: ${primaryAccount.id}');
    }

    if (mostRecentWithBalance != null) {
      updatedAccount = updatedAccount.copyWith(
        balance: mostRecentWithBalance.newBalance!,
        lastUpdated: mostRecentWithBalance.date,
      );
      print(
        'Updated primary account balance to ${mostRecentWithBalance.newBalance}',
      );
    }

    accountsBox.put(primaryAccount.id, updatedAccount);
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
