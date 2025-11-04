import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class MPesaIntegrationScreen extends StatefulWidget {
  const MPesaIntegrationScreen({Key? key}) : super(key: key);

  @override
  State<MPesaIntegrationScreen> createState() => _MPesaIntegrationScreenState();
}

class _MPesaIntegrationScreenState extends State<MPesaIntegrationScreen> {
  bool _isConnected = false;
  final _phoneController = TextEditingController(text: '254712345678');
  bool _autoSyncEnabled = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleConnect() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isConnected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('M-Pesa account connected successfully!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    });
  }

  void _handleDisconnect() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceGray,
        title: Text(
          'Disconnect M-Pesa?',
          style: GoogleFonts.poppins(
            color: AppTheme.primaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to disconnect your M-Pesa account? This will stop automatic transaction syncing.',
          style: GoogleFonts.poppins(
            color: AppTheme.textGray,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppTheme.textGray,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isConnected = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('M-Pesa account disconnected'),
                  backgroundColor: AppTheme.accentRed,
                ),
              );
            },
            child: Text(
              'Disconnect',
              style: GoogleFonts.poppins(
                color: AppTheme.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'M-Pesa Integration',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radius12),
                        ),
                        child: const Icon(
                          Icons.sms_outlined,
                          color: AppTheme.primaryDark,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing16),
                      Expanded(
                        child: Text(
                          'Sync M-Pesa Transactions',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Text(
                    'Connect your M-Pesa account to automatically import and categorize your transactions.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            if (_isConnected) ...[
              // Connected State
              PremiumCard(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                hasGlow: true,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accentGreen.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: AppTheme.accentGreen,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'M-Pesa Connected',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      '+254 712 345 678',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    _buildSwitchTile(
                      'Auto Sync Transactions',
                      'Automatically import new transactions',
                      _autoSyncEnabled,
                      (value) => setState(() => _autoSyncEnabled = value),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _handleDisconnect,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                          side: const BorderSide(color: AppTheme.accentRed, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radius16),
                          ),
                        ),
                        child: Text(
                          'Disconnect',
                          style: GoogleFonts.poppins(
                            color: AppTheme.accentRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Connection Form
              Text(
                'Phone Number',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              PremiumCard(
                padding: EdgeInsets.zero,
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryLight,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: 'M-Pesa Phone Number',
                    labelStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppTheme.primaryGold,
                    ),
                    hintText: '254712345678',
                    hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textGray.withOpacity(0.5),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              PremiumCard(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryGold, size: 20),
                        const SizedBox(width: AppTheme.spacing12),
                        Expanded(
                          child: Text(
                            'You\'ll receive an SMS confirmation to verify your phone number',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing32),
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
                  onPressed: _isLoading ? null : _handleConnect,
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
                          'Connect M-Pesa',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryGold,
        ),
      ],
    );
  }
}

