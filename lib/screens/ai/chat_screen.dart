import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/ai/ai_consultant_service.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/box_manager.dart';
import '../../models/ai/chat_message_model.dart';
import '../../core/secrets.dart';

class ChatScreen extends StatefulWidget {
  final String sessionId;
  const ChatScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatUser _user = ChatUser(
    id: '1',
    firstName: 'Me',
  );
  
  final ChatUser _ai = ChatUser(
    id: '2',
    firstName: 'Atlas',
    profileImage: 'https://ui-avatars.com/api/?name=AI&background=D4AF37&color=fff', // Gold avatar
  );

  List<ChatMessage> _messages = [];
  final AIConsultantService _aiService = AIConsultantService();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    await _aiService.initialize(AppSecrets.geminiApiKey, userId);
    await _aiService.loadSession(widget.sessionId);
    
    // Load from Hive
    // Box might not be open if we came directly? Safe to use getBox as initialize opens it.
    final box = BoxManager().getBox<ChatMessageModel>(BoxManager.chatBoxName, userId);
    final history = box.values
        .where((m) => m.sessionId == widget.sessionId)
        .toList()
        ..sort((a,b) => b.createdAt.compareTo(a.createdAt)); // Newest first for UI

    if (mounted) {
      if (history.isNotEmpty) {
        setState(() {
          _messages = history.map((m) => ChatMessage(
            text: m.text,
            user: m.senderId == 'user' ? _user : _ai,
            createdAt: m.createdAt,
          )).toList();
        });
      } else {
        setState(() {
          _messages = [
            ChatMessage(
              text: 'Hello! I\'m Atlas, your personal financial advisor. Ask me anything about your spending or budget! 💸',
              user: _ai,
              createdAt: DateTime.now(),
            )
          ];
        });
      }
    }
  }

  static const int _maxAtlasMessages = 5;

  int _countUserMessages() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return 0;
    try {
      final box = BoxManager().getBox<ChatMessageModel>(BoxManager.chatBoxName, userId);
      return box.values.where((m) => m.senderId == 'user').length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _onSend(ChatMessage message) async {
    if (_countUserMessages() >= _maxAtlasMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You've used your 5 trial messages. Full Atlas experience coming in future updates.",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppTheme.primaryGold,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _messages.insert(0, message); // Add user message
      _isTyping = true;
    });

    try {
      final responseText = await _aiService.sendMessage(message.text);

      final aiMessage = ChatMessage(
        text: responseText,
        user: _ai,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.insert(0, aiMessage);
        _isTyping = false;
      });
    } catch (e) {
      final err = e.toString().toLowerCase();
      final isUnavailable = err.contains('quota') ||
          err.contains('exceeded') ||
          err.contains('credits') ||
          err.contains('afford') ||
          err.contains('max_tokens');
      final friendly = isUnavailable
          ? 'Atlas is not available right now.'
          : 'Sorry, something went wrong. Please try again.';
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            text: friendly,
            user: _ai,
            createdAt: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2332),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primaryGold),
            SizedBox(width: 8),
            Text('AI Advisor', style: GoogleFonts.poppins(color: Colors.white)),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: DashChat(
        currentUser: _user,
        onSend: _onSend,
        messages: _messages,
        typingUsers: _isTyping ? [_ai] : [],
        messageOptions: MessageOptions(
          containerColor: Color(0xFF2C3E50),
          currentUserContainerColor: AppTheme.primaryGold,
          textColor: Colors.white,
          currentUserTextColor: Colors.black,
          timeFontSize: 10,
          showOtherUsersAvatar: true,
          showCurrentUserAvatar: false,
          avatarBuilder: (user, onPress, onLongPress) {
             return Container(
               margin: EdgeInsets.only(right: 8),
               child: CircleAvatar(
                 backgroundColor: AppTheme.primaryGold,
                 child: Text("AI", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
               ),
             );
          }
        ),
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            hintText: "Ask about your finances...",
            hintStyle: TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Color(0xFF1A2332),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          inputTextStyle: TextStyle(color: Colors.white),
          sendButtonBuilder: (send) => IconButton(
            icon: Icon(Icons.send, color: AppTheme.primaryGold),
            onPressed: send,
          ),
        ),
      ),
    );
  }
}
