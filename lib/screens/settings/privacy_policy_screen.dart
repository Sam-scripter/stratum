import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Updated: January 1, 2024',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  _buildSection(
                    '1. Information We Collect',
                    'We collect information you provide directly to us, such as when you create an account, add transactions, or contact support. This includes financial data, personal information, and usage data.',
                  ),
                  _buildSection(
                    '2. How We Use Your Information',
                    'We use your information to provide, maintain, and improve our services, process transactions, send notifications, and provide customer support. We do not sell your personal information.',
                  ),
                  _buildSection(
                    '3. Data Storage and Security',
                    'Your data is stored securely using industry-standard encryption. We implement appropriate technical and organizational measures to protect your personal information.',
                  ),
                  _buildSection(
                    '4. Data Sharing',
                    'We may share anonymized, aggregated data with third-party service providers to help us operate our app. We do not share personally identifiable financial information without your consent.',
                  ),
                  _buildSection(
                    '5. Your Rights',
                    'You have the right to access, update, or delete your personal information at any time. You can export your data or request deletion through the app settings.',
                  ),
                  _buildSection(
                    '6. Cookies and Tracking',
                    'We use cookies and similar tracking technologies to track activity on our app and store certain information to improve your experience.',
                  ),
                  _buildSection(
                    '7. Third-Party Services',
                    'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties.',
                  ),
                  _buildSection(
                    '8. Children\'s Privacy',
                    'Our app is not intended for children under 13 years of age. We do not knowingly collect personal information from children.',
                  ),
                  _buildSection(
                    '9. Changes to Privacy Policy',
                    'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.',
                  ),
                  _buildSection(
                    '10. Contact Us',
                    'If you have questions about this Privacy Policy, please contact us at privacy@stratum.app',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGold,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

