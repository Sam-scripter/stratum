import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/box_manager.dart';
import '../../models/ai/chat_session_model.dart';
import '../../services/ai/ai_consultant_service.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final AIConsultantService _aiService = AIConsultantService();
  String _userId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _initialize();
  }

  Future<void> _initialize() async {
     await _aiService.initialize('AIzaSyCnnNwQPMAvbXgQCL6Cblp_UL-Z0Ywe5-8', _userId);
     setState(() => _isLoading = false);
  }

  Future<void> _startNewChat() async {
    try {
      final sessionId = await _aiService.createNewSession();
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(sessionId: sessionId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error starting chat: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: Text('Atlas AI', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF1A2332),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
        : ValueListenableBuilder<Box<ChatSessionModel>>(
            valueListenable: BoxManager().getBox<ChatSessionModel>(BoxManager.chatSessionBoxName, _userId).listenable(),
            builder: (context, box, _) {
              final sessions = box.values.toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

              if (sessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text(
                        "No conversations yet",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _startNewChat,
                        icon: Icon(Icons.add),
                        label: Text("Start New Chat"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      )
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                separatorBuilder: (ctx, i) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _buildSessionCard(session);
                },
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewChat,
        backgroundColor: AppTheme.primaryGold,
        icon: Icon(Icons.add, color: Colors.black),
        label: Text("New Chat", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSessionCard(ChatSessionModel session) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: AppTheme.accentRed,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
         session.delete();
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
               builder: (context) => ChatScreen(sessionId: session.id),
            )
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2332),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
               Container(
                 width: 48,
                 height: 48,
                 decoration: BoxDecoration(
                   color: AppTheme.primaryGold.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: Center(
                   child: Text("🤖", style: TextStyle(fontSize: 24)),
                 ),
               ),
               SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       session.title,
                       style: GoogleFonts.poppins(
                         color: Colors.white,
                         fontWeight: FontWeight.w600,
                         fontSize: 16,
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                     SizedBox(height: 4),
                     Text(
                       session.summary.isEmpty ? "No messages" : session.summary,
                       style: GoogleFonts.poppins(
                         color: Colors.white54,
                         fontSize: 12,
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ],
                 ),
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   Text(
                     _formatDate(session.updatedAt),
                     style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
                   ),
                   SizedBox(height: 8),
                   Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
                 ],
               )
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    if (DateTime.now().difference(date).inDays < 1) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('MM/dd').format(date);
  }
}
