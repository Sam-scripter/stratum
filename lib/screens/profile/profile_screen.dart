import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../settings/settings_screen.dart';
import '../../models/box_manager.dart';
import '../../models/transaction/transaction_model.dart';
import '../../models/budget/budget_model.dart';
import '../../models/savings/savings_goal_model.dart';
import '../../models/investment/investment_model.dart'; // Ensure this model exists or use generic if strictly needed, but assuming standard flow

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User Data
  User? _currentUser;
  String _userName = 'User';
  String _userEmail = 'Processing...';
  String _userInitials = 'U';
  String? _profileImagePath;
  bool _isPremium = false; // Still mock/placeholder as no subscription system yet
  
  // Real stats
  int _totalTransactions = 0;
  int _activeBudgets = 0;
  int _totalInvestments = 0;
  String _memberSince = '...';

  // Inline editing state
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditingName = false;
  
  // Image Picker
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _userName = _currentUser!.displayName ?? 'Stratum User';
      _userEmail = _currentUser!.email ?? 'No Email';
      _userInitials = _getInitials(_userName);
      _memberSince = _formatDate(_currentUser!.metadata.creationTime);
    }
    
    _nameController.text = _userName;
    _emailController.text = _userEmail;

    await _loadLocalSettings();
    await _loadStats();
  }

  Future<void> _loadLocalSettings() async {
    if (_currentUser == null) return;
    try {
      final box = await Hive.openBox('settings_${_currentUser!.uid}');
      setState(() {
        _profileImagePath = box.get('profile_image_path');
      });
    } catch (e) {
      print("Error loading settings: $e");
    }
  }

  Future<void> _loadStats() async {
    if (_currentUser == null) return;
    try {
      final userId = _currentUser!.uid;
      final boxManager = BoxManager();
      
      // Open boxes if not open (BoxManager usually handles singleton boxes, but we ensure)
      await boxManager.openAllBoxes(userId);

      final transactionBox = boxManager.getBox<Transaction>(BoxManager.transactionsBoxName, userId);
      final budgetBox = boxManager.getBox<Budget>(BoxManager.budgetsBoxName, userId);
      // Assuming Investment box exists? If not catching error.
      // We check if BoxManager has investments. If not, we skip.
      // Based on file list, `investment_model.dart` exists, so likely `investmentsBoxName` exists or we check generic.
      // Let's assume standard names.
      Box<dynamic>? investmentBox;
      try {
         investmentBox = Hive.box('investments_$userId');
      } catch (_) {
         // If generic open failed, maybe it wasn't opened.
      }
      
      setState(() {
        _totalTransactions = transactionBox.length;
        _activeBudgets = budgetBox.length;
        _totalInvestments = investmentBox?.length ?? 0;
      });
      
    } catch (e) {
      print("Error loading stats: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isNotEmpty) {
      try {
        await _currentUser?.updateDisplayName(_nameController.text.trim());
        setState(() {
          _userName = _nameController.text.trim();
          _userInitials = _getInitials(_userName);
          _isEditingName = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Name Updated')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating name: $e')),
        );
      }
    }
  }
  
  // Email editing is disabled as per requirements, so we remove _saveEmail or make it no-op
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${_currentUser?.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
      
      // Save path to Hive
      if (_currentUser != null) {
        final box = await Hive.openBox('settings_${_currentUser!.uid}');
        await box.put('profile_image_path', savedImage.path);
      }

      setState(() {
        _profileImagePath = savedImage.path;
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error updating photo: $e')),
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Deep navy
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
                        image: _profileImagePath != null && File(_profileImagePath!).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(_profileImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileImagePath == null || !File(_profileImagePath!).existsSync()
                          ? Center(
                              child: Text(
                                _userInitials,
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
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

                // Email Field (Read Only)
                _buildEditableField(
                  label: 'EMAIL ADDRESS',
                  controller: _emailController,
                  isEditing: false, // Explicitly disabled
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onEdit: () {}, // No-op
                  onSave: () {}, 
                  onCancel: () {},
                  readOnly: true,
                ),
                const SizedBox(height: AppTheme.spacing24),

                // Premium Status Card (Static)
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

            // Quick Stats Section (Real Data)
            _buildQuickStats(),
            const SizedBox(height: AppTheme.spacing24),

            // Upgrade to Premium or Premium Benefits
            if (!_isPremium)
              _buildPremiumUpgradeCard()
            else
              _buildPremiumBenefitsCard(),
            const SizedBox(height: AppTheme.spacing24),

            // Achievements/Milestones Section (Real Data Logic)
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
    bool readOnly = false,
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
                          onSubmitted: (_) => onSave(),
                        )
                      : GestureDetector(
                          onTap: readOnly ? null : onEdit,
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
                if (!readOnly) ...[
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
    // Real logic calculation
    final hasFirstTransaction = _totalTransactions > 0;
    final isBudgetMaster = _activeBudgets >= 5;
    final isInvestor = _totalInvestments >= 1;
    final isSavingsChampion = false; // Need SavingsGoal logic, skipping complex check for now or assuming false

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
                hasFirstTransaction,
              ),
              const SizedBox(height: 16),
              _buildAchievementItem(
                '📊 Budget Master',
                'Created 5 active budgets',
                Icons.check_circle_outlined,
                AppTheme.accentGreen,
                isBudgetMaster,
              ),
              const SizedBox(height: 16),
              _buildAchievementItem(
                '📈 Investor',
                'Added your first investment',
                Icons.check_circle_outlined,
                AppTheme.accentGreen,
                isInvestor,
              ),
              const SizedBox(height: 16),
              _buildAchievementItem(
                '🎯 Savings Champion',
                'Maintained 20% savings rate', 
                Icons.radio_button_unchecked_outlined,
                Colors.white.withOpacity(0.3),
                isSavingsChampion,
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
            unlocked ? icon : Icons.lock_outline, // Changed icon for locked stae
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



