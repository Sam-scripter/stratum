import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stratum/firebase_options.dart';
import 'package:stratum/screens/home/home_screen.dart';
import 'package:stratum/screens/transactions/transactions_screen.dart';
import 'package:stratum/screens/budgets/budget_screen.dart';
import 'package:stratum/screens/investments/investments_screen.dart';
import 'package:stratum/screens/profile/profile_screen.dart';
import 'package:stratum/screens/splash/splash_screen.dart';
import 'package:stratum/theme/app_theme.dart';
import 'package:stratum/models/box_manager.dart';
import 'package:stratum/services/notification/notification_service.dart';
import 'package:stratum/services/background/sms_background_service.dart';
import 'package:provider/provider.dart';
import 'package:stratum/repositories/financial_repository.dart';
import 'package:stratum/services/finances/financial_service.dart';
import 'package:stratum/services/sms_reader/sms_reader_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  BoxManager.registerAdapters();
  await NotificationService().initialize();
  await BackgroundSmsService.initialize();

  runApp(const StratumApp());
}

class StratumApp extends StatelessWidget {
  const StratumApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Provide User (Auth State)
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
        ),
        // 2. Provide FinancialRepository dependent on User
        ChangeNotifierProxyProvider<User?, FinancialRepository>(
          create: (_) => FinancialRepository(
            userId: '', // Initial empty state
            boxManager: BoxManager(),
            financialService: FinancialService(),
            smsReaderService: SmsReaderService(''),
          ),
          update: (_, user, previous) {
            // If user changed or previous (initial) was empty, recreate or update
            final userId = user?.uid ?? '';
            
            // If we already have a repository for this user, return it? 
            // Actually, ChangeNotifierProxyProvider usually disposes previous when created.
            // But here we want to Create a fresh one if userId changed.
            
            if (previous != null && previous.userId == userId) {
                return previous;
            }
            
            return FinancialRepository(
              userId: userId,
              boxManager: BoxManager(),
              financialService: FinancialService(),
              smsReaderService: SmsReaderService(userId),
            );
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Stratum',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // We can now just check the User provided by StreamProvider
    final user = context.watch<User?>();
    
    if (user != null) {
      // User is logged in, check if we have a pending notification to navigate to
      WidgetsBinding.instance.addPostFrameCallback((_) {
         NotificationService.instance.consumePendingTransaction();
      });
      return const MainScreen();
    }
    
    return const SplashScreen();
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
    const BudgetScreen(), // userId passed optionally now, or we can pass it
    const InvestmentsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Update BudgetScreen usage if needed, but we made userId optional there.
    // We can also rebuild _screens if we want to pass userId explicitely, 
    // but SingleTickerProviderStateMixin in BudgetScreen might complain if recreated?
    // Actually, _screens usually should be built in build() or initialized in initState.
    // Keeping it simple.
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.5),
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
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Invest',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
