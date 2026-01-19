import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../models/account/account_model.dart';
import '../../models/box_manager.dart';
import '../../models/transaction/transaction_model.dart';
import '../../services/sms_reader/sms_reader_service.dart';
import '../../widgets/custom_widgets.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({Key? key}) : super(key: key);

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Fields
  String _accountName = '';
  AccountType _selectedType = AccountType.Bank;
  bool _isAutomated = true; // Sync with SMS by default
  String _smsSender = '';
  double _initialBalance = 0.0;
  
  bool _isScanning = false;
  String _scanStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Add Account',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isScanning 
          ? _buildScanningView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Account Details'),
                    const SizedBox(height: AppTheme.spacing16),
                    
                    // Account Name
                    TextFormField(
                      decoration: _inputDecoration('Account Name', 'e.g. Equity Bank'),
                      style: GoogleFonts.poppins(color: Colors.white),
                      validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                      onSaved: (value) => _accountName = value!,
                    ),
                    const SizedBox(height: AppTheme.spacing20),

                    // Account Type Dropdown
                    DropdownButtonFormField<AccountType>(
                      value: _selectedType,
                      dropdownColor: AppTheme.surfaceGray,
                      decoration: _inputDecoration('Account Type', ''),
                      style: GoogleFonts.poppins(color: Colors.white),
                      items: AccountType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_formatAccountType(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                          // Auto-disable sync for Cash/Liability if preferred
                          if (_selectedType == AccountType.Cash) {
                            _isAutomated = false;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    
                    // Initial Balance
                    TextFormField(
                      decoration: _inputDecoration('Current Balance', '0.00'),
                      style: GoogleFonts.poppins(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                         if (value == null || value.isEmpty) return null;
                         if (double.tryParse(value) == null) return 'Invalid number';
                         return null;
                      },
                      onSaved: (value) {
                        if (value != null && value.isNotEmpty) {
                          _initialBalance = double.parse(value);
                        }
                      },
                    ),
                    
                    const SizedBox(height: AppTheme.spacing32),
                    _buildSectionTitle('Automation'),
                    const SizedBox(height: AppTheme.spacing16),
                    
                    // Sync Toggle
                    SwitchListTile(
                      title: Text(
                        'Sync with SMS',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Automatically track transactions from SMS',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textGray,
                          fontSize: 12,
                        ),
                      ),
                      value: _isAutomated,
                      onChanged: (value) {
                        setState(() {
                          _isAutomated = value;
                        });
                      },
                      activeColor: AppTheme.primaryGold,
                      contentPadding: EdgeInsets.zero,
                    ),

                    if (_isAutomated) ...[
                      const SizedBox(height: AppTheme.spacing16),
                      TextFormField(
                        decoration: _inputDecoration(
                          'SMS Sender Name', 
                          'e.g. EQUITY, KCB, MPESA'
                        ).copyWith(
                          helperText: 'Enter the exact sender name as it appears in your SMS inbox.',
                          helperStyle: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 11),
                        ),
                        style: GoogleFonts.poppins(color: Colors.white),
                        validator: (value) => 
                          _isAutomated && (value == null || value.isEmpty) 
                              ? 'Required for SMS sync' 
                              : null,
                        onSaved: (value) => _smsSender = value!,
                      ),
                    ],

                    const SizedBox(height: AppTheme.spacing32),

                    // Auto-Discovery Button
                    Center(
                      child: TextButton.icon(
                        onPressed: _runAutoDiscovery,
                        icon: const Icon(Icons.travel_explore, color: AppTheme.primaryGold),
                        label: Text(
                          'Scan Inbox for New Accounts',
                          style: GoogleFonts.poppins(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.0,
                      child: ElevatedButton(
                        onPressed: _saveAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radius12),
                          ),
                        ),
                        child: Text(
                          _isAutomated ? 'Save & Scan SMS' : 'Save Account',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScanningView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            'Scanning for $_smsSender Messages...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            _scanStatus,
            style: GoogleFonts.poppins(
              color: AppTheme.textGray,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        color: AppTheme.textGray,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.poppins(color: AppTheme.textGray),
      hintStyle: GoogleFonts.poppins(color: Colors.white24),
      filled: true,
      fillColor: AppTheme.surfaceGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing16,
      ),
    );
  }

  String _formatAccountType(AccountType type) {
    return type.toString().split('.').last.toUpperCase();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final boxManager = BoxManager();
      await boxManager.openAllBoxes(userId);
      final accountsBox = boxManager.getBox<Account>(
        BoxManager.accountsBoxName, 
        userId
      );

      // Create new account
      final newAccount = Account(
        id: const Uuid().v4(),
        name: _accountName,
        balance: _initialBalance,
        type: _selectedType,
        lastUpdated: DateTime.now(),
        senderAddress: _isAutomated ? _smsSender : '',
        isAutomated: _isAutomated,
      );

      accountsBox.put(newAccount.id, newAccount);

      if (_isAutomated) {
        // Trigger automated scan
        await _performInitialScan(userId);
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving account: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  Future<void> _runAutoDiscovery() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isScanning = true;
      _scanStatus = 'Scanning for bank accounts...';
    });

    final smsService = SmsReaderService(userId);
    final hasPermission = await smsService.requestSmsPermission();

    if (!hasPermission) {
      if (mounted) {
        setState(() => _isScanning = false);
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS permission denied')),
        );
      }
      return;
    }

    try {
      final newAccounts = await smsService.discoverAccounts();
      
      if (mounted) {
        setState(() => _isScanning = false);
        
        if (newAccounts.isEmpty) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surfaceGray,
              title: Text('No New Accounts Found', style: GoogleFonts.poppins(color: Colors.white)),
              content: Text(
                'We scanned your recent messages but couldn\'t identify any new bank accounts (KCB, Equity, NVBA, etc.).',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                )
              ],
            ),
          );
        } else {
          // Show results
          final names = newAccounts.map((a) => a.name).join(', ');
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surfaceGray,
              title: Text('Accounts Found! 🚀', style: GoogleFonts.poppins(color: Colors.white)),
              content: Text(
                'We found and added the following accounts:\n\n$names',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // Go back to list
                  },
                  child: const Text('Great!'),
                )
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    }
  }

  Future<void> _performInitialScan(String userId) async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Initializing...';
    });

    final smsService = SmsReaderService(userId);
    bool hasPermission = await smsService.requestSmsPermission();

    if (!hasPermission) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS permission denied')),
        );
        Navigator.pop(context); // Close anyway, account is saved but not synced
      }
      return;
    }

    // Start scanning
    // Listen to the stream
    smsService.scanAllMessages().listen(
      (progress) {
        if (mounted) {
          setState(() {
            _scanStatus = progress.status;
          });
        }
      },
      onDone: () {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan complete & Account added!'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          Navigator.pop(context);
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _isScanning = false);
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error scanning: $e')),
          );
          Navigator.pop(context);
        }
      },
    );
  }
}
