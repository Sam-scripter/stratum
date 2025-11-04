import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stratum/screens/home/home_screen.dart';
import 'package:stratum/widgets/enhanced_widgets_demo.dart';
import 'package:stratum/screens/transactions/transactions_screen.dart';
import 'package:stratum/screens/budgets/budget_screen.dart';
import 'package:stratum/screens/investments/investments_screen.dart';
import 'package:stratum/screens/profile/profile_screen.dart';
import 'package:stratum/screens/splash/splash_screen.dart';
import 'package:stratum/theme/app_theme.dart';

void main() {
  runApp(const StratumApp());
}

class StratumApp extends StatelessWidget {
  const StratumApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stratum - Financial Advisor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/enhanced-demo': (context) => const EnhancedWidgetsDemo(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TransactionsScreen(),
    const BudgetScreen(),
    const InvestmentsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceGray,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radius20),
            topRight: Radius.circular(AppTheme.radius20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radius20),
            topRight: Radius.circular(AppTheme.radius20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.surfaceGray,
            elevation: 0,
            selectedItemColor: AppTheme.primaryGold,
            unselectedItemColor: AppTheme.textGray,
            selectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded),
                label: 'Home',
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radius8),
                  ),
                  child: const Icon(Icons.home_rounded),
                ),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.receipt_long_rounded),
                label: 'Transactions',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.pie_chart_rounded),
                label: 'Budget',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.trending_up_rounded),
                label: 'Invest',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
