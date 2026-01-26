import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../services/background/sms_background_service.dart';

class BackgroundPermissionScreen extends StatefulWidget {
  const BackgroundPermissionScreen({Key? key}) : super(key: key);

  @override
  State<BackgroundPermissionScreen> createState() => _BackgroundPermissionScreenState();
}

class _BackgroundPermissionScreenState extends State<BackgroundPermissionScreen> {
  bool _isRequesting = false;

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    
    // 1. Request the exemption
    await BackgroundSmsService.requestBatteryExemption();
    
    // 2. Wait a moment for dialog/user action (since it's an external intent often)
    // Actually requestBatteryExemption awaits the system dialog result on some versions,
    // or returns immediately if it launches a screen.
    // We'll give it a slight delay for UX.
    await Future.delayed(const Duration(seconds: 1));

    // 3. Navigate away regardless of outcome (we can't force them)
    // But we might want to check if they enabled it?
    // Checking status again:
    final status = await Permission.ignoreBatteryOptimizations.status;
    
    if (mounted) {
      if (status.isGranted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Great! Background updates enabled.'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    // Start the background service immediately before determining navigation
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await BackgroundSmsService.startMonitoring(user.uid);
    }

    final prefs = await SharedPreferences.getInstance();
    // Ensure we mark onboarding as done if not already (it might be done in SMS screen, but safe to ensure)
    await prefs.setBool('hasCompletedSmsOnboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Animated Icon
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 1),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentBlue.withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentBlue.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_outlined,
                        size: 60,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              Text(
                'Keep Stratum Alive',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'To automatically detect transactions even when you are not using the app, Stratum needs permission to run in the background.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppTheme.textGray,
                  height: 1.6,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Explanation cards
               _buildInfoCard(
                 Icons.notifications_active_outlined, 
                 'Real-time Alerts', 
                 'Get notified immediately when money comes in or out.'
               ),
               const SizedBox(height: 16),
               _buildInfoCard(
                 Icons.battery_std, 
                 'Battery Friendly', 
                 'We optimized Stratum to use minimal power.'
               ),

              const Spacer(),

              // Action Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                   gradient: AppTheme.goldGradient,
                   borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                     BoxShadow(
                       color: AppTheme.primaryGold.withOpacity(0.3),
                       blurRadius: 12,
                       offset: const Offset(0, 4),
                     )
                   ]
                ),
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryDark),
                        )
                      : Text(
                          'Enable Background Updates',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accentBlue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                   title,
                   style: GoogleFonts.poppins(
                     fontWeight: FontWeight.w600,
                     color: AppTheme.primaryLight,
                     fontSize: 14,
                   ),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   desc,
                   style: GoogleFonts.poppins(
                     color: AppTheme.textGray,
                     fontSize: 12,
                   ),
                 ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
