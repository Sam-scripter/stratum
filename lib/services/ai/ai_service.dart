import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/ai/merchant_map.dart';
import '../../models/box_manager.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late GenerativeModel _model;
  bool _initialized = false;
  
  // Cache box name
  static const String merchantMapBoxName = 'merchant_map_cache';

  Future<void> initialize(String apiKey) async {
    if (_initialized) return;

    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
    );
    
    // Register adapter only if not already registered (BoxManager might do it or we do it here)
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(MerchantMapAdapter());
    }
    
    await Hive.openBox<MerchantMap>(merchantMapBoxName);
    
    _initialized = true;
  }

  /// Clean merchant name and categorize using Gemini + Cache
  Future<List<String>> cleanMerchantAndCategory(String rawName, String body) async {
    if (!_initialized) {
      // Fallback if not initialized (e.g. no API key yet)
      return [rawName, 'General']; 
    }

    final box = Hive.box<MerchantMap>(merchantMapBoxName);
    
    // 1. Check Cache
    final cached = box.values.firstWhere(
      (m) => m.rawName == rawName, 
      orElse: () => MerchantMap(rawName: '', cleanName: '', category: ''),
    );
    
    if (cached.rawName.isNotEmpty) {
      return [cached.cleanName, cached.category];
    }

    // 2. Query Gemini
    try {
      final prompt = '''
      Analyze this financial transaction SMS and extract the clean merchant name and the most appropriate category.
      
      Input:
      Sender/Context: $rawName
      Message: $body
      
      Categories: Dining, Groceries, Shopping, Transport, Utilities, Entertainment, Health, Investment, Salary, Transfer, Other, General.
      
      Output ONLY a string in this format: "CleanName|Category"
      Example: "Uber|Transport" or "Java House|Food & Drink"
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final text = response.text?.trim() ?? '';
      
      if (text.contains('|')) {
        final parts = text.split('|');
        final cleanName = parts[0].trim();
        final category = parts.length > 1 ? parts[1].trim() : 'General';
        
        // Cache result
        final mapEntry = MerchantMap(
          rawName: rawName,
          cleanName: cleanName,
          category: category,
        );
        box.add(mapEntry);
        
        return [cleanName, category];
      }
    } catch (e) {
      print('AI Service Error: $e');
    }

    // Fallback
    return [rawName, 'General'];
  }

  /// Generate a friendly/urgent budget alert message
  Future<String?> generateBudgetAlert({
    required String category,
    required double spent,
    required double limit,
    required int dayOfMonth,
  }) async {
    if (!_initialized) return null;

    try {
      final prompt = '''
      The user has exceeded their budget velocity.
      Category: $category
      Spent: ${spent.toStringAsFixed(0)}
      Limit: ${limit.toStringAsFixed(0)}
      Day of Month: $dayOfMonth (out of 30)
      
      Write a short, friendly, but urgent notification body (max 20 words).
      Do not include a title.
      Use emojis.
      Example: "Whoa! You've used 80% of your Dining budget and it's only day 10! 🍔 Caution."
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim();
    } catch (e) {
      print('AI Alert Gen Error: $e');
      return null;
    }
  }
}
