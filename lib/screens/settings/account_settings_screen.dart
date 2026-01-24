import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: _user?.displayName ?? '');
    _emailController = TextEditingController(text: _user?.email ?? '');
    _phoneController = TextEditingController(text: _user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_user != null) {
           if (_nameController.text.trim() != _user!.displayName) {
             await _user!.updateDisplayName(_nameController.text.trim());
             // Reload to ensure local cache updates
             await _user!.reload(); 
             _user = FirebaseAuth.instance.currentUser;
           }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account settings updated successfully!'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          Navigator.pop(context); // Go back after save
        }
      } catch (e) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating account: $e'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
         }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(backgroundColor: AppTheme.primaryDark),
        body: const Center(child: Text("User not logged in", style: TextStyle(color: Colors.white))),
      );
    }
    
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Account Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryLight),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Information Card
              PremiumCard(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    _buildInfoRow(
                      'User ID',
                      _user!.uid.substring(0, 8).toUpperCase(),
                      Icons.badge_outlined,
                    ),
                    const Divider(color: AppTheme.borderGray, height: AppTheme.spacing24),
                    _buildInfoRow(
                      'Member Since',
                      _formatDate(_user!.metadata.creationTime),
                      Icons.calendar_today_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Edit Information
              Text(
                'Personal Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Full Name Field (Editable)
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppTheme.primaryGold,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Email Field (Read Only)
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  enabled: false,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight.withOpacity(0.7),
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email (Read-only)',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppTheme.textGray, // Greyed out
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Phone Field (Read Only if empty, editable if we wanted, but let's keep it read only for now to match scope)
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _phoneController,
                  readOnly: true, // Making read-only for now unless we implement phone update flow
                  enabled: false,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight.withOpacity(0.7),
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppTheme.textGray,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing32),

              // Save Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDark),
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radius8),
            border: Border.all(
              color: AppTheme.primaryGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: AppTheme.primaryGold, size: 20),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

