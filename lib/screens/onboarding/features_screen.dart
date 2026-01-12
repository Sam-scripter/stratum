import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Powerful Features',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Everything you need to manage your finances',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppTheme.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Features List
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFeature(
                        icon: Icons.sms_outlined,
                        title: 'Automatic SMS Reading',
                        description: 'Automatically detects and categorizes transactions from M-PESA, KCB, and other banks',
                        color: AppTheme.accentBlue,
                      ),
                      const SizedBox(height: 24),
                      _buildFeature(
                        icon: Icons.category_outlined,
                        title: 'Smart Categorization',
                        description: 'AI learns your spending patterns and automatically categorizes transactions',
                        color: AppTheme.accentGreen,
                      ),
                      const SizedBox(height: 24),
                      _buildFeature(
                        icon: Icons.pie_chart_outline,
                        title: 'Budget Tracking',
                        description: 'Set budgets, track spending, and get alerts when you\'re approaching limits',
                        color: AppTheme.primaryGold,
                      ),
                      const SizedBox(height: 24),
                      _buildFeature(
                        icon: Icons.trending_up_outlined,
                        title: 'Investment Tracking',
                        description: 'Monitor your investments and savings goals with detailed analytics',
                        color: AppTheme.accentOrange,
                      ),
                      const SizedBox(height: 24),
                      _buildFeature(
                        icon: Icons.psychology_outlined,
                        title: 'AI Insights',
                        description: 'Get personalized financial advice and recommendations based on your spending',
                        color: AppTheme.accentRed,
                      ),
                      const SizedBox(height: 24),
                      _buildFeature(
                        icon: Icons.lock_outline,
                        title: 'Privacy First',
                        description: 'All your financial data stays on your device. We never access your information',
                        color: AppTheme.textGray,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

