import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Same as backgroundDeep
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Investment 101 🎓"),
            SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildLearnCard("What is an MMF?", "Low risk, daily interest.", Colors.greenAccent),
                  SizedBox(width: 12),
                  _buildLearnCard("Stocks vs Bonds", "Ownership vs Lending.", Colors.blueAccent),
                  SizedBox(width: 12),
                  _buildLearnCard("Crypto Basics", "High risk, high reward.", Colors.orangeAccent),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            _buildSectionHeader("Trusted Platforms 🏛️"),
            SizedBox(height: 12),
            _buildPlatformCard(
              "Mali (Safaricom)", 
              "Invest via M-Pesa. 10% annual interest.",
              "https://www.safaricom.co.ke/personal/m-pesa/mali",
              Icons.phone_android
            ),
            SizedBox(height: 12),
            _buildPlatformCard(
              "CIC Money Market", 
              "Regulated Unit Trust. consistent returns.",
              "https://cic.co.ke/personal/financial-planning/unit-trusts/",
              Icons.account_balance
            ),
            SizedBox(height: 12),
            _buildPlatformCard(
              "Hisa App", 
              "Buy US Stocks (Apple, Tesla) from Kenya.",
              "https://hisa.co/",
              Icons.show_chart
            ),
             SizedBox(height: 12),
            _buildPlatformCard(
              "Binance", 
              "Leading Crypto Exchange.",
              "https://www.binance.com",
              Icons.currency_bitcoin
            ),
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

  Widget _buildLearnCard(String title, String subtitle, Color color) {
    return Container(
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
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.lightbulb_outline, color: color, size: 20),
          ),
          Spacer(),
          Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10), maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(String name, String desc, String url, IconData icon) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
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
                 color: AppTheme.primaryGold.withOpacity(0.1),
                 shape: BoxShape.circle,
               ),
               child: Icon(icon, color: AppTheme.primaryGold),
             ),
             SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                   Text(desc, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                 ],
               ),
             ),
             Icon(Icons.open_in_new, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
