import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // NEW
import '../../repositories/financial_repository.dart';
import '../../models/investment/investment_model.dart';
import '../../theme/app_theme.dart';
import 'add_investment_screen.dart';
import 'discover_screen.dart';
import '../../services/subscription/subscription_service.dart'; // NEW
import '../monetization/plans_screen.dart'; // NEW

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        appBar: AppBar(
          title: Text('Investments', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
          backgroundColor: const Color(0xFF1A2332),
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppTheme.primaryGold,
            labelColor: AppTheme.primaryGold,
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "My Portfolio"),
              Tab(text: "Discover"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPortfolioTab(context),
            const DiscoverScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioTab(BuildContext context) {
    final canAccess = context.watch<SubscriptionService>().canAccessInvestments;
    
    if (!canAccess) {
      return _buildLockedState(context);
    }

    return Consumer<FinancialRepository>(
      builder: (context, repository, _) {
        final investments = repository.investments;
        final totalValue = investments.fold<double>(0.0, (sum, i) => sum + i.currentValue);
        final totalCost = investments.fold<double>(0.0, (sum, i) => sum + i.principalAmount);
        final profit = totalValue - totalCost;
        final profitPercent = totalCost == 0 ? 0 : (profit / totalCost) * 100;
        final isProfit = profit >= 0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddInvestmentScreen()));
            },
            backgroundColor: AppTheme.primaryGold,
            icon: Icon(Icons.add, color: Colors.black),
            label: Text('Add Asset', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          body: investments.isEmpty 
          ? _buildEmptyState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                     // Chart
                     if (investments.isNotEmpty) _buildAllocationChart(investments),
                     SizedBox(height: 24),

                     // Summary Card
                     Container(
                       padding: EdgeInsets.all(20),
                       decoration: BoxDecoration(
                         gradient: AppTheme.cardGradient,
                         borderRadius: BorderRadius.circular(20),
                         boxShadow: [
                           BoxShadow(
                             color: AppTheme.primaryGold.withOpacity(0.1),
                             blurRadius: 10,
                             offset: Offset(0, 4),
                           )
                         ]
                       ),
                       child: Column(
                         children: [
                           Text('Total Portfolio Value', 
                             style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                           SizedBox(height: 8),
                           Text('KES ${NumberFormat("#,##0").format(totalValue)}',
                             style: GoogleFonts.poppins(
                               color: Colors.white, 
                               fontSize: 32, 
                               fontWeight: FontWeight.bold
                             )),
                           SizedBox(height: 12),
                           Container(
                             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                             decoration: BoxDecoration(
                               color: isProfit ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(20),
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Icon(
                                   isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                                   color: isProfit ? Colors.greenAccent : Colors.redAccent,
                                   size: 16,
                                 ),
                                 SizedBox(width: 4),
                                 Text(
                                   '${profit >= 0 ? "+" : ""}${NumberFormat("#,##0").format(profit)} (${profitPercent.toStringAsFixed(1)}%)',
                                   style: GoogleFonts.poppins(
                                     color: isProfit ? Colors.greenAccent : Colors.redAccent,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                               ],
                             ),
                           )
                         ],
                       ),
                     ),
                     
                     SizedBox(height: 24),
                     
                     // Asset List
                     ListView.separated(
                       shrinkWrap: true,
                       physics: NeverScrollableScrollPhysics(),
                       itemCount: investments.length,
                       separatorBuilder: (_,__) => SizedBox(height: 12),
                       itemBuilder: (context, index) {
                         return _buildAssetCard(context, investments[index], repository);
                       },
                     )
                  ],
                ),
              ),
            ),
        );
      },
    );
  }

  Widget _buildAllocationChart(List<InvestmentModel> investments) {
    final Map<InvestmentType, double> totals = {};
    double totalValue = 0;
    
    for (var i in investments) {
      totals[i.type] = (totals[i.type] ?? 0) + i.currentValue;
      totalValue += i.currentValue;
    }

    final List<PieChartSectionData> sections = totals.entries.map((entry) {
      final percentage = (entry.value / totalValue) * 100;
      return PieChartSectionData(
        color: _getTypeColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: GoogleFonts.poppins(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: Colors.white
        ),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context, InvestmentModel asset, FinancialRepository repo) {
    final profit = asset.profitOrLoss;
    final isProfit = profit >= 0;
    
    return Dismissible(
      key: Key(asset.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: AppTheme.accentRed,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
            title: Text("Delete Asset?"),
            content: Text("Are you sure you want to remove ${asset.name}?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
            ],
          )
        );
      },
      onDismissed: (_) {
         repo.investmentService.deleteInvestment(asset.id);
      },
      child: GestureDetector(
        onTap: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => AddInvestmentScreen(existingInvestment: asset)));
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2332), // backgroundLight
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(asset.type).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getTypeIcon(asset.type), color: _getTypeColor(asset.type)),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    Text(asset.type.name.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('KES ${NumberFormat("#,##0").format(asset.currentValue)}', 
                     style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    '${profit >= 0 ? "+" : ""}${NumberFormat("#,##0.0").format(asset.profitOrLossPercentage)}%',
                    style: GoogleFonts.poppins(
                      color: isProfit ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 80, color: Colors.white24),
          SizedBox(height: 16),
          Text("No Investments Yet", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
          SizedBox(height: 8),
          Text("Start building your portfolio today!", style: GoogleFonts.poppins(color: Colors.white54)),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddInvestmentScreen()));
            },
            icon: Icon(Icons.add),
            label: Text("Add First Asset"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.black,
            ),
          )
        ],
      ),
    );
  }

  Color _getTypeColor(InvestmentType type) {
    switch(type) {
      case InvestmentType.stock: return Colors.blueAccent;
      case InvestmentType.crypto: return Colors.orangeAccent;
      case InvestmentType.mmf: return Colors.greenAccent;
      case InvestmentType.property: return Colors.purpleAccent;
      case InvestmentType.bond: return Colors.tealAccent;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(InvestmentType type) {
    switch(type) {
      case InvestmentType.stock: return Icons.ssid_chart;
      case InvestmentType.crypto: return Icons.currency_bitcoin;
      case InvestmentType.mmf: return Icons.account_balance;
      case InvestmentType.property: return Icons.home_work;
      case InvestmentType.bond: return Icons.receipt_long;
      default: return Icons.category;
    }
  }

  Widget _buildLockedState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_rounded, size: 60, color: AppTheme.primaryGold),
          ),
          const SizedBox(height: 24),
          Text(
            "Portfolio Tracking is Locked",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Upgrade to Stratum Plus to track your stocks, crypto, and assets manually or via SMS.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              "View Plans",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
