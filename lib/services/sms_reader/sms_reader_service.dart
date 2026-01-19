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
            // Found a NEW account!
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

    // Reversal Pattern
    final mpesaReversalPattern = RegExp(
      r'([A-Z0-9]+)\s+Confirmed\.\s*Reversal of transaction [A-Z0-9]+ has been successfully reversed.*?New M-PESA balance is Ksh([\d,]+\.\d{2})',
      caseSensitive: false,
    );
     // Alternative generic reversal detection if the above is too specific
    if (body.toLowerCase().contains('reversal of') && 
        body.toLowerCase().contains('confirmed')) {
        
        // Try to extract amount and balance
        final amountPattern = RegExp(r'Ksh([\d,]+\.\d{2})');
        final matches = amountPattern.allMatches(body).toList();
        
        if (matches.length >= 2) {
           // Assume first money is amount reversed, last is balance
           // This is a heuristic. Mpesa reversal messages vary.
           // "OT82... Confirmed. Reversal of transaction OT82... of Ksh30,000.00 to ... has been successfully reversed. New M-PESA balance is Ksh45,000.00"
           
           // If we matched the explicit regex, we can be more precise, but let's try a robust flexible approach
           String? reference;
           double? amount;
           double? balance;
           
           final refMatch = RegExp(r'^([A-Z0-9]+)').firstMatch(body);
           reference = refMatch?.group(1);
           
           if (matches.isNotEmpty) {
             // Usually "Reversal of... Ksh X ... Balance is Ksh Y"
             // Exception: "Reversal of transaction ... sent to ... of Ksh X ..."
             // If we have 2 matches, usually 1st is amount, 2nd is balance?
             // If 1 match, maybe just balance? No, reversal must have amount.

             // Let's use the explicit matches if possible
             final amountStr = matches.length > 1 ? matches[matches.length - 2]
                 .group(1) : matches.first.group(1);
             final balanceStr = matches.last.group(1);

             if (amountStr != null)
               amount = double.parse(amountStr.replaceAll(',', ''));
             if (balanceStr != null)
               balance = double.parse(balanceStr.replaceAll(',', ''));

             if (amount != null) {
               return Transaction(
                 id: uuid.v4(),
                 title: 'Reversal / Refund',
                 amount: amount,
                 type: TransactionType.income,
                 category: TransactionCategory.other,
                 // Or Refund if added
                 recipient: 'M-PESA',
                 originalSms: body,
                 newBalance: balance,
                 date: date,
                 accountId: accountId,
                 reference: reference,
                 description: 'Reversal of previous transaction',
               );
             }
           }
        }
    }

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

    // Balance Regex
    final kcbBalancePattern = RegExp(
      r'Avail(?:able)?\.?\s*Bal(?:ance)?\s*(?:is|:)?\s*(?:KES|Ksh)\.?\s*([\d,]+\.\d{2})',
      caseSensitive: false,
    );
     // Try to find balance
    double? balance;
    final balanceMatch = kcbBalancePattern.firstMatch(body);
    if (balanceMatch != null) {
      balance = double.parse(balanceMatch.group(1)!.replaceAll(',', ''));
    }

    // Amount Regex
    final amountPattern = RegExp(
      r'(?:KES|Ksh)\.?\s*([\d,]+\.\d{2})',
      caseSensitive: false,
    );
    // Be careful not to pick up the balance as the amount if it's the only number
    // Usually amount comes before balance.
    
    // Detect Transaction Fee
    // "Transaction cost KES 15.00"
    double fee = 0.0;
    final feePattern = RegExp(
      r'Transaction cost\s+(?:KES|Ksh)\.?\s*([\d,]+\.\d{2})', 
      caseSensitive: false
    );
    final feeMatch = feePattern.firstMatch(body);
    if (feeMatch != null) {
      fee = double.parse(feeMatch.group(1)!.replaceAll(',', ''));
    }

    // Extract all amounts
    final allAmountMatches = amountPattern.allMatches(body).toList();
    
    if (allAmountMatches.isEmpty) return null;

    // Logic to identify the main transaction amount vs fee vs balance
    // Example: "Your SEND TO M-PESA... KES 1,350.00... Transaction cost KES 15.00... Avail Bal KES 27,888.18"
    
    double amount = 0.0;
    
    // Heuristic: The main amount is usually the first currency figure that isn't the fee or balance.
    // Or we can rely on specific keywords like "request of KES X" or "transaction KES X" or "bought KES X"
    
    // Better KCB specific patterns based on user examples:
    
    // 1. "KES 80.00 transaction made on KCB card..." (Debit)
    final cardDebitPattern = RegExp(
      r'(?:KES|Ksh)\.?\s*([\d,]+\.\d{2})\s+transaction made on',
      caseSensitive: false
    );
    
    // 2. "Your KCB credit card... transaction KES 80.00... has been reversed" (Reversal)
    final reversalPattern = RegExp(
      r'transaction\s+(?:KES|Ksh)\.?\s*([\d,]+\.\d{2})\s+.*reversed',
      caseSensitive: false
    );
    
    // 3. "Your SEND TO M-PESA request of KES 1,350.00..."
    final sendMoneyPattern = RegExp(
      r'request of\s+(?:KES|Ksh)\.?\s*([\d,]+\.\d{2})',
      caseSensitive: false
    );
    
    TransactionType type = TransactionType.expense;
    String title = 'KCB Transaction';
    String description = '';

    var match = reversalPattern.firstMatch(body);
    if (match != null) {
       amount = double.parse(match.group(1)!.replaceAll(',', ''));
       type = TransactionType.income; // Reversals are income/refunds
       title = 'Reversal / Refund';
       description = 'Reversal of prior transaction';
    } else {
       match = cardDebitPattern.firstMatch(body);
       if (match != null) {
         amount = double.parse(match.group(1)!.replaceAll(',', ''));
         type = TransactionType.expense;
         title = 'Card Payment';
       } else {
         match = sendMoneyPattern.firstMatch(body);
         if (match != null) {
           amount = double.parse(match.group(1)!.replaceAll(',', ''));
           type = TransactionType.expense;
           // Extract recipient if possible
           final recipientMatch = RegExp(r'to\s+([^-]+)-\s*([A-Z\s]+)').firstMatch(body);
           if (recipientMatch != null) {
             title = 'Sent to ${recipientMatch.group(2)?.trim() ?? "M-PESA"}';
           } else {
             title = 'Sent to M-PESA';
           }
         } else {
            // Fallback: Use first amount found that isn't fee or balance
            // This is risky but better than nothing
            for (final m in allAmountMatches) {
               final val = double.parse(m.group(1)!.replaceAll(',', ''));
               if (val != balance && val != fee) {
                 amount = val;
                 break;
               }
            }
         }
       }
    }
    
    // Apply Fee if it's an expense
    if (fee > 0 && type == TransactionType.expense) {
      amount += fee; // Total deduction includes fee
      description = '$description (Includes Fee: KES $fee)'.trim();
    }
    
    // Check for income keywords if specific patterns failed but we have an amount
    if (match == null && (body.toLowerCase().contains('credited') || body.toLowerCase().contains('received'))) {
       type = TransactionType.income;
       title = 'Money Received';
    }

    TransactionCategory category = learnedCategory != null
        ? (PatternLearningService.categoryFromString(learnedCategory) ??
              TransactionCategory.general)
        : TransactionCategory.general;

    return Transaction(
      id: uuid.v4(),
      title: title,
      amount: amount,
      type: type,
      category: category,
      originalSms: body,
      newBalance: balance, // Can be null, reconcileBalances will handle it
      date: date,
      accountId: accountId,
      description: description,
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
    final Set<String> affectedAccountIds = {};
    
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
        if (transaction.accountId != null) {
          affectedAccountIds.add(transaction.accountId!);
        }
      }
    }
    
    // Trigger reconciliation for all affected accounts
    for (final accountId in affectedAccountIds) {
      await reconcileBalances(accountId);
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
