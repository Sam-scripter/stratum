import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/investment/discover_content.dart'; // NEW
import 'discover_detail_screen.dart'; // NEW

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // backgroundDeep
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Investment 101 🎓"),
            SizedBox(height: 12),
            SizedBox(
              height: 150, // Slightly taller for better touch targets
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: DiscoverData.education.length,
                separatorBuilder: (_,__) => SizedBox(width: 12),
                itemBuilder: (context, index) {
                   return _buildLearnCard(context, DiscoverData.education[index]);
                },
              ),
            ),
            
            SizedBox(height: 24),
            _buildSectionHeader("Trusted Platforms 🏛️"),
            SizedBox(height: 12),
            ...DiscoverData.platforms.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPlatformCard(context, item),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLearnCard(BuildContext context, DiscoverItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DiscoverDetailScreen(item: item)));
      },
      child: Container(
        width: 160,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332), // backgroundLight
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: item.color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(item.iconData ?? Icons.lightbulb, color: item.color, size: 20),
            ),
            Spacer(),
            Text(item.title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            SizedBox(height: 4),
            Text(item.subtitle, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformCard(BuildContext context, DiscoverItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DiscoverDetailScreen(item: item)));
      },
      child: Container(
        padding: EdgeInsets.all(16),
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
                 color: item.color.withOpacity(0.1),
                 shape: BoxShape.circle,
               ),
               child: Icon(item.iconData ?? Icons.public, color: item.color),
             ),
             SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(item.title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                   Text(item.subtitle, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                 ],
               ),
             ),
             Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
