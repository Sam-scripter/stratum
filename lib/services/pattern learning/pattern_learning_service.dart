import 'package:uuid/uuid.dart';
import '../../models/message_pattern/message_pattern.dart';
import '../../models/box_manager.dart';
import '../../models/transaction/transaction_model.dart';

class PatternLearningService {
  static const uuid = Uuid();
  static const String patternsBoxName = 'message_patterns';

  /// Learn from user's category update - creates a generalized pattern
  static String learnPattern(String sms, String category) {
    // Create a generalized pattern by replacing numbers and specific names
    var pattern = sms;

    // Replace amounts with placeholder
    pattern = pattern.replaceAll(RegExp(r'Ksh[\d,]+\.\d{2}'), 'KshAMOUNT');
    pattern = pattern.replaceAll(RegExp(r'KES\.?\s*[\d,]+\.\d{2}'), 'KESAMOUNT');
    pattern = pattern.replaceAll(RegExp(r'Ksh[\d,]+'), 'KshAMOUNT');
    pattern = pattern.replaceAll(RegExp(r'KES\.?\s*[\d,]+'), 'KESAMOUNT');

    // Replace phone numbers
    pattern = pattern.replaceAll(RegExp(r'\d{10,12}'), 'PHONE');

    // Replace transaction codes
    pattern = pattern.replaceAll(RegExp(r'[A-Z]{2,}\d+[A-Z]*'), 'TXNCODE');

    // Replace dates and times
    pattern = pattern.replaceAll(RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}'), 'DATE');
    pattern = pattern.replaceAll(RegExp(r'\d{1,2}:\d{2}(?::\d{2})?\s*[AP]M'), 'TIME');

    return pattern;
  }

  /// Get category for a learned pattern
  static String? getCategoryForPattern(String pattern, String accountType, String userId) {
    try {
      final boxManager = BoxManager();
      final patternsBox = boxManager.getBox<MessagePattern>(patternsBoxName, userId);
      
      final match = patternsBox.values.firstWhere(
        (p) => p.pattern == pattern && p.accountType == accountType,
        orElse: () => MessagePattern(
          id: '',
          pattern: '',
          category: '',
          accountType: '',
          lastSeen: DateTime.now(),
        ),
      );

      if (match.id.isEmpty) return null;
      return match.category;
    } catch (e) {
      return null;
    }
  }

  /// Save a learned pattern
  static Future<void> savePattern(MessagePattern pattern, String userId) async {
    try {
      final boxManager = BoxManager();
      await boxManager.openAllBoxes(userId);
      final patternsBox = boxManager.getBox<MessagePattern>(patternsBoxName, userId);

      // Check if pattern already exists
      final existing = patternsBox.values.firstWhere(
        (p) => p.pattern == pattern.pattern && p.accountType == pattern.accountType,
        orElse: () => pattern,
      );

      if (existing.id != pattern.id && existing.id.isNotEmpty) {
        // Pattern exists, increment count
        final updated = existing.copyWith(
          matchCount: existing.matchCount + 1,
          lastSeen: DateTime.now(),
          category: pattern.category, // Update category if user changed it
        );
        patternsBox.put(existing.id, updated);
      } else {
        // New pattern
        patternsBox.put(pattern.id, pattern);
      }
    } catch (e) {
      print('Error saving pattern: $e');
    }
  }

  /// Convert TransactionCategory enum to string for learning
  static String categoryToString(TransactionCategory category) {
    return category.toString().split('.').last;
  }

  /// Convert string to TransactionCategory enum
  static TransactionCategory? categoryFromString(String categoryStr) {
    try {
      return TransactionCategory.values.firstWhere(
        (c) => c.toString().split('.').last == categoryStr.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

