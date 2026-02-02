import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/box_manager.dart';
import '../../models/ai/chat_message_model.dart';
import '../../models/ai/chat_session_model.dart';
import '../../models/investment/investment_model.dart'; // NEW
import '../../models/ai/daily_insight_model.dart'; // NEW
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

class AIConsultantService {
  static final AIConsultantService _instance = AIConsultantService._internal();
  factory AIConsultantService() => _instance;
  AIConsultantService._internal();

  late GenerativeModel _model;
  ChatSession? _chatSession;
  bool _initialized = false;
  String _userId = '';
  String? _currentSessionId;

  Future<void> initialize(String apiKey, String userId) async {
    if (_initialized && _userId == userId) return;
    
    _userId = userId;
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
    );
    
    await BoxManager().openAllBoxes(userId);
    _initialized = true;
  }

  Future<String> createNewSession() async {
    if (!_initialized) throw Exception("AI Service not initialized");
    
    final id = const Uuid().v4();
    final session = ChatSessionModel(
      id: id, 
      title: 'New Chat', // Default title for new sessions
      createdAt: DateTime.now(), 
      updatedAt: DateTime.now()
    );
    
    final box = BoxManager().getBox<ChatSessionModel>(BoxManager.chatSessionBoxName, _userId);
    await box.put(id, session);
    
    return id;
  }
  
  Future<void> loadSession(String sessionId) async {
    if (!_initialized) throw Exception("AI Service not initialized");
    _currentSessionId = sessionId;

    final box = BoxManager().getBox<ChatMessageModel>(BoxManager.chatBoxName, _userId);
    // Filter messages for this session
    final history = box.values
        .where((m) => m.sessionId == sessionId)
        .toList()
        ..sort((a,b) => a.createdAt.compareTo(b.createdAt));

    // Build Gemini History (System Prompt + Saved Messages)
    final List<Content> geminiHistory = [
      Content.text('''
        You are Atlas, an intelligent financial advisor app.
        Your goal is to help the user manage their money, understand their spending, and plan for the future.
        Key traits: Friendly, Concise, Insightful, Encouraging.
        Emojis: Use them frequently.
        
        STRICT GUARDRAILS:
        - You are a FINANCIAL ASSISTANT. 
        - DO NOT answer questions about politics, sports, general knowledge, coding, or cooking unless they relate to money/budgeting.
        - If the topic is not financial, politely refuse: "I focus only on your financial health! 💰"
        
        RAG CONTEXT:
        If I provide [CONTEXT: ...], use it to answer.
        If the user asks "How much spent on X?" and NO context is provided, say: "I couldn't find any recent transactions for that."
      '''),
      Content.model([TextPart('Understood! I am Atlas, your dedicated financial partner. 🏦')]),
    ];
    
    // Strict Alternation Sanitization
    String lastRole = 'model';
    for (var msg in history) {
      final role = (msg.senderId == 'user') ? 'user' : 'model';
      final text = msg.text.isEmpty ? '.' : msg.text; 
      
      if (role == lastRole) {
        final lastContent = geminiHistory.last;
        final newParts = List<Part>.from(lastContent.parts);
        if (newParts.isNotEmpty && newParts.last is TextPart) {
           final prevText = (newParts.last as TextPart).text;
           newParts.removeLast();
           newParts.add(TextPart('$prevText\n$text'));
        } else {
           newParts.add(TextPart(text));
        }
        geminiHistory.removeLast();
        geminiHistory.add(Content(role, newParts));
      } else {
        if (role == 'user') geminiHistory.add(Content.text(text));
        else geminiHistory.add(Content.model([TextPart(text)]));
        lastRole = role;
      }
    }
    
    // Fix: Ensure history ends with Model so the next sendMessage (User) is valid
    if (lastRole == 'user') {
       geminiHistory.add(Content.model([TextPart('... (Context restored)')]));
    }

    _chatSession = _model.startChat(history: geminiHistory);
  }

  /// Main message handler
  Future<String> sendMessage(String text) async {
    if (!_initialized || _chatSession == null || _currentSessionId == null) {
      return "AI not ready. Please restart chat.";
    }

    try {
      // 0. Persist User Message
      final msgBox = BoxManager().getBox<ChatMessageModel>(BoxManager.chatBoxName, _userId);
      await msgBox.add(ChatMessageModel(
        text: text, 
        senderId: 'user', 
        createdAt: DateTime.now(),
        sessionId: _currentSessionId!,
      ));

      // 1. Intent Analysis (Does this need data?)
      final intentPrompt = '''
      Analyze the user query: "$text"
      Does this require financial data?
      
      Output JSON ONLY:
      { "needs_data": true/false, "keywords": [], "timeframe_days": 30 }
      ''';
      
      String? contextStr;
      try {
        final intentResponse = await _model.generateContent([Content.text(intentPrompt)]);
        final jsonText = intentResponse.text?.replaceAll(RegExp(r'```json|```'), '').trim();
        
        if (jsonText != null && jsonText.contains('"needs_data": true')) {
          await BoxManager().openAllBoxes(_userId); 
          final transactions = BoxManager().getBox<Transaction>(BoxManager.transactionsBoxName, _userId).values;
          
          final now = DateTime.now();
          final cutoff = now.subtract(const Duration(days: 90)); // 90 days context
          
          final relevantTxns = transactions.where((t) {
            if (t.date.isBefore(cutoff)) return false;
            final queryLower = text.toLowerCase();
            return t.title.toLowerCase().contains(queryLower) || 
                   t.categoryName.toLowerCase().contains(queryLower);
          }).toList();
          
          double total = 0;
          for (var t in relevantTxns) total += t.amount;
          
          if (relevantTxns.isNotEmpty) {
             contextStr = '[CONTEXT: Found ${relevantTxns.length} matching transactions. Total: KES ${total.toStringAsFixed(0)}. Top 5: ${relevantTxns.take(5).map((t) => "${t.title}: ${t.amount}").join(", ")}]';
          } else {
             final recent = transactions.toList()..sort((a,b) => b.date.compareTo(a.date));
             final last5 = recent.take(5).toList();
              contextStr = '[CONTEXT: No specific matches. Last 5 txns: ${last5.map((t) => "${t.title}: ${t.amount}").join(", ")}]';
          }

          // Fetch Investments Context
          final invBox = BoxManager().getBox<InvestmentModel>(BoxManager.investmentsBoxName, _userId);
          if (invBox.isNotEmpty) {
             final investments = invBox.values;
             final invTotal = investments.fold<double>(0.0, (sum, i) => sum + i.currentValue);
             final invDetails = investments.map((i) => "${i.name} (${i.currentValue})").join(", ");
             
             final invContext = "[INVESTMENTS: Total Value: KES ${invTotal.toStringAsFixed(0)}. Assets: $invDetails]";
             contextStr = (contextStr == null) ? invContext : "$contextStr\n$invContext";
          }
        }
      } catch (e) {
        print('Intent error: $e');
      }

      // 2. Chat Query
      var messageToSend = text;
      if (contextStr != null) {
        messageToSend = '$contextStr\n\nUser Question: $text';
      }
      
      final response = await _chatSession!.sendMessage(Content.text(messageToSend));
      final responseText = response.text ?? "I'm having trouble thinking right now. 😵‍💫";
      
      // 3. Persist AI Response
      await msgBox.add(ChatMessageModel(
        text: responseText, 
        senderId: 'ai', 
        createdAt: DateTime.now(),
        sessionId: _currentSessionId!
      ));
      
      // 4. Update Session Metadata & Title
      _updateSessionMetadata(text);

      return responseText;

    } catch (e) {
      return "Error: $e";
    }
  }
  
  Future<void> _updateSessionMetadata(String lastUserText) async {
    final sessionBox = BoxManager().getBox<ChatSessionModel>(BoxManager.chatSessionBoxName, _userId);
    final session = sessionBox.get(_currentSessionId);
    if (session != null) {
      session.updatedAt = DateTime.now();
      session.summary = lastUserText; // Simple summary
      session.save();
      
      // Auto-title if it's new
      if (session.title == 'New Chat') {
        _generateTitle(session);
      }
    }
  }
  
  Future<void> _generateTitle(ChatSessionModel session) async {
    try {
      // Use a separate chat or the model directly
      final prompt = '''
      Summarize the following conversation intent into a short Title (max 4 words).
      User asked: "${session.summary}"
      
      Output ONLY the title. No quotes.
      Example: "Budget Advice", "Uber Spending".
      ''';
      
      final response = await _model.generateContent([Content.text(prompt)]);
      final title = response.text?.trim() ?? session.title;
      
      if (title.isNotEmpty) {
        session.title = title;
        session.save();
      }
    } catch (e) {
      print('Title gen error: $e');
    }
  }

  // --- Daily Insight Logic ---
  Future<DailyInsight> getDailyInsight(String userId) async {
    if (!_initialized) throw Exception("AI Service not initialized");
    
    final box = BoxManager().getBox<DailyInsight>(BoxManager.dailyInsightsBoxName, userId);
    
    // Check for today's insight
    final today = DateTime.now();
    final cached = box.values.firstWhereOrNull((i) => 
      i.date.year == today.year && i.date.month == today.month && i.date.day == today.day
    );

    if (cached != null) return cached;

    // Generate NEW Insight
    try {
      // 1. Build Context
      final context = await _buildContext(userId);
      
      // 2. Prompt
      final prompt = '''
      You are Atlas, a financial advisor.
      Context: $context
      
      Task: Give me ONE short, actionable, 1-sentence financial tip for today.
      Focus on spending habits, upcoming bills, or savings.
      If no data is available, give a general saving tip.
      
      Output JSON ONLY:
      { "text": "Your tip here", "type": "positive/neutral/warning" }
      ''';
      
      final response = await _model.generateContent([Content.text(prompt)]);
      final jsonText = response.text?.replaceAll(RegExp(r'```json|```'), '').trim();
      
      String text = "Save a little every day!"; // Fallback
      String type = "neutral";
      
      if (jsonText != null) {
         // Simple parsing (avoid importing dart:convert if not needed, but cleaner to use it if I update imports)
         // I'll assume standard string manipulation for robustness if json parse fails or just simplistic parsing
         if (jsonText.contains('"text":')) {
           final textMatch = RegExp(r'"text":\s*"(.*?)"').firstMatch(jsonText);
           if (textMatch != null) text = textMatch.group(1)!;
           
           if (jsonText.contains('"type": "positive"')) type = 'positive';
           if (jsonText.contains('"type": "warning"')) type = 'warning';
         } else {
           text = jsonText; // Fallback to raw text
         }
      }
      
      final insight = DailyInsight(text: text, date: today, type: type);
      await box.add(insight);
      return insight;
      
    } catch (e) {
      print("Insight Gen Error: $e");
      return DailyInsight(text: "Review your expenses today.", date: DateTime.now());
    }
  }

  Future<String> _buildContext(String userId) async {
    await BoxManager().openAllBoxes(userId);
    final transactions = BoxManager().getBox<Transaction>(BoxManager.transactionsBoxName, userId).values;
    final now = DateTime.now();
    final recent = transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 30)))).toList();
    
    // Sort
    recent.sort((a,b) => b.date.compareTo(a.date));
    
    // Summary
    double income = 0;
    double expense = 0;
    for (var t in recent) {
      if (t.type == TransactionType.income) income += t.amount; else expense += t.amount;
    }
    
    // Investments
    final investments = BoxManager().getBox<InvestmentModel>(BoxManager.investmentsBoxName, userId).values;
    double totalInvested = investments.fold(0, (sum, i) => sum + i.currentValue);

    // Recent Summary
    final recentStr = recent.take(5).map((t) => "${t.title} (${t.amount})").join(", ");
    
    return """
    Last 30 Days:
    Income: $income
    Expense: $expense
    Total Invested: $totalInvested
    Recent Transactions: $recentStr
    """;
  }
}
