import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';
import '../../models/transaction/transaction_model.dart';
import '../pattern learning/pattern_learning_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class UnifiedTransactionParser {
  static const String _localRulesPath = 'assets/parsing_rules.json';
  Map<String, dynamic>? _config;
  final Uuid _uuid = const Uuid();

  Map<String, dynamic>? _rawConfig;
  List<String> _userNames = [];

  // Cache compiled regexes for performance
  final List<ParsingRule> _compiledRules = [];

  Future<void> initialize() async {
    try {
      // 1. Load from local assets (Fallback / Default)
      final jsonString = await rootBundle.loadString(_localRulesPath);
      _rawConfig = json.decode(jsonString);
      
      // 2. Try fetching from Remote Config (Override)
      try {
        await _fetchRemoteConfig();
      } catch (e) {
        print('Remote Config fetch failed (using local): $e');
      }
      
      _recompileRules();
    } catch (e) {
      print('Error initializing UnifiedTransactionParser: $e');
    }
  }

  Future<void> _fetchRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 12),
    ));

    await remoteConfig.fetchAndActivate();
    
    // Look for our specific key 'parsing_rules_v1'
    final remoteString = remoteConfig.getString('parsing_rules_v1');
    if (remoteString.isNotEmpty) {
      try {
        final remoteMap = json.decode(remoteString);
        if (remoteMap is Map<String, dynamic> && remoteMap.containsKey('patterns')) {
           print('Successfully loaded Remote Config (v1)');
           _rawConfig = remoteMap; // Override local
        }
      } catch (e) {
        print('Error parsing remote config JSON: $e');
      }
    }
  }

  void setUserNames(List<String> names) {
    // Normalize names: uppercase, trim, remove empty
    final normalized = names
        .map((n) => n.trim().toUpperCase())
        .where((n) => n.isNotEmpty)
        .toList();
        
    // Only recompile if changed
    if (normalized.join(',') != _userNames.join(',')) {
      _userNames = normalized;
      if (_rawConfig != null) {
        _recompileRules();
      }
    }
  }

  void _recompileRules() {
    if (_rawConfig == null) return;
    _compiledRules.clear();
    final List<dynamic> patterns = _rawConfig!['patterns'] ?? [];
    
    // Construct user name regex part: (NAME1|NAME2|NAME3)
    String userNamesRegex = '(ME|MYSELF)'; // Default safe fallback
    if (_userNames.isNotEmpty) {
      // Escape names for regex safety
      final escaped = _userNames.map((n) => RegExp.escape(n)).join('|');
      userNamesRegex = '($escaped)';
    }

    for (final p in patterns) {
      try {
        String rawRegex = p['regex'];
        
        // DYNAMIC SUBSTITUTION
        if (rawRegex.contains('{{USER_NAMES}}')) {
          rawRegex = rawRegex.replaceAll('{{USER_NAMES}}', userNamesRegex);
        }

        _compiledRules.add(ParsingRule(
          bank: p['bank'],
          type: p['type'],
          regex: RegExp(rawRegex, caseSensitive: false),
          groups: Map<String, dynamic>.from(p['groups']),
        ));
      } catch (e) {
        print('Failed to compile rule for ${p['bank']}: $e');
      }
    }
  }

  Future<Transaction?> parseMessage({
    required String address,
    required String body,
    required DateTime date,
    required String accountId,
    required String userId,
    String? accountType,
  }) async {
    if (_compiledRules.isEmpty) await initialize();

    // 1. Filter rules by Bank/Sender if possible to optimize
    final rules = _compiledRules.where((rule) => 
        address.toUpperCase().contains(rule.bank) || 
        (rule.bank == 'MPESA' && (address.toUpperCase().contains('M-PESA')))
    );

    for (final rule in rules) {
      final match = rule.regex.firstMatch(body);
      if (match != null) {
        return _createTransactionFromMatch(rule, match, body, date, accountId, accountType, userId);
      }
    }
    return null;
  }

  Future<Transaction?> _createTransactionFromMatch(
    ParsingRule rule, 
    RegExpMatch match, 
    String originalSms, 
    DateTime date,
    String accountId,
    String? accountType,
    String userId,
  ) async {
    try {
      // Extract fields based on groups configuration
      String? reference;
      double amount = 0.0;
      double? balance;
      String recipientOrSender = '';
      double fee = 0.0;
      
      final groups = rule.groups;

      // Helper to get group value
      String? getGroupText(dynamic indexOrName) {
        if (indexOrName is int) {
          return match.group(indexOrName);
        } else if (indexOrName is String) {
          return indexOrName; // Static value like "Safaricom Airtime"
        }
        return null;
      }
      
      // Reference
      if (groups.containsKey('reference')) {
        reference = getGroupText(groups['reference']);
      }
      
      // Amount
      if (groups.containsKey('amount')) {
         final val = getGroupText(groups['amount']);
         if (val != null) amount = double.tryParse(val.replaceAll(',', '')) ?? 0.0;
      }
      
      // Fee (for KCB etc)
      if (groups.containsKey('fee')) {
         final val = getGroupText(groups['fee']);
         if (val != null) fee = double.tryParse(val.replaceAll(',', '')) ?? 0.0;
      }

      // Balance
      if (groups.containsKey('balance')) {
         final val = getGroupText(groups['balance']);
         if (val != null) balance = double.tryParse(val.replaceAll(',', '')) ?? 0.0;
      }
      
      // Recipient / Sender / Agent
      if (groups.containsKey('recipient')) {
        recipientOrSender = getGroupText(groups['recipient']) ?? '';
      } else if (groups.containsKey('sender')) {
        recipientOrSender = getGroupText(groups['sender']) ?? '';
      } else if (groups.containsKey('agent')) {
        recipientOrSender = getGroupText(groups['agent']) ?? '';
      } else if (groups.containsKey('item')) {
        recipientOrSender = getGroupText(groups['item']) ?? '';
      }

      // Determine Type & Category
      TransactionType type = TransactionType.expense;
      String description = ''; // Fix: Declare description here

      if (rule.type == 'RECEIVED' || rule.type == 'INCOME' || rule.type == 'DEPOSIT') {
        type = TransactionType.income;
      } else if (rule.type == 'WITHDRAW') {
        type = TransactionType.transfer;
      }
      
      // Handle Reversals (User requested: Expense reversed -> Income)
      if (groups.containsKey('is_reversal') && groups['is_reversal'] == true) {
        type = TransactionType.income;
        if (recipientOrSender.isEmpty) recipientOrSender = 'Reversal';
        description = 'Transaction Reversal';
      }
      
      // Apply Fee if Expense
      if (type == TransactionType.expense && fee > 0) { // Fix: Remove duplicate declaration
        amount += fee;
        description = 'Includes fee: $fee';
      }

      // 2. Conflict Resolution: Check PatternLearningService for Category Override
      TransactionCategory category = TransactionCategory.general;
      
      // Default heuristics
      if (rule.type == 'AIRTIME' || recipientOrSender.toLowerCase().contains('airtime')) {
        category = TransactionCategory.utilities;
      } else if (rule.type == 'PAYBILL') {
        category = TransactionCategory.other; 
      }

      // Advanced Heuristics (Ported from SmsReaderService)
      final lower = recipientOrSender.toLowerCase();
      if (lower.contains('safaricom') || lower.contains('airtime')) {
        category = TransactionCategory.utilities;
      } else if (lower.contains('kplc') || lower.contains('power') || lower.contains('electricity') || lower.contains('water')) {
        category = TransactionCategory.utilities;
      } else if (lower.contains('rent')) {
        category = TransactionCategory.other;
      } else if (lower.contains('pharmacy') || lower.contains('hospital') || lower.contains('clinic')) {
        category = TransactionCategory.health;
      } else if (lower.contains('school') || lower.contains('university') || lower.contains('college')) {
        category = TransactionCategory.other; // Or education if added
      } else if (lower.contains('supermarket') || lower.contains('shop') || lower.contains('store')) {
        category = TransactionCategory.shopping;
      } else if (lower.contains('restaurant') || lower.contains('cafe') || lower.contains('hotel')) {
        category = TransactionCategory.dining;
      }

      // Check Learning Service (First Priority)
      final learnedPatternKey = PatternLearningService.learnPattern(originalSms, '');
      final learnedCategoryStr = PatternLearningService.getCategoryForPattern(
        learnedPatternKey, 
        accountType ?? rule.bank, 
        userId
      );

      if (learnedCategoryStr != null) {
        final learnedCat = PatternLearningService.categoryFromString(learnedCategoryStr);
        if (learnedCat != null) category = learnedCat;
      }
      
      return Transaction(
        id: _uuid.v4(),
        title: type == TransactionType.income ? 'Received from $recipientOrSender' : recipientOrSender,
        amount: amount,
        type: type,
        category: category, 
        recipient: recipientOrSender,
        originalSms: originalSms,
        newBalance: balance,
        date: date,
        accountId: accountId,
        reference: reference,
        description: description,
      );
    } catch (e) {
      print('Error creating transaction from match: $e');
      return null;
    }
  }
}

class ParsingRule {
  final String bank;
  final String type;
  final RegExp regex;
  final Map<String, dynamic> groups;

  ParsingRule({
    required this.bank,
    required this.type,
    required this.regex,
    required this.groups,
  });
}
