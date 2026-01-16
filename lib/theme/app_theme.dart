import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Base Colors (Keep your existing)
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFE5C158);
  static const Color darkGold = Color(0xFFB8941F);
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color primaryDark = Color(0xFF0A0E1A);
  static const Color cardBg = Color(0xFF141821);
  static const Color primaryLight = Color(0xFFF8F9FA);
  static const Color surfaceGray = Color(0xFF1F2937);
  static const Color borderGray = Color(0xFF374151);
  static const Color textGray = Color(0xFFD1D5DB);

  // Enhanced Accent Colors (New)
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color accentGreen = Color(0xFF10B981); // Brighter
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentPurple = Color(0xFF8B5CF6); // New
  static const Color accentTeal = Color(0xFF14B8A6); // New
  static const Color accentAmber = Color(0xFFFBBF24); // New
  static const Color accentIndigo = Color(0xFF6366F1); // New

  // Semantic Colors (New)
  static const Color positive = Color(0xFF10B981);
  static const Color negative = Color(0xFFEF4444);
  static const Color neutral = Color(0xFF6B7280);
  static const Color insight = Color(0xFF8B5CF6);
  static const Color warning = Color(0xFFF59E0B);

  // Background Variations (New)
  static const Color backgroundDeep = Color(0xFF0A0E1A); // Deepest
  static const Color backgroundMid = Color(0xFF141821); // Mid layer
  static const Color backgroundLight = Color(0xFF1A2332); // Lightest

  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0E1A),
      Color(0xFF1A0F2E),
      Color(0xFF0A0E1A),
    ],
  );

  static LinearGradient get primaryGradient => premiumGradient;

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF4D03F),
      Color(0xFFD4AF37),
      Color(0xFFB8941A),
      Color(0xFFA89968),
    ],
    stops: [0.0, 0.33, 0.66, 1.0],
  );

  // New Gradients
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient insightGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );

  // Neumorphic Shadow (New)
  static List<BoxShadow> get neumorphicShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      offset: const Offset(4, 4),
      blurRadius: 15,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.03),
      offset: const Offset(-4, -4),
      blurRadius: 15,
    ),
  ];

  // Soft Glow (New)
  static BoxShadow softGlow(Color color) => BoxShadow(
    color: color.withOpacity(0.3),
    blurRadius: 20,
    spreadRadius: 2,
  );

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDeep,
      primaryColor: primaryGold,

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDeep,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryLight,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 36,
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
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryLight,
        ),
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
        labelLarge: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryGold,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGold,
          side: const BorderSide(color: primaryGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGray.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGray.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textGray.withOpacity(0.6),
        ),
      ),

      cardTheme: CardThemeData(
        color: backgroundLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: backgroundLight,
        selectedColor: primaryGold,
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

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;

  // Border Radius
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
}