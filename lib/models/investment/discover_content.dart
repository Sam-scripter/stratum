import 'package:flutter/material.dart';

enum DiscoverType { learn, platform }

class DiscoverItem {
  final String id;
  final String title;
  final String subtitle;
  final String description; // Full detail text
  final String? iconUrl; // Or use IconData locally
  final IconData? iconData;
  final Color color;
  final DiscoverType type;
  final String? actionUrl; // External link
  final String? actionLabel; // "Visit Website", "Download App"
  final List<String> keyFeatures;

  const DiscoverItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    this.iconData,
    this.iconUrl,
    required this.color,
    required this.type,
    this.actionUrl,
    this.actionLabel,
    this.keyFeatures = const [],
  });

  // Unique prompt for Atlas to explain this topic
  String get atlasPrompt => "Tell me more about $title. $subtitle. Key features: ${keyFeatures.join(', ')}.";
}

class DiscoverData {
  static const List<DiscoverItem> education = [
    DiscoverItem(
      id: 'mmf_101',
      title: 'Money Market Funds (MMF)',
      subtitle: 'Low risk, daily interest up to 15%.',
      description: 
        "A Money Market Fund (MMF) is a type of mutual fund that invests in high-quality, short-term debt instruments, cash, and cash equivalents.\n\n"
        "Why invest in MMFs?\n"
        "1. Safety: They are considered very low risk.\n"
        "2. Liquidity: You can withdraw your money within 24-48 hours.\n"
        "3. Compound Interest: Interest is earned daily and compounded monthly.",
      iconData: Icons.account_balance,
      color: Colors.greenAccent,
      type: DiscoverType.learn,
      keyFeatures: [
        "Low Risk", "High Liquidity", "Compound Interest", "Regulated by CMA"
      ],
    ),
    DiscoverItem(
      id: 'stocks_bonds',
      title: 'Stocks vs Bonds',
      subtitle: 'Ownership vs Lending.',
      description: 
        "Stocks represent ownership in a company. When you buy a stock, you become a shareholder.\n\n"
        "Bonds are loans you give to a company or government. They pay you interest (coupons) over a fixed period.\n\n"
        "Key Differences:\n"
        "- Risk: Stocks are higher risk, Bonds are lower risk.\n"
        "- Returns: Stocks offer capital gains + dividends. Bonds offer fixed interest.",
      iconData: Icons.compare_arrows,
      color: Colors.blueAccent,
      type: DiscoverType.learn,
      keyFeatures: [
        "Equity (Stocks)", "Debt (Bonds)", "Dividends", "Fixed Income"
      ]
    ),
     DiscoverItem(
      id: 'crypto_basics',
      title: 'Crypto Basics',
      subtitle: 'High risk, high reward digital assets.',
      description: 
        "Cryptocurrency is digital money that uses blockchain technology. Bitcoin and Ethereum are the most common.\n\n"
        "It is highly volatile, meaning prices can go up or down very quickly.",
      iconData: Icons.currency_bitcoin,
      color: Colors.orangeAccent,
      type: DiscoverType.learn,
      keyFeatures: [
        "Blockchain", "Decentralized", "High Volatility", "24/7 Trading"
      ]
    ),
  ];

  static const List<DiscoverItem> platforms = [
    DiscoverItem(
      id: 'mali',
      title: 'Mali (Safaricom)',
      subtitle: 'Invest via M-Pesa. 10% annual interest.',
      description: 
        "Mali is a unit trust investment service regulated by the CMA and powered by Safaricom.\n\n"
        "It allows M-PESA customers to invest as little as KSh 100 and earn daily interest.\n"
        "Access it via *334# or the M-PESA App.",
      iconData: Icons.phone_android,
      color: Color(0xFFD4AF37), // Gold
      type: DiscoverType.platform,
      actionUrl: "https://www.safaricom.co.ke/personal/m-pesa/mali",
      actionLabel: "Visit Safaricom Mali",
      keyFeatures: [
        "Min Investment: KSh 100", "Instant Withdrawal", "Daily Interest", "Powered by M-PESA"
      ]
    ),
    DiscoverItem(
      id: 'cic_mmf',
      title: 'CIC Money Market',
      subtitle: 'Consistent returns. Regulated Unit Trust.',
      description: 
        "CIC Asset Management offers one of the largest Money Market Funds in Kenya.\n\n"
        "It focuses on capital preservation while offering high returns. Ideal for emergency funds and short-term goals.",
      iconData: Icons.security,
      color: Colors.tealAccent,
      type: DiscoverType.platform,
      actionUrl: "https://cic.co.ke/personal/financial-planning/unit-trusts/",
      actionLabel: "Open CIC Account",
      keyFeatures: [
        "Min Investment: KSh 5,000", "Monthly Statements", "Capital Preservation", "Top Tier Manager"
      ]
    ),
    DiscoverItem(
      id: 'hisa',
      title: 'Hisa App',
      subtitle: 'Buy US Stocks (Apple, Tesla) & KE Stocks.',
      description: 
        "Hisa allows you to invest in fractional US shares like Apple, Tesla, and Microsoft directly from M-Pesa.\n\n"
        "It also supports the Nairobi Securities Exchange (NSE).",
      iconData: Icons.show_chart,
      color: Colors.pinkAccent,
      type: DiscoverType.platform,
      actionUrl: "https://hisa.co/",
      actionLabel: "Download Hisa",
      keyFeatures: [
        "US Stocks", "NSE Stocks", "Fractional Shares", "User Friendly"
      ]
    ),
     DiscoverItem(
      id: 'binance',
      title: 'Binance',
      subtitle: 'Leading Crypto Exchange.',
      description: 
        "Binance is the world's largest crypto exchange by volume.\n\n"
        "Buy Bitcoin, Ethereum, and stablecoins using M-Pesa P2P.",
      iconData: Icons.currency_bitcoin,
      color: Colors.yellowAccent,
      type: DiscoverType.platform,
      actionUrl: "https://www.binance.com",
      actionLabel: "Go to Binance",
      keyFeatures: [
        "Crypto P2P", "Staking", "Low Fees", "Global Access"
      ]
    ),
  ];
}
