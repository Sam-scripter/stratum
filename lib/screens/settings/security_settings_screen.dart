import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = true;
  bool _autoLockEnabled = true;
  int _autoLockTime = 5; // minutes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Security Settings',
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
            // Password Section
            Text(
              'Password',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildActionItem(
              'Change Password',
              'Update your account password',
              Icons.lock_outlined,
              AppTheme.accentBlue,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change password feature coming soon!'),
                    backgroundColor: AppTheme.accentBlue,
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Two-Factor Authentication
            Text(
              'Two-Factor Authentication',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable 2FA',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          'Add an extra layer of security',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _twoFactorEnabled,
                    onChanged: (value) => setState(() => _twoFactorEnabled = value),
                    activeColor: AppTheme.primaryGold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Biometric Authentication
            Text(
              'Biometric Authentication',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use Fingerprint/Face ID',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          'Quick and secure access',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _biometricEnabled,
                    onChanged: (value) => setState(() => _biometricEnabled = value),
                    activeColor: AppTheme.primaryGold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // App Lock
            Text(
              'App Lock',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto Lock',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            Text(
                              'Lock app after inactivity',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _autoLockEnabled,
                        onChanged: (value) => setState(() => _autoLockEnabled = value),
                        activeColor: AppTheme.primaryGold,
                      ),
                    ],
                  ),
                  if (_autoLockEnabled) ...[
                    const Divider(color: AppTheme.borderGray, height: AppTheme.spacing24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lock Time',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textGray,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _autoLockTime > 1
                                  ? () => setState(() => _autoLockTime--)
                                  : null,
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: _autoLockTime > 1
                                    ? AppTheme.primaryGold
                                    : AppTheme.textGray,
                              ),
                            ),
                            Text(
                              '$_autoLockTime min',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                            IconButton(
                              onPressed: _autoLockTime < 60
                                  ? () => setState(() => _autoLockTime++)
                                  : null,
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: _autoLockTime < 60
                                    ? AppTheme.primaryGold
                                    : AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
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
}

