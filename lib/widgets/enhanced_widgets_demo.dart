import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'enhanced_widgets_examples.dart';

/// Demo screen to preview enhanced widgets before implementation
class EnhancedWidgetsDemo extends StatefulWidget {
  const EnhancedWidgetsDemo({Key? key}) : super(key: key);

  @override
  State<EnhancedWidgetsDemo> createState() => _EnhancedWidgetsDemoState();
}

class _EnhancedWidgetsDemoState extends State<EnhancedWidgetsDemo> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Enhanced UI Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'UI Enhancements Preview',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Compare the enhanced widgets with the current design',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.textGray,
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),

            // 1. Enhanced Net Worth Card
            _buildSection(
              '1. Enhanced Net Worth Card',
              'Multi-layer shadows, gold glow, privacy toggle, trend indicator',
              const EnhancedNetWorthCard(
                netWorth: 'KES 325,480.00',
                balance: 'KES 125,480.00',
                savingsRate: '42.5%',
                trendPercentage: 12.5,
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // 2. Enhanced Premium Cards
            _buildSection(
              '2. Enhanced Premium Cards',
              'Multi-layer shadow system with optional gold glow',
              Column(
                children: [
                  EnhancedPremiumCard(
                    hasGlow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Card with Gold Glow',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          'This card has the enhanced shadow system with a gold glow effect.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  EnhancedPremiumCard(
                    isSelected: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Card',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          'This card is selected with a gold border.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // 3. Enhanced Buttons
            _buildSection(
              '3. Enhanced Gold Buttons',
              'Gradient background, multi-layer shadows, press animations',
              Column(
                children: [
                  EnhancedGoldButton(
                    label: 'Primary Action',
                    icon: Icons.add_circle_outline,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Button pressed!')),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  EnhancedGoldButton(
                    label: 'Loading State',
                    isLoading: true,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  EnhancedGoldButton(
                    label: 'Simple Button',
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // 4. Enhanced Transaction Items
            _buildSection(
              '4. Enhanced Transaction Items',
              'Gradient backgrounds, better typography, income indicators',
              Column(
                children: [
                  EnhancedTransactionListItem(
                    emoji: '💼',
                    title: 'Monthly Salary',
                    category: 'Salary',
                    amount: '+KES 85,000.00',
                    date: 'Nov 15, 2025',
                    isIncome: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction tapped')),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  EnhancedTransactionListItem(
                    emoji: '🍽️',
                    title: 'Restaurant - The Boma',
                    category: 'Dining',
                    amount: '-KES 2,500.00',
                    date: 'Nov 14, 2025',
                    isIncome: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  EnhancedTransactionListItem(
                    emoji: '🛒',
                    title: 'Naivas Supermarket',
                    category: 'Groceries',
                    amount: '-KES 5,200.00',
                    date: 'Nov 13, 2025',
                    isIncome: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // 5. Enhanced Bottom Navigation
            _buildSection(
              '5. Enhanced Bottom Navigation',
              'Curved top border, gold active indicators, smooth animations',
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGray,
                  borderRadius: BorderRadius.circular(AppTheme.radius16),
                ),
                child: EnhancedBottomNavBar(
                  currentIndex: _navIndex,
                  onTap: (index) {
                    setState(() => _navIndex = index);
                  },
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // 6. Loading Skeletons
            _buildSection(
              '6. Loading Skeletons',
              'Placeholder widgets for loading states',
              Column(
                children: [
                  const ShimmerLoader(
                    width: double.infinity,
                    height: 120,
                    borderRadius: BorderRadius.all(Radius.circular(AppTheme.radius16)),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Row(
                    children: [
                      Expanded(
                        child: ShimmerLoader(
                          width: double.infinity,
                          height: 80,
                          borderRadius: BorderRadius.circular(AppTheme.radius12),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: ShimmerLoader(
                          width: double.infinity,
                          height: 80,
                          borderRadius: BorderRadius.circular(AppTheme.radius12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing32),

            // Comparison Note
            EnhancedPremiumCard(
              backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.accentBlue,
                        size: 24,
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Text(
                        'Preview Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    'This is a preview of the enhanced UI components. Compare these with the current design in the home screen.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textGray,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    'If you like these enhancements, we can integrate them into the main app.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppTheme.textGray,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        content,
      ],
    );
  }
}

