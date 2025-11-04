import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import 'account_settings_screen.dart';
import 'mpesa_integration_screen.dart';
import 'notification_settings_screen.dart';
import 'currency_settings_screen.dart';
import 'security_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'export_data_screen.dart';
import 'help_support_screen.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Settings',
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
            // Account Settings Section
            Text(
              'Account',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSettingItem(
              context,
              'Account Settings',
              'Manage your account information',
              Icons.person_outline,
              AppTheme.accentBlue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              'M-Pesa Integration',
              'Connect and manage your M-Pesa account',
              Icons.sms_outlined,
              AppTheme.accentGreen,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MPesaIntegrationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Preferences Section
            Text(
              'Preferences',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSettingItem(
              context,
              'Notifications',
              'Manage notification preferences',
              Icons.notifications_outlined,
              AppTheme.accentOrange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              'Currency',
              'Change default currency',
              Icons.attach_money,
              AppTheme.accentBlue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CurrencySettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Security & Privacy Section
            Text(
              'Security & Privacy',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSettingItem(
              context,
              'Security',
              'Change password, enable 2FA',
              Icons.security_outlined,
              AppTheme.accentBlue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SecuritySettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              'Privacy',
              'Manage your privacy settings',
              Icons.privacy_tip_outlined,
              AppTheme.accentBlue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Data Management Section
            Text(
              'Data',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSettingItem(
              context,
              'Export Data',
              'Download your financial data',
              Icons.file_download_outlined,
              AppTheme.accentBlue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExportDataScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Support Section
            Text(
              'Support',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSettingItem(
              context,
              'Help & Support',
              'Get help and contact support',
              Icons.help_outline,
              AppTheme.textGray,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              'Terms & Conditions',
              'Read our terms and conditions',
              Icons.description_outlined,
              AppTheme.textGray,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsConditionsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              'Privacy Policy',
              'Read our privacy policy',
              Icons.privacy_tip_outlined,
              AppTheme.textGray,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              context,
              'About Stratum',
              'App version and information',
              Icons.info_outline,
              AppTheme.textGray,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.surfaceGray,
                      title: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to logout?',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textGray,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textGray,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logged out successfully'),
                                backgroundColor: AppTheme.accentGreen,
                              ),
                            );
                            // Navigate to login screen
                            // Navigator.of(context).pushAndRemoveUntil(
                            //   MaterialPageRoute(builder: (context) => LoginScreen()),
                            //   (route) => false,
                            // );
                          },
                          child: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: AppTheme.accentRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                  side: const BorderSide(color: AppTheme.accentRed, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius16),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Center(
              child: Text(
                'Version 1.0.0',
                style: GoogleFonts.poppins(
                  color: AppTheme.textGray,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
}

