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

  // Inline editing state
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditingName = false;
  bool _isEditingEmail = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _userName;
    _emailController.text = _userEmail;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveName() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        _userName = _nameController.text.trim();
        _userInitials = _getInitials(_userName);
        _isEditingName = false;
      });
      // TODO: Save to backend
    }
  }

  void _saveEmail() {
    if (_emailController.text.trim().isNotEmpty && _isValidEmail(_emailController.text.trim())) {
      setState(() {
        _userEmail = _emailController.text.trim();
        _isEditingEmail = false;
      });
      // TODO: Save to backend
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Deep navy - clean design
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.white.withOpacity(0.6)),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profile Avatar
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _userInitials,
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Implement photo picker
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Photo picker coming soon!')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0A1628),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing32),

                // Name Field (Editable)
                _buildEditableField(
                  label: 'FULL NAME',
                  controller: _nameController,
                  isEditing: _isEditingName,
                  icon: Icons.person_outline,
                  onEdit: () => setState(() => _isEditingName = true),
                  onSave: _saveName,
                  onCancel: () {
                    setState(() {
                      _isEditingName = false;
                      _nameController.text = _userName;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Email Field (Editable)
                _buildEditableField(
                  label: 'EMAIL ADDRESS',
                  controller: _emailController,
                  isEditing: _isEditingEmail,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onEdit: () => setState(() => _isEditingEmail = true),
                  onSave: _saveEmail,
                  onCancel: () {
                    setState(() {
                      _isEditingEmail = false;
                      _emailController.text = _userEmail;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacing24),

                // Premium Status Card
                CleanCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isPremium 
                                  ? AppTheme.accentBlue.withOpacity(0.2)
                                  : AppTheme.accentBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.accentBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              _isPremium ? Icons.workspace_premium_outlined : Icons.card_membership_outlined,
                              color: AppTheme.accentBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPremium ? 'Premium Member' : 'Free Plan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Member since $_memberSince',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Upgrade',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
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

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required IconData icon,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return CleanCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.6), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: isEditing
                      ? TextField(
                          controller: controller,
                          keyboardType: keyboardType,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          autofocus: true,
                        )
                      : GestureDetector(
                          onTap: onEdit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              controller.text,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ),
                if (isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.check_outlined, color: AppTheme.accentGreen, size: 20),
                    onPressed: onSave,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_outlined, color: AppTheme.accentRed, size: 20),
                    onPressed: onCancel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ] else
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.white.withOpacity(0.6), size: 18),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Transactions',
            '$_totalTransactions',
            Icons.account_balance_wallet_outlined,
            AppTheme.accentBlue,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.1),
          ),
          _buildStatItem(
            'Budgets',
            '$_activeBudgets',
            Icons.pie_chart_outline,
            AppTheme.accentRed,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.1),
          ),
          _buildStatItem(
            'Investments',
            '$_totalInvestments',
            Icons.trending_up_outlined,
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
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumUpgradeCard() {
    return CleanCard(
      backgroundColor: AppTheme.accentBlue.withOpacity(0.15),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: AppTheme.accentBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Upgrade to Premium',
                  style: GoogleFonts.poppins(
                    color: AppTheme.accentBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPremiumBenefit('AI-powered financial insights'),
          _buildPremiumBenefit('Personalized recommendations'),
          _buildPremiumBenefit('Advanced analytics'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Start Free Trial - KES 499/month',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBenefitsCard() {
    return CleanCard(
      backgroundColor: AppTheme.accentBlue.withOpacity(0.15),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Premium Benefits',
                  style: GoogleFonts.poppins(
                    color: AppTheme.accentBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        CleanCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildAchievementItem(
                '💰 First Transaction',
                'Tracked your first expense',
                Icons.check_circle_outlined,
                AppTheme.accentGreen,
                true,
              ),
              const SizedBox(height: 16),
              _buildAchievementItem(
                '📊 Budget Master',
                'Created 5 active budgets',
                Icons.check_circle_outlined,
                AppTheme.accentGreen,
                true,
              ),
              const SizedBox(height: 16),
              _buildAchievementItem(
                '📈 Investor',
                'Added your first investment',
                Icons.check_circle_outlined,
                AppTheme.accentGreen,
                true,
              ),
              const SizedBox(height: 16),
              _buildAchievementItem(
                '🎯 Savings Champion',
                'Maintained 20% savings rate for 3 months',
                Icons.radio_button_unchecked_outlined,
                Colors.white.withOpacity(0.3),
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
            color: unlocked ? color : Colors.white.withOpacity(0.3),
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
                  color: unlocked ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outlined, color: AppTheme.accentBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



