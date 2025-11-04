import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
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
                    '1. Acceptance of Terms',
                    'By accessing and using Stratum, you accept and agree to be bound by the terms and provision of this agreement.',
                  ),
                  _buildSection(
                    '2. Use License',
                    'Permission is granted to temporarily access the materials on Stratum\'s app for personal, non-commercial transitory viewing only.',
                  ),
                  _buildSection(
                    '3. Privacy Policy',
                    'Your use of Stratum is also governed by our Privacy Policy. Please review our Privacy Policy to understand our practices.',
                  ),
                  _buildSection(
                    '4. Financial Information',
                    'Stratum provides tools to track and manage your finances. We do not provide financial advice. Always consult with a qualified financial advisor for financial decisions.',
                  ),
                  _buildSection(
                    '5. Data Security',
                    'We implement industry-standard security measures to protect your data. However, no method of transmission over the Internet is 100% secure.',
                  ),
                  _buildSection(
                    '6. Limitation of Liability',
                    'In no event shall Stratum or its suppliers be liable for any damages arising out of the use or inability to use the app.',
                  ),
                  _buildSection(
                    '7. Subscription Terms',
                    'Premium subscriptions are billed monthly or annually. You can cancel your subscription at any time through your account settings.',
                  ),
                  _buildSection(
                    '8. Changes to Terms',
                    'Stratum reserves the right to revise these terms at any time. Continued use of the app after changes constitutes acceptance of new terms.',
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

