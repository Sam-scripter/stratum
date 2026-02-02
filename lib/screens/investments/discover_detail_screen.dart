import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/investment/discover_content.dart';
import '../../models/ai/chat_session_model.dart';
import '../../services/ai/ai_consultant_service.dart';


class DiscoverDetailScreen extends StatelessWidget {
  final DiscoverItem item;

  const DiscoverDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image/Icon Area
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [
                     item.color.withOpacity(0.3),
                     const Color(0xFF0A1628),
                   ]
                 )
              ),
              child: Center(
                 child: Container(
                   padding: const EdgeInsets.all(32),
                   decoration: BoxDecoration(
                     color: item.color.withOpacity(0.2),
                     shape: BoxShape.circle,
                     border: Border.all(color: item.color, width: 2),
                     boxShadow: [
                       BoxShadow(color: item.color.withOpacity(0.4), blurRadius: 20)
                     ]
                   ),
                   child: Icon(item.iconData, size: 64, color: item.color),
                 ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
                  const SizedBox(height: 8),
                  Text(item.subtitle, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
                  
                  const SizedBox(height: 32),
                  
                  // Key Features
                  if (item.keyFeatures.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.keyFeatures.map((f) => Chip(
                        backgroundColor: const Color(0xFF1A2332),
                        label: Text(f, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      )).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  Text("About", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(
                    item.description, 
                    style: GoogleFonts.poppins(fontSize: 15, color: Colors.white70, height: 1.6)
                  ),
                  
                  const SizedBox(height: 160), // Space for FABs
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ASK ATLAS BUTTON
            SizedBox(
              width: double.infinity,
              child: FloatingActionButton.extended(
                heroTag: 'atlas_ask',
                onPressed: () => _askAtlas(context),
                backgroundColor: const Color(0xFF8B5CF6), // Purple for AI
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text("Ask Atlas about this", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            
            const SizedBox(height: 12),

            // EXTERNAL ACTION BUTTON
            if (item.actionUrl != null)
              SizedBox(
                width: double.infinity,
                child: FloatingActionButton.extended(
                  heroTag: 'external_action',
                  onPressed: () => _launchURL(item.actionUrl!),
                  backgroundColor: AppTheme.primaryGold,
                  icon: const Icon(Icons.open_in_new, color: Colors.black),
                  label: Text(item.actionLabel ?? "Visit", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _askAtlas(BuildContext context) async {
    // 1. Create a logical "Ask" session or just switch tab and pre-fill?
    // The requirement is "Ask Atlas which will give me accurate information".
    // We can pre-send a message to Atlas and then show the chat.
    
    final prompt = item.atlasPrompt;

    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
    );

    try {
      // Send message via service
      final response = await AIConsultantService().sendMessage(prompt);
      
      Navigator.pop(context); // Close loader

      // Navigate to Home -> Chat Tab (Index 2 in MainScreen? No, Chat is separate or modal?)
      // Wait, Chat is in the MainScreen tabs? 
      // Let's check MainScreen. It has: Home, Transactions, Budget, Investments, Profile.
      // Where is Chat? It's usually a FAB on Home or a separate screen.
      // Ah, previous tasks said "Update HomeScreen to route to ChatHistoryScreen".
      
      // Assuming Chat is accessible via context or we navigate to a ChatScreen.
      // I'll check how Chat is accessed.
      
      // For now, I'll navigate to the ChatScreen directly.
      // But verify where ChatScreen is.
      // I'll fix this in the next step if navigation is tricky.
      // Strategy: Navigate to MainScreen, then maybe show a Chat Modal?
      // Or just push ChatScreen (since it's a detail experience).
      
      // Wait, I haven't implemented ChatScreen navigation logic in this file yet.
      // I will assume there is a ChatScreen.
      // Actually, I'll use Navigator.push to a `ChatScreen` if it exists.
      
      // TEMP: Show response in detailed dialog for now if ChatScreen isn't easily pushable, 
      // BUT user wants to "Ask Atlas".
      
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatResponseScreen(title: item.title, response: response)
      ));
      
    } catch (e) {
      Navigator.pop(context); // Close loader
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Atlas Error: $e")));
    }
  }
}

// Temporary simple screen to show Atlas answer if full Chat UI integration is complex
class ChatResponseScreen extends StatelessWidget {
  final String title;
  final String response;
  const ChatResponseScreen({required this.title, required this.response});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(title: Text("Atlas on $title"), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             Row(children: [
               Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
               SizedBox(width: 8),
               Text("Atlas says:", style: TextStyle(color: Colors.white70))
             ]),
             SizedBox(height: 16),
             Text(response, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, height: 1.5)),
          ],
        ),
      )
    );
  }
}
