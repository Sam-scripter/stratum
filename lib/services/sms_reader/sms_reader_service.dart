import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../../models/box_manager.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/account/account_model.dart';
import '../pattern learning/pattern_learning_service.dart';

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

  /// Read all SMS messages and parse financial ones
  /// Returns a stream of progress updates (current/total)
  Stream<SmsReadProgress> readAllSms() async* {
    try {
      await _boxManager.openAllBoxes(userId);
      
      // Get all messages
      final List<SmsMessage> messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 10000, // Read up to 10k messages
      );

      yield SmsReadProgress(
        current: 0,
        total: messages.length,
        status: 'Reading ${messages.length} messages...',
      );

      final List<Transaction> transactions = [];
      final Set<String> financialSenders = {'MPESA', 'M-PESA', 'SAFARICOM', 'KCB', 'EQUITY', 'COOP', 'CO-OP', 'NCBA', 'STANBIC'};

      int processed = 0;

      for (var message in messages) {
        processed++;

        // Only process messages from financial institutions
        final address = message.address?.toUpperCase() ?? '';
        final isFinancial = financialSenders.any((sender) => address.contains(sender));

        if (isFinancial && message.body != null) {
          // Use the parser service to extract transaction
          final transaction = _parseSmsToTransaction(
            message.address!,
            message.body!,
            message.date ?? DateTime.now(),
          );

          if (transaction != null) {
            transactions.add(transaction);
          }
        }

        // Yield progress every 100 messages
        if (processed % 100 == 0 || processed == messages.length) {
          yield SmsReadProgress(
            current: processed,
            total: messages.length,
            status: 'Processed $processed messages...',
            transactionsFound: transactions.length,
          );
        }
      }

      // Save all transactions
      yield SmsReadProgress(
        current: messages.length,
        total: messages.length,
        status: 'Saving ${transactions.length} transactions...',
        transactionsFound: transactions.length,
      );

      await _saveTransactions(transactions);

      yield SmsReadProgress(
        current: messages.length,
        total: messages.length,
        status: 'Complete!',
        transactionsFound: transactions.length,
        isComplete: true,
      );

    } catch (e) {
      yield SmsReadProgress(
        current: 0,
        total: 0,
        status: 'Error: ${e.toString()}',
        hasError: true,
      );
    }
  }

  /// Normalize sender address to handle variations (MPESA, M-PESA, SAFARICOM all map to MPESA)
  String _normalizeSenderAddress(String address, String? accountType) {
    final upper = address.toUpperCase().trim();
    if (accountType == 'MPESA') {
      // All MPESA variations map to the same
      if (upper.contains('MPESA') || upper.contains('M-PESA') || upper.contains('SAFARICOM')) {
        return 'MPESA';
      }
    }
    return upper;
  }

  /// Parse SMS to Transaction using the parser service
  Transaction? _parseSmsToTransaction(String address, String body, DateTime date) {
    // Use financial_tracker's parser logic
    final normalizedAddress = address.toUpperCase().trim();
    
    String? accountType;
    if (normalizedAddress.contains('MPESA') || normalizedAddress == 'MPESA') {
      accountType = 'MPESA';
    } else if (normalizedAddress.contains('KCB')) {
      accountType = 'KCB';
    } else if (normalizedAddress.contains('EQUITY')) {
      accountType = 'EQUITY';
    } else {
      return null;
    }

    // Get or create account
    final accountsBox = _boxManager.getBox<Account>(
      BoxManager.accountsBoxName,
      userId,
    );
    
    Account? account;
    
    // Normalize sender address for matching (handle variations like MPESA, M-PESA, SAFARICOM)
    final normalizedSenderAddress = _normalizeSenderAddress(address, accountType);
    
    try {
      // First, try to find account by normalized sender address (most accurate)
      account = accountsBox.values.firstWhere(
        (acc) => _normalizeSenderAddress(acc.senderAddress, accountType) == normalizedSenderAddress,
      );
    } catch (e) {
      // If not found by address, try by type - but check for duplicates
      try {
        final matchingAccounts = accountsBox.values.where(
          (acc) {
            if (accountType == 'MPESA') {
              return acc.type == AccountType.Mpesa;
            } else {
              return acc.type == AccountType.Bank && acc.name.toUpperCase().contains(accountType!);
            }
          },
        ).toList();
        
        if (matchingAccounts.isNotEmpty) {
          // Use the first matching account (prefer one with transactions or balance)
          account = matchingAccounts.firstWhere(
            (acc) => acc.balance > 0,
            orElse: () => matchingAccounts.first,
          );
          // Update sender address if it's different (to consolidate)
          if (account.senderAddress.toUpperCase() != address.toUpperCase()) {
            final updated = account.copyWith(senderAddress: address);
            accountsBox.put(account.id, updated);
            account = updated;
          }
        } else {
          // No account found, create new one
          final newAccount = Account(
            id: const Uuid().v4(),
            name: accountType == 'MPESA' ? 'M-Pesa' : accountType!,
            balance: 0.0,
            type: accountType == 'MPESA' ? AccountType.Mpesa : AccountType.Bank,
            lastUpdated: DateTime.now(),
            senderAddress: address,
            isAutomated: true,
          );
          accountsBox.put(newAccount.id, newAccount);
          account = newAccount;
          print('📱 Created new account: ${account.name} (ID: ${account.id}, Address: $address)');
        }
      } catch (e2) {
        // Fallback: create new account
        final newAccount = Account(
          id: const Uuid().v4(),
          name: accountType == 'MPESA' ? 'M-Pesa' : accountType!,
          balance: 0.0,
          type: accountType == 'MPESA' ? AccountType.Mpesa : AccountType.Bank,
          lastUpdated: DateTime.now(),
          senderAddress: address,
          isAutomated: true,
        );
        accountsBox.put(newAccount.id, newAccount);
        account = newAccount;
        print('📱 Created new account: ${account.name} (ID: ${account.id}, Address: $address)');
      }
    }

    // Parse using financial_tracker patterns
    final transaction = _parseFinancialSms(address, body, date, account.id, accountType);
    
    // If transaction has balance, update account immediately
    if (transaction != null && transaction.newBalance != null) {
      final updatedAccount = account.copyWith(
        balance: transaction.newBalance!,
        lastUpdated: transaction.date,
      );
      accountsBox.put(account.id, updatedAccount);
      print('💰 Updated ${account.name} balance to KES ${transaction.newBalance} from transaction');
    }
    
    return transaction;
  }

  /// Parse financial SMS using financial_tracker patterns
  Transaction? _parseFinancialSms(String address, String body, DateTime date, String accountId, String accountType) {
    // Check for learned pattern first
    final pattern = PatternLearningService.learnPattern(body, '');
    final learnedCategory = PatternLearningService.getCategoryForPattern(pattern, accountType, userId);
    
    // Use financial_tracker's MPESA patterns
    if (accountType == 'MPESA') {
      return _parseMpesaSms(body, date, accountId, learnedCategory);
    } else if (accountType == 'KCB') {
      return _parseKcbSms(body, date, accountId, learnedCategory);
    }
    
    return null;
  }

  /// Parse MPESA SMS (from financial_tracker)
  Transaction? _parseMpesaSms(String body, DateTime date, String accountId, String? learnedCategory) {
    const uuid = Uuid();
    
    // M-PESA Patterns (from financial_tracker)
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

    double _parseAmount(String amountStr) {
      return double.parse(amountStr.replaceAll(',', ''));
    }

    TransactionCategory _categorizeRecipient(String recipient) {
      final lower = recipient.toLowerCase();
      if (lower.contains('safaricom') || lower.contains('airtime')) return TransactionCategory.utilities;
      if (lower.contains('kplc') || lower.contains('power') || lower.contains('electricity')) return TransactionCategory.utilities;
      if (lower.contains('water')) return TransactionCategory.utilities;
      if (lower.contains('rent')) return TransactionCategory.other;
      if (lower.contains('pharmacy') || lower.contains('hospital') || lower.contains('clinic')) return TransactionCategory.health;
      if (lower.contains('school') || lower.contains('university') || lower.contains('college')) return TransactionCategory.other;
      if (lower.contains('supermarket') || lower.contains('shop') || lower.contains('store')) return TransactionCategory.shopping;
      if (lower.contains('restaurant') || lower.contains('cafe') || lower.contains('hotel')) return TransactionCategory.dining;
      if (lower.contains('agent')) return TransactionCategory.other;
      return TransactionCategory.general;
    }

    // Try sent/paid pattern
    var match = mpesaSentPattern.firstMatch(body);
    if (match != null) {
      final reference = match.group(1)!;
      final amount = _parseAmount(match.group(2)!);
      final recipient = match.group(3)!.trim();
      final balance = _parseAmount(match.group(4)!);

      TransactionCategory category = learnedCategory != null
          ? (PatternLearningService.categoryFromString(learnedCategory) ?? _categorizeRecipient(recipient))
          : _categorizeRecipient(recipient);

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
      final amount = _parseAmount(match.group(2)!);
      final sender = match.group(3)!.trim();
      final balance = _parseAmount(match.group(4)!);

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
      final amount = _parseAmount(match.group(2)!);
      final agent = match.group(3)!.trim();
      final balance = _parseAmount(match.group(4)!);

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
      final amount = _parseAmount(match.group(2)!);
      final item = match.group(3)!.trim();
      final balance = _parseAmount(match.group(4)!);

      return Transaction(
        id: uuid.v4(),
        title: item,
        amount: amount,
        type: TransactionType.expense,
        category: item.toLowerCase().contains('airtime') ? TransactionCategory.utilities : TransactionCategory.shopping,
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

  /// Parse KCB SMS (simplified version)
  Transaction? _parseKcbSms(String body, DateTime date, String accountId, String? learnedCategory) {
    const uuid = Uuid();
    
    // Simple KCB patterns
    final kcbBalancePattern = RegExp(
      r'Avail(?:able)?\.?\s*Bal(?:ance)?\s*(?:is|:)?\s*(?:KES|Ksh)\.?\s*([\d,]+\.\d{2})',
      caseSensitive: false,
    );

    double? balance;
    final balanceMatch = kcbBalancePattern.firstMatch(body);
    if (balanceMatch != null) {
      balance = double.parse(balanceMatch.group(1)!.replaceAll(',', ''));
    }

    // Try to extract amount
    final amountPattern = RegExp(r'(?:KES|Ksh)\.?\s*([\d,]+\.\d{2})', caseSensitive: false);
    final amountMatch = amountPattern.firstMatch(body);
    if (amountMatch == null) return null;

    final amount = double.parse(amountMatch.group(1)!.replaceAll(',', ''));
    
    TransactionType type = TransactionType.expense;
    if (body.toLowerCase().contains('credited') || body.toLowerCase().contains('received')) {
      type = TransactionType.income;
    }

    TransactionCategory category = learnedCategory != null
        ? (PatternLearningService.categoryFromString(learnedCategory) ?? TransactionCategory.general)
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
      final isDuplicate = transactionsBox.values.any((t) =>
        t.date.millisecondsSinceEpoch == transaction.date.millisecondsSinceEpoch &&
        t.amount == transaction.amount &&
        t.accountId == transaction.accountId
      );

      if (!isDuplicate) {
        transactionsBox.put(transaction.id, transaction);
      }
    }

    // Update account balances - use the most recent transaction's balance for each account
    final Map<String, Transaction> mostRecentByAccount = {};
    
    // Group transactions by account ID and find the most recent one for each
    for (var transaction in transactionsBox.values) {
      if (transaction.newBalance == null || transaction.accountId.isEmpty) continue;
      
      final existing = mostRecentByAccount[transaction.accountId];
      if (existing == null || transaction.date.isAfter(existing.date)) {
        mostRecentByAccount[transaction.accountId] = transaction;
      }
    }

    // Update balance for each account with the most recent transaction's balance
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
          print('✅ Updated account ${account.name} (${account.id}) balance to KES ${entry.value.newBalance}');
        } else {
          print('⚠️ Transaction for account ${account.name} has no balance or balance is 0');
        }
      } catch (e) {
        print('⚠️ Account ${entry.key} not found for balance update: $e');
        // List all accounts for debugging
        final allAccounts = accountsBox.values.toList();
        print('Available accounts: ${allAccounts.map((a) => '${a.name} (${a.id})').toList()}');
        print('Transaction accountId: ${entry.key}');
      }
    }
    
    // Also recalculate balances from all transactions (fallback)
    _recalculateBalancesFromTransactions(accountsBox, transactionsBox);
  }

  /// Process a single new SMS message
  Future<Transaction?> processSingleSms(String address, String body, DateTime date) async {
    final transaction = _parseSmsToTransaction(address, body, date);

    if (transaction != null) {
      await _boxManager.openAllBoxes(userId);
      final transactionsBox = _boxManager.getBox<Transaction>(
        BoxManager.transactionsBoxName,
        userId,
      );

      // Check for duplicates
      final isDuplicate = transactionsBox.values.any((t) =>
        t.date.millisecondsSinceEpoch == transaction.date.millisecondsSinceEpoch &&
        t.amount == transaction.amount &&
        t.accountId == transaction.accountId
      );

      if (!isDuplicate) {
        transactionsBox.put(transaction.id, transaction);
        
        // Update account balance
        final accountsBox = _boxManager.getBox<Account>(
          BoxManager.accountsBoxName,
          userId,
        );
        final account = accountsBox.values.firstWhere(
          (acc) => acc.id == transaction.accountId,
          orElse: () => Account(
            id: transaction.accountId,
            name: '',
            balance: 0,
            type: AccountType.Bank,
            lastUpdated: DateTime.now(),
            senderAddress: '',
            isAutomated: false,
          ),
        );

        if (transaction.newBalance != null) {
          final updated = account.copyWith(
            balance: transaction.newBalance!,
            lastUpdated: transaction.date,
          );
          accountsBox.put(account.id, updated);
        }
      }

      return transaction;
    }

    return null;
  }

  /// Recalculate account balances from all transactions (fallback method)
  void _recalculateBalancesFromTransactions(
    Box<Account> accountsBox,
    Box<Transaction> transactionsBox,
  ) {
    // Group transactions by account and find most recent with balance
    final Map<String, Transaction> latestWithBalance = {};
    
    for (var transaction in transactionsBox.values) {
      if (transaction.newBalance == null || transaction.newBalance! <= 0) continue;
      
      final existing = latestWithBalance[transaction.accountId];
      if (existing == null || transaction.date.isAfter(existing.date)) {
        latestWithBalance[transaction.accountId] = transaction;
      }
    }
    
    // Update all accounts
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
          print('🔄 Recalculated ${account.name} balance to KES ${entry.value.newBalance}');
        }
      } catch (e) {
        // Account not found, skip
      }
    }
  }
}

class SmsReadProgress {
  final int current;
  final int total;
  final String status;
  final int transactionsFound;
  final bool isComplete;
  final bool hasError;

  SmsReadProgress({
    required this.current,
    required this.total,
    required this.status,
    this.transactionsFound = 0,
    this.isComplete = false,
    this.hasError = false,
  });

  double get progress => total > 0 ? current / total : 0.0;
}

