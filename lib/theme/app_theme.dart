// app_theme.dart (stratum):

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Color Palette
  static const Color primaryGold = Color(0xFFD4AF37); // Luxury Gold
  static const Color lightGold = Color(0xFFE5C158); // Light Gold
  static const Color darkGold = Color(0xFFB8941F); // Dark Gold
  static const Color platinum = Color(0xFFE5E4E2); // Platinum
  static const Color primaryDark = Color(0xFF0A0E1A); // Deep Navy/Black (darker)
  static const Color cardBg = Color(0xFF141821); // Card Background (slightly lighter)
  static const Color primaryLight = Color(0xFFF8F9FA); // Off-white
  static const Color accentBlue = Color(0xFF4A90E2); // Professional Blue
  static const Color accentGreen = Color(0xFF00D9A3); // Success Green (brighter)
  static const Color accentRed = Color(0xFFEF4444); // Alert Red
  static const Color accentOrange = Color(0xFFF59E0B); // Warning Orange
  static const Color deepPurple = Color(0xFF1A0F2E); // Deep Purple
  static const Color surfaceGray = Color(0xFF1F2937); // Card Background (keep for compatibility)
  static const Color borderGray = Color(0xFF374151); // Border Color
  static const Color textGray = Color(0xFFD1D5DB); // Light Text

  // Gradients for Premium Feel
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0E1A), // Deep Navy
      Color(0xFF1A0F2E), // Deep Purple
      Color(0xFF0A0E1A), // Deep Navy
    ],
  );

  // Alias for primary gradient
  static LinearGradient get primaryGradient => premiumGradient;

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF4D03F), // Bright gold
      Color(0xFFD4AF37), // Standard gold
      Color(0xFFB8941A), // Deep gold
      Color(0xFFA89968), // Dark gold
    ],
    stops: [0.0, 0.33, 0.66, 1.0],
  );

  // Gold to Platinum gradient for text
  static const LinearGradient goldToPlatinumGradient = LinearGradient(
    colors: [
      Color(0xFFD4AF37), // Gold
      Color(0xFFE5C158), // Light Gold
      Color(0xFFE5E4E2), // Platinum
    ],
  );

  // Gold shimmer gradient for animations
  static const LinearGradient goldShimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.5),
    end: Alignment(1.0, 0.5),
    colors: [
      Color(0xFFD4AF37),
      Color(0xFFE5C158),
      Color(0xFFE5E4E2),
      Color(0xFFE5C158),
      Color(0xFFD4AF37),
    ],
    stops: [0.0, 0.3, 0.5, 0.7, 1.0],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // Green
      Color(0xFF059669), // Darker Green
    ],
  );

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A1628), // Deep navy - clean design
      primaryColor: accentBlue, // Use accent blue instead of gold
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryLight,
        ),
      ),

      // Text Themes
      textTheme: TextTheme(
        // Display Styles
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: primaryLight,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primaryLight,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryLight,
        ),

        // Headline Styles
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryLight,
        ),

        // Title Styles
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primaryLight,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textGray,
        ),

        // Body Styles
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: primaryLight,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textGray,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textGray,
        ),

        // Label Styles
        labelLarge: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accentBlue, // Use accent blue instead of gold
        ),
      ),

      // Button Themes - Using accent blue instead of gold for calm design
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0, // No elevation for clean design
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentBlue,
          side: BorderSide(color: accentBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textGray,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceGray,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceGray,
        selectedColor: accentBlue, // Use accent blue instead of gold
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Spacing Constants
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;

  // Border Radius Constants
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
}
