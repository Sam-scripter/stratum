import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'features_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppTheme.premiumGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'S',
                    style: GoogleFonts.poppins(
                      fontSize: 60,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // App Name
              Text(
                'STRATUM',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tagline
              Text(
                'Your Personal Financial Advisor',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textGray,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Description
              Text(
                'Take control of your finances with AI-powered insights. Track spending, manage budgets, and make smarter financial decisions.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppTheme.textGray,
                  height: 1.6,
                ),
              ),
              
              const Spacer(),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FeaturesScreen(),
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
                    'Get Started',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Login Button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Text(
                  'Already have an account? Login',
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
}

