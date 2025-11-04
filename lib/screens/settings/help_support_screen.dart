import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Support
            Text(
              'Contact Support',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildContactCard(
              'Email Support',
              'support@stratum.app',
              Icons.email_outlined,
              AppTheme.accentBlue,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening email client...'),
                    backgroundColor: AppTheme.accentBlue,
                  ),
                );
              },
            ),
            _buildContactCard(
              'Live Chat',
              'Chat with our support team',
              Icons.chat_bubble_outline,
              AppTheme.accentGreen,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Live chat coming soon!'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              },
            ),
            _buildContactCard(
              'Phone Support',
              '+254 700 000 000',
              Icons.phone_outlined,
              AppTheme.accentOrange,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calling support...'),
                    backgroundColor: AppTheme.accentOrange,
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing24),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildFAQItem(
              'How do I add a transaction?',
              'Tap the "+" button on the Transactions screen or use the Quick Actions on the home screen.',
            ),
            _buildFAQItem(
              'How do I set a budget?',
              'Go to the Budget screen and tap the "+" icon in the app bar to create a new budget.',
            ),
            _buildFAQItem(
              'Can I sync my M-Pesa transactions?',
              'Yes! Go to Settings > M-Pesa Integration and connect your account to automatically import transactions.',
            ),
            _buildFAQItem(
              'How do I upgrade to Premium?',
              'Visit your Profile screen and tap the "Upgrade to Premium" card to start your free trial.',
            ),
            _buildFAQItem(
              'How do I export my data?',
              'Go to Settings > Export Data to download your financial information in CSV, JSON, or PDF format.',
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: AppTheme.primaryGold, size: 20),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    question,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              answer,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textGray,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

