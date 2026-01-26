import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/investment/investment_model.dart';
import '../../services/finances/investment_service.dart';
import '../../theme/app_theme.dart';

class AddInvestmentScreen extends StatefulWidget {
  final InvestmentModel? existingInvestment;

  const AddInvestmentScreen({Key? key, this.existingInvestment}) : super(key: key);

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _principalController;
  late TextEditingController _valueController;
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  
  InvestmentType _selectedType = InvestmentType.stock;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final inv = widget.existingInvestment;
    _nameController = TextEditingController(text: inv?.name ?? '');
    _principalController = TextEditingController(text: inv?.principalAmount.toString() ?? '');
    _valueController = TextEditingController(text: inv?.currentValue.toString() ?? '');
    _quantityController = TextEditingController(text: inv?.quantity.toString() ?? '');
    _notesController = TextEditingController(text: inv?.notes ?? '');
    if (inv != null) {
      _selectedType = inv.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _principalController.dispose();
    _valueController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final service = InvestmentService(userId);
      
      final name = _nameController.text.trim();
      final principal = double.tryParse(_principalController.text) ?? 0.0;
      final value = double.tryParse(_valueController.text) ?? 0.0;
      final quantity = double.tryParse(_quantityController.text) ?? 0.0;
      final notes = _notesController.text.trim();

      if (widget.existingInvestment != null) {
        await service.updateInvestment(
          widget.existingInvestment!.id,
          name: name,
          type: _selectedType,
          principalAmount: principal,
          currentValue: value,
          quantity: quantity,
          notes: notes,
        );
      } else {
        await service.addInvestment(
          name: name,
          type: _selectedType,
          principalAmount: principal,
          currentValue: value,
          quantity: quantity,
          notes: notes,
        );
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingInvestment != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Asset' : 'Add Asset', 
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1A2332),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLabel('Asset Name'),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: _inputDecoration('e.g. Safaricom Shares'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              _buildLabel('Asset Type'),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InvestmentType>(
                    value: _selectedType,
                    dropdownColor: Color(0xFF1A2332),
                    icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryGold),
                    style: GoogleFonts.poppins(color: Colors.white),
                    items: InvestmentType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Invested (Cost)'),
                        TextFormField(
                          controller: _principalController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: _inputDecoration('0.00', prefix: 'KES '),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Current Value'),
                        TextFormField(
                          controller: _valueController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: _inputDecoration('0.00', prefix: 'KES '),
                           validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildLabel('Quantity (Optional)'),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: _inputDecoration('e.g. 500 Shares'),
              ),
              
              const SizedBox(height: 16),
              _buildLabel('Notes'),
              TextFormField(
                controller: _notesController,
                style: GoogleFonts.poppins(color: Colors.white),
                maxLines: 3,
                decoration: _inputDecoration('Optional notes...'),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'Update Asset' : 'Add Asset', 
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
    );
  }
  
  InputDecoration _inputDecoration(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixStyle: GoogleFonts.poppins(color: AppTheme.primaryGold),
      hintStyle: GoogleFonts.poppins(color: Colors.white24),
      filled: true,
      fillColor: const Color(0xFF1A2332),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
