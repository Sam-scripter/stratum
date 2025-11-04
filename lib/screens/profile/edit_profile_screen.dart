import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialInitials;

  const EditProfileScreen({
    Key? key,
    required this.initialName,
    required this.initialEmail,
    required this.initialInitials,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String _selectedInitials;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _selectedInitials = widget.initialInitials;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateInitials() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        setState(() {
          _selectedInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
        });
      } else if (parts.length == 1) {
        setState(() {
          _selectedInitials = parts[0][0].toUpperCase();
        });
      }
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      _updateInitials();
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'initials': _selectedInitials,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Preview
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _selectedInitials,
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacing8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppTheme.primaryDark,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Full Name Field
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
                    hintText: 'Enter your full name',
                    hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray.withOpacity(0.5),
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
                  onChanged: (_) => _updateInitials(),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Email Field
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppTheme.primaryGold,
                    ),
                    hintText: 'Enter your email',
                    hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray.withOpacity(0.5),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
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
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius16),
                    ),
                  ),
                  child: Text(
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
}

