import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// Premium Card Widget with Enhanced Multi-Layer Shadows
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final bool hasGlow;
  final bool isSelected;

  const PremiumCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacing16),
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.hasGlow = false,
    this.isSelected = false,
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
            // Soft gold glow (outer) - when enabled
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

// Premium Amount Display Widget
class AmountDisplay extends StatelessWidget {
  final String label;
  final String amount;
  final Color? amountColor;
  final TextAlign textAlign;

  const AmountDisplay({
    Key? key,
    required this.label,
    required this.amount,
    this.amountColor,
    this.textAlign = TextAlign.left,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppTheme.textGray,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: amountColor ?? AppTheme.primaryGold,
            letterSpacing: 0.3,
          ),
          textAlign: textAlign,
        ),
      ],
    );
  }
}

// Transaction List Item Widget
class TransactionListItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String category;
  final String amount;
  final String date;
  final bool isIncome;
  final VoidCallback? onTap;

  const TransactionListItem({
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.borderGray.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            // Category Emoji
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceGray,
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        date,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Flexible(
              child: Text(
                amount,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isIncome ? AppTheme.accentGreen : AppTheme.primaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AI Insight Card Widget with Enhanced Premium Feel
class AIInsightCard extends StatefulWidget {
  final String title;
  final String insight;
  final String actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;

  const AIInsightCard({
    Key? key,
    required this.title,
    required this.insight,
    required this.actionLabel,
    this.onAction,
    this.accentColor,
  }) : super(key: key);

  @override
  State<AIInsightCard> createState() => _AIInsightCardState();
}

class _AIInsightCardState extends State<AIInsightCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: PremiumCard(
        backgroundColor: AppTheme.surfaceGray,
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('✨', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              widget.insight,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.primaryLight,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            SizedBox(
              width: double.infinity,
              child: _EnhancedButton(
                label: widget.actionLabel,
                onPressed: widget.onAction,
                accentColor: widget.accentColor ?? AppTheme.accentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Button with Animations
class _EnhancedButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? accentColor;

  const _EnhancedButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.accentColor,
  }) : super(key: key);

  @override
  State<_EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<_EnhancedButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
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
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.accentColor ?? AppTheme.accentBlue,
                (widget.accentColor ?? AppTheme.accentBlue).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            boxShadow: [
              BoxShadow(
                color: (widget.accentColor ?? AppTheme.accentBlue).withOpacity(0.4),
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
            child: Text(
              widget.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Financial Health Score Widget with Enhanced Premium Feel
class FinancialHealthScore extends StatefulWidget {
  final double score; // 0-100
  final String description;

  const FinancialHealthScore({
    Key? key,
    required this.score,
    required this.description,
  }) : super(key: key);

  @override
  State<FinancialHealthScore> createState() => _FinancialHealthScoreState();
}

class _FinancialHealthScoreState extends State<FinancialHealthScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  Color get scoreColor {
    if (widget.score >= 80) return AppTheme.accentGreen;
    if (widget.score >= 60) return AppTheme.accentOrange;
    return AppTheme.accentRed;
  }

  String get scoreLabel {
    if (widget.score >= 80) return 'Excellent';
    if (widget.score >= 60) return 'Good';
    return 'Needs Improvement';
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Health Score',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        final animatedScore = (widget.score * _progressAnimation.value).clamp(0, 100);
                        return Text(
                          '${animatedScore.toStringAsFixed(0)}/100',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                            letterSpacing: -0.5,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: AppTheme.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radius20),
                        border: Border.all(
                          color: scoreColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        scoreLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle with glow
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.borderGray.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scoreColor.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    // Progress circle
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: _progressAnimation.value,
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                            backgroundColor: Colors.transparent,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            widget.description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.textGray,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// Category Chip Widget
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold : AppTheme.surfaceGray,
          borderRadius: BorderRadius.circular(AppTheme.radius8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGold : AppTheme.borderGray,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.primaryDark : AppTheme.primaryLight,
          ),
        ),
      ),
    );
  }
}
