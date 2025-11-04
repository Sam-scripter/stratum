import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _transactionAlerts = true;
  bool _budgetAlerts = true;
  bool _investmentUpdates = true;
  bool _aiInsights = true;
  bool _paymentReminders = true;
  bool _marketingEmails = false;

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryGold,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
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
            // General Settings
            Text(
              'General',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSwitchTile(
              'Push Notifications',
              'Receive notifications on your device',
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
            ),
            _buildSwitchTile(
              'Email Notifications',
              'Receive notifications via email',
              _emailNotifications,
              (value) => setState(() => _emailNotifications = value),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Transaction Alerts
            Text(
              'Transaction Alerts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSwitchTile(
              'Transaction Alerts',
              'Get notified when transactions are added',
              _transactionAlerts,
              (value) => setState(() => _transactionAlerts = value),
            ),
            _buildSwitchTile(
              'Payment Reminders',
              'Reminders for upcoming payments',
              _paymentReminders,
              (value) => setState(() => _paymentReminders = value),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Budget Alerts
            Text(
              'Budget Alerts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSwitchTile(
              'Budget Warnings',
              'Alerts when approaching budget limits',
              _budgetAlerts,
              (value) => setState(() => _budgetAlerts = value),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Investment Updates
            Text(
              'Investment Updates',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSwitchTile(
              'Investment Updates',
              'Notifications about investment performance',
              _investmentUpdates,
              (value) => setState(() => _investmentUpdates = value),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // AI Insights
            Text(
              'AI Insights',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSwitchTile(
              'AI Insights',
              'Receive AI-powered financial insights',
              _aiInsights,
              (value) => setState(() => _aiInsights = value),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Marketing
            Text(
              'Marketing',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildSwitchTile(
              'Marketing Emails',
              'Receive updates about new features',
              _marketingEmails,
              (value) => setState(() => _marketingEmails = value),
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }
}

