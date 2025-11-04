// This file contains examples of enhanced widgets
// These demonstrate the UI improvements proposed in UI_IMPROVEMENTS_PROPOSAL.md
// These are reference implementations - integrate as needed

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Enhanced Premium Card with multi-layer shadows and glow effects
class EnhancedPremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool isSelected;
  final bool hasGlow;

  const EnhancedPremiumCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacing16),
    this.onTap,
    this.backgroundColor,
    this.isSelected = false,
    this.hasGlow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.surfaceGray,
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          // Multi-layer shadow system for premium depth
          boxShadow: [
            // Soft gold glow (outer)
            if (hasGlow || isSelected)
              BoxShadow(
                color: AppTheme.primaryGold.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            // Deep shadow for depth
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: -3,
              offset: const Offset(0, 6),
            ),
            // Sharp shadow for definition
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
          // Subtle gold border when selected
          border: isSelected
              ? Border.all(
                  color: AppTheme.primaryGold.withOpacity(0.5),
                  width: 1.5,
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// Enhanced Net Worth Card with animated gradient and trend indicator
class EnhancedNetWorthCard extends StatefulWidget {
  final String netWorth;
  final String balance;
  final String savingsRate;
  final double? trendPercentage;

  const EnhancedNetWorthCard({
    Key? key,
    required this.netWorth,
    required this.balance,
    required this.savingsRate,
    this.trendPercentage,
  }) : super(key: key);

  @override
  State<EnhancedNetWorthCard> createState() => _EnhancedNetWorthCardState();
}

class _EnhancedNetWorthCardState extends State<EnhancedNetWorthCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedPremiumCard(
      hasGlow: true,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Net Worth',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textGray,
                  letterSpacing: 0.5,
                ),
              ),
              // Eye icon to toggle balance visibility
              GestureDetector(
                onTap: () {
                  setState(() => _isBalanceVisible = !_isBalanceVisible);
                },
                child: Icon(
                  _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.primaryGold.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          // Main net worth display with currency formatting
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KES ',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.primaryGold.withOpacity(0.6),
                  letterSpacing: 1,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _isBalanceVisible
                      ? widget.netWorth.replaceAll('KES ', '')
                      : '•••••••',
                  key: ValueKey(_isBalanceVisible),
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGold,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
          // Trend indicator
          if (widget.trendPercentage != null) ...[
            const SizedBox(height: AppTheme.spacing8),
            Row(
              children: [
                Icon(
                  widget.trendPercentage! >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: widget.trendPercentage! >= 0
                      ? AppTheme.accentGreen
                      : AppTheme.accentRed,
                  size: 16,
                ),
                const SizedBox(width: AppTheme.spacing4),
                Text(
                  '${widget.trendPercentage! >= 0 ? '+' : ''}${widget.trendPercentage!.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.trendPercentage! >= 0
                        ? AppTheme.accentGreen
                        : AppTheme.accentRed,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  'this month',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTheme.spacing20),
          // Sub-metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  'This Month',
                  widget.balance,
                  widget.balance.contains('-')
                      ? AppTheme.accentRed
                      : AppTheme.accentGreen,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _buildMetricBox(
                  'Savings Rate',
                  widget.savingsRate,
                  AppTheme.accentGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: AppTheme.borderGray.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced Button with gradient, shimmer, and animations
class EnhancedGoldButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const EnhancedGoldButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  State<EnhancedGoldButton> createState() => _EnhancedGoldButtonState();
}

class _EnhancedGoldButtonState extends State<EnhancedGoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryDark,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: AppTheme.primaryDark,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced Bottom Navigation Bar with curved top and active indicator
class EnhancedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const EnhancedBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius20),
          topRight: Radius.circular(AppTheme.radius20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius20),
          topRight: Radius.circular(AppTheme.radius20),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: onTap,
          selectedItemColor: AppTheme.primaryGold,
          unselectedItemColor: AppTheme.textGray,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          items: [
            _buildNavItem(Icons.home_rounded, 'Home'),
            _buildNavItem(Icons.trending_up_rounded, 'Investments'),
            _buildNavItem(Icons.receipt_long_rounded, 'Transactions'),
            _buildNavItem(Icons.settings_rounded, 'Settings'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radius8),
        ),
        child: Icon(icon),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryGold.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppTheme.radius8),
          border: Border.all(
            color: AppTheme.primaryGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryGold,
        ),
      ),
      label: label,
    );
  }
}

/// Enhanced Transaction List Item with swipe actions and expandable details
class EnhancedTransactionListItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String category;
  final String amount;
  final String date;
  final bool isIncome;
  final VoidCallback? onTap;

  const EnhancedTransactionListItem({
    Key? key,
    required this.emoji,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: AppTheme.borderGray.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                // Category icon with gradient background
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isIncome
                          ? [
                              AppTheme.accentGreen.withOpacity(0.2),
                              AppTheme.accentGreen.withOpacity(0.1),
                            ]
                          : [
                              AppTheme.accentRed.withOpacity(0.2),
                              AppTheme.accentRed.withOpacity(0.1),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                    border: Border.all(
                      color: (isIncome
                              ? AppTheme.accentGreen
                              : AppTheme.accentRed)
                          .withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                // Transaction details
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing4,
                              vertical: AppTheme.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryDark.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius8,
                              ),
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textGray,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Text(
                            date,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textGray.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount with enhanced styling
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isIncome
                            ? AppTheme.accentGreen
                            : AppTheme.primaryLight,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (isIncome)
                      Container(
                        margin: const EdgeInsets.only(top: AppTheme.spacing4),
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing4,
                          vertical: AppTheme.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radius8,
                          ),
                        ),
                        child: Text(
                          'Income',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Example: Enhanced loading skeleton
class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoader({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceGray,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radius8),
      ),
    );
  }
}

