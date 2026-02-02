import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/subscription/subscription_service.dart';
import '../../models/subscription/user_subscription_model.dart';

class PlansScreen extends StatefulWidget {
  final bool isFromOnboarding;
  
  const PlansScreen({Key? key, this.isFromOnboarding = false}) : super(key: key);

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85); // Peeking cards
  int _currentIndex = 1; // Default to Middle (Plus)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isFromOnboarding 
            ? null 
            : IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Text(
                  "Choose Your Plan",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Unlock the full power of AI finance tracking.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Carousel
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: [
                _buildPlanCard(
                  title: "Stratum Core",
                  price: "Free",
                  features: ["Unlimited Transactions", "Basic Budgeting", "Dashboard Overview"],
                  isPopular: false,
                  tier: SubscriptionTier.core,
                  color: Colors.grey,
                ),
                _buildPlanCard(
                  title: "Stratum Plus",
                  price: "KES 499/mo",
                  features: ["Everything in Core", "AI Daily Insights", "Financial Health Score", "Investment Portfolio", "No Ads"],
                  isPopular: true,
                  tier: SubscriptionTier.plus,
                  color: const Color(0xFF4361EE),
                ),
                _buildPlanCard(
                  title: "Stratum Elite",
                  price: "KES 899/mo",
                  features: ["Everything in Plus", "Unlimited Atlas Chat", "Deep RAG Context", "Priority Support"],
                  isPopular: false,
                  tier: SubscriptionTier.elite,
                  color: const Color(0xFFD4AF37), // Gold
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentIndex == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index ? Colors.white : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 24),
          
          // Footer Actions
          if (widget.isFromOnboarding)
            TextButton(
              onPressed: () {
                // Determine logic for "Continue with Free"
                // Probably navigate to MainScreen
                 Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              child: Text(
                "Continue with Free",
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
           Padding(
             padding: const EdgeInsets.only(bottom: 24.0, top: 12),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 _buildFooterLink("Terms"),
                 const SizedBox(width: 16),
                 _buildFooterLink("Privacy"),
                 const SizedBox(width: 16),
                 _buildFooterLink("Restore"),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isPopular,
    required SubscriptionTier tier,
    required Color color,
  }) {
    final isSelected = true; // Since it's a carousel, center item is focused visually by PageView default scaling if we used it, but here we just show full cards.
    // For simplicity, we just render the card.

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151E2E),
        borderRadius: BorderRadius.circular(24),
        border: isPopular ? Border.all(color: color, width: 2) : Border.all(color: Colors.white10),
        boxShadow: isPopular 
          ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]
          : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "MOST POPULAR",
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: features.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          features[index],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _handlePurchase(tier);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                tier == SubscriptionTier.core ? "Current Plan" : "Upgrade", // Dynamic check needed
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFooterLink(String text) {
    return InkWell(
      onTap: () {},
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white54,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _handlePurchase(SubscriptionTier tier) async {
    // Mock Purchase Flow
    final service = context.read<SubscriptionService>();
    
    // Show Loading
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator())
    );
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    await service.upgradeTo(tier);
    
    if (mounted) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Welcome to Stratum ${tier.name.toUpperCase()}!")),
      );
      if (widget.isFromOnboarding) {
         Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
         Navigator.pop(context); // Close plans screen
      }
    }
  }
}
