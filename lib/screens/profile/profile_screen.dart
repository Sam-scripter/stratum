import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock user data - in real app, this would come from a state management solution
  String _userName = 'Alex Johnson';
  String _userEmail = 'alex.johnson@email.com';
  String _userInitials = 'AJ';
  bool _isPremium = false;
  
  // Mock stats
  final int _totalTransactions = 247;
  final int _activeBudgets = 6;
  final int _totalInvestments = 4;
  final String _memberSince = 'Jan 2024';

  void _handleEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialName: _userName,
          initialEmail: _userEmail,
          initialInitials: _userInitials,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _userName = result['name'] as String;
        _userEmail = result['email'] as String;
        _userInitials = result['initials'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.primaryGold),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          children: [
            // Profile Header
            PremiumCard(
              hasGlow: true,
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _userInitials,
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _handleEditProfile,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacing8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: AppTheme.primaryDark,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  GestureDetector(
                    onTap: _handleEditProfile,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _userName,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppTheme.textGray,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    _userEmail,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing8,
                    ),
                    decoration: BoxDecoration(
                      gradient: _isPremium ? AppTheme.goldGradient : null,
                      color: _isPremium ? null : AppTheme.primaryGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radius20),
                      border: Border.all(
                        color: AppTheme.primaryGold.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPremium ? Icons.workspace_premium : Icons.card_membership,
                          size: 16,
                          color: _isPremium ? AppTheme.primaryDark : AppTheme.primaryGold,
                        ),
                        const SizedBox(width: AppTheme.spacing4),
                        Text(
                          _isPremium ? '⭐ Premium' : '🆓 Free Plan',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _isPremium ? AppTheme.primaryDark : AppTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    'Member since $_memberSince',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Quick Stats Section
            _buildQuickStats(),
            const SizedBox(height: AppTheme.spacing24),

            // Upgrade to Premium or Premium Benefits
            if (!_isPremium)
              _buildPremiumUpgradeCard()
            else
              _buildPremiumBenefitsCard(),
            const SizedBox(height: AppTheme.spacing24),

            // Achievements/Milestones Section
            _buildAchievementsSection(),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return PremiumCard(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Transactions',
            '$_totalTransactions',
            Icons.account_balance_wallet,
            AppTheme.accentBlue,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.borderGray.withOpacity(0.3),
          ),
          _buildStatItem(
            'Budgets',
            '$_activeBudgets',
            Icons.pie_chart,
            AppTheme.accentRed,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.borderGray.withOpacity(0.3),
          ),
          _buildStatItem(
            'Investments',
            '$_totalInvestments',
            Icons.trending_up,
            AppTheme.accentGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radius8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryLight,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumUpgradeCard() {
    return PremiumCard(
      backgroundColor: AppTheme.primaryGold.withOpacity(0.15),
      hasGlow: true,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: AppTheme.primaryGold,
                size: 28,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  'Upgrade to Premium',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildPremiumBenefit('AI-powered financial insights'),
          _buildPremiumBenefit('Personalized recommendations'),
          _buildPremiumBenefit('Advanced analytics'),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(AppTheme.radius12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Start Free Trial - KES 499/month',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primaryDark,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBenefitsCard() {
    return PremiumCard(
      backgroundColor: AppTheme.primaryGold.withOpacity(0.1),
      hasGlow: true,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppTheme.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Text(
                  'Premium Benefits',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildPremiumBenefit('✓ AI-powered financial insights'),
          _buildPremiumBenefit('✓ Personalized recommendations'),
          _buildPremiumBenefit('✓ Advanced analytics & reports'),
          _buildPremiumBenefit('✓ Priority customer support'),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryLight,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        PremiumCard(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            children: [
              _buildAchievementItem(
                '💰 First Transaction',
                'Tracked your first expense',
                Icons.check_circle,
                AppTheme.accentGreen,
                true,
              ),
              const SizedBox(height: AppTheme.spacing16),
              _buildAchievementItem(
                '📊 Budget Master',
                'Created 5 active budgets',
                Icons.check_circle,
                AppTheme.accentGreen,
                true,
              ),
              const SizedBox(height: AppTheme.spacing16),
              _buildAchievementItem(
                '📈 Investor',
                'Added your first investment',
                Icons.check_circle,
                AppTheme.accentGreen,
                true,
              ),
              const SizedBox(height: AppTheme.spacing16),
              _buildAchievementItem(
                '🎯 Savings Champion',
                'Maintained 20% savings rate for 3 months',
                Icons.radio_button_unchecked,
                AppTheme.textGray,
                false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(
    String title,
    String description,
    IconData icon,
    Color color,
    bool unlocked,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          decoration: BoxDecoration(
            color: unlocked ? color.withOpacity(0.15) : AppTheme.surfaceGray.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            border: Border.all(
              color: unlocked ? color.withOpacity(0.3) : AppTheme.borderGray.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: unlocked ? color : AppTheme.textGray,
            size: 24,
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: unlocked ? AppTheme.primaryLight : AppTheme.textGray,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primaryGold, size: 18),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: AppTheme.primaryLight,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



