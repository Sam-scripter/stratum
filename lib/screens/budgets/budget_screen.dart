import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/budget/budget_model.dart';
import '../../models/savings/savings_goal_model.dart';
import '../../services/finances/budget_service.dart';
import '../../theme/app_theme.dart';

class BudgetScreen extends StatefulWidget {
  final String? userId; // Now optional
  const BudgetScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with SingleTickerProviderStateMixin {
  BudgetService? _budgetService;
  late TabController _tabController;
  String? _userId;
  
  // Data State
  double _freeCash = 0.0;
  List<Budget> _budgets = [];
  List<SavingsGoal> _savingsGoals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeService();
  }

  Future<void> _initializeService() async {
    // Get userId from parameter or Firebase
    _userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    _budgetService = BudgetService(_userId!);
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_budgetService == null) return;
    setState(() => _isLoading = true);
    try {
      final budgets = await _budgetService!.getAllBudgets();
      final goals = await _budgetService!.getAllSavingsGoals();
      final freeCash = await _budgetService!.getFreeCash();
      
      setState(() {
        _budgets = budgets;
        _savingsGoals = goals;
        _freeCash = freeCash;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading budget data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: Text('Smart Finance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGold,
          labelColor: AppTheme.primaryGold,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'Budgets'),
            Tab(text: 'Savings Goals'),
          ],
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildBudgetsTab(),
              _buildSavingsTab(),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryGold,
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildBudgetsTab() {
    if (_budgets.isEmpty) {
      return Center(
        child: Text("No budgets set yet", style: GoogleFonts.poppins(color: Colors.white54)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _budgets.length,
      itemBuilder: (context, index) {
        final budget = _budgets[index];
        final progress = budget.progress;
        final color = progress > 1.0 ? AppTheme.accentRed : (progress > 0.8 ? Colors.orange : AppTheme.accentGreen);
        
        return Card(
          color: const Color(0xFF1A2332),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(budget.categoryName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                    Text('KES ${budget.spentAmount.toStringAsFixed(0)} / ${budget.limitAmount.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white70)),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress > 1 ? 1 : progress,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                if (progress > 1.0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Exceeded by KES ${(budget.spentAmount - budget.limitAmount).toStringAsFixed(0)}', style: GoogleFonts.poppins(color: AppTheme.accentRed, fontSize: 12)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavingsTab() {
     if (_savingsGoals.isEmpty) {
      return Center(
        child: Text("No savings goals yet", style: GoogleFonts.poppins(color: Colors.white54)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
      itemCount: _savingsGoals.length,
      itemBuilder: (context, index) {
        final goal = _savingsGoals[index];
        return Card(
          color: const Color(0xFF1A2332),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Icon(IconData(goal.iconCodePoint, fontFamily: 'MaterialIcons'), size: 40, color: Color(goal.colorValue)),
                 SizedBox(height: 8),
                 Text(goal.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                 SizedBox(height: 4),
                 Text('${(goal.progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.poppins(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 24)),
                 SizedBox(height: 4),
                 Text('KES ${goal.savedAmount.toStringAsFixed(0)} / ${goal.targetAmount.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog() {
    // Show simple dialog to choose what to add
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: Text("Add New", style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.speed, color: AppTheme.accentGreen),
              title: Text("Budget", style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddBudgetDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.savings, color: AppTheme.primaryGold),
              title: Text("Savings Goal", style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddSavingsDialog();
              },
            ),
          ],
        ),
      )
    );
  }

  void _showAddBudgetDialog() {
     // Implementation for adding budget (Simplified for Phase 7 MVP)
     final categoryController = TextEditingController();
     final amountController = TextEditingController();
     
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: const Color(0xFF1A2332),
         title: Text("New Budget", style: GoogleFonts.poppins(color: Colors.white)),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             TextField(
               controller: categoryController,
               style: TextStyle(color: Colors.white),
               decoration: InputDecoration(labelText: "Category (e.g. Dining)", labelStyle: TextStyle(color: Colors.white54)),
             ),
             TextField(
               controller: amountController,
               style: TextStyle(color: Colors.white),
               keyboardType: TextInputType.number,
               decoration: InputDecoration(labelText: "Limit Amount", labelStyle: TextStyle(color: Colors.white54)),
             ),
           ],
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
           ElevatedButton(
             onPressed: () async {
               if (categoryController.text.isNotEmpty && amountController.text.isNotEmpty) {
                 await _budgetService!.createOrUpdateBudget(
                   categoryController.text, 
                   double.parse(amountController.text)
                 );
                 Navigator.pop(ctx);
                 _loadData();
               }
             }, 
             style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
             child: Text("Save", style: TextStyle(color: Colors.black))
           ),
         ],
       )
     );
  }

  void _showAddSavingsDialog() {
     // Implementation for adding savings goal (Simplified for Phase 7 MVP)
     final nameController = TextEditingController();
     final targetController = TextEditingController();
     
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: const Color(0xFF1A2332),
         title: Text("New Savings Goal", style: GoogleFonts.poppins(color: Colors.white)),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             TextField(
               controller: nameController,
               style: TextStyle(color: Colors.white),
               decoration: InputDecoration(labelText: "Goal Name", labelStyle: TextStyle(color: Colors.white54)),
             ),
             TextField(
               controller: targetController,
               style: TextStyle(color: Colors.white),
               keyboardType: TextInputType.number,
               decoration: InputDecoration(labelText: "Target Amount", labelStyle: TextStyle(color: Colors.white54)),
             ),
           ],
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
           ElevatedButton(
             onPressed: () async {
               if (nameController.text.isNotEmpty && targetController.text.isNotEmpty) {
                 await _budgetService!.createSavingsGoal(
                   nameController.text, 
                   double.parse(targetController.text),
                   Colors.blue.value,
                   Icons.savings.codePoint
                 );
                 Navigator.pop(ctx);
                 _loadData();
               }
             }, 
             style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
             child: Text("Save", style: TextStyle(color: Colors.black))
           ),
         ],
       )
     );
  }
}
