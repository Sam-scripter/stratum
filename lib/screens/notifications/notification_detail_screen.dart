import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/notification/notification_model.dart';
import '../../models/box_manager.dart';
import '../../models/transaction/transaction_model.dart';
import '../transactions/transaction_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onMarkAsRead;

  const NotificationDetailScreen({
    Key? key,
    required this.notification,
    this.onMarkAsRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mark as read when viewing detail
    if (!notification.isRead && onMarkAsRead != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onMarkAsRead!();
      });
    }

    final isTransaction = notification.transactionId != null;
    final typeName = isTransaction ? 'Transaction' : 'System';
    final icon = isTransaction ? Icons.account_balance_wallet : Icons.info_outline;
    
    // Determine color
    Color iconColor = AppTheme.textGray;
    if (isTransaction) {
       iconColor = AppTheme.accentBlue;
       if (notification.body.contains('+')) {
         iconColor = AppTheme.accentGreen;
       }
    } else {
      iconColor = AppTheme.primaryGold;
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(
          'Notification',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              notification.isRead
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_unread_outlined,
              color: AppTheme.primaryGold,
            ),
            onPressed: () {
              if (!notification.isRead && onMarkAsRead != null) {
                onMarkAsRead!();
                Navigator.of(context).pop();
              }
            },
            tooltip: notification.isRead ? 'Mark as unread' : 'Mark as read',
          ),
          /*
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: AppTheme.primaryGold),
            color: AppTheme.surfaceGray,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppTheme.accentRed, size: 20),
                    const SizedBox(width: AppTheme.spacing12),
                    Text(
                      'Delete',
                      style: GoogleFonts.poppins(
                        color: AppTheme.accentRed,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
          */
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Header Card
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              hasGlow: !notification.isRead,
              child: Column(
                children: [
                  // Icon with badge
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              iconColor.withOpacity(0.3),
                              iconColor.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: iconColor.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 40,
                        ),
                      ),
                      if (!notification.isRead)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacing4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentRed,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryDark,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.circle,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing20),

                  // Title
                  Text(
                    notification.title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radius20),
                      border: Border.all(
                        color: iconColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      typeName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Notification Content
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    notification.body,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.primaryLight,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Notification Details
            PremiumCard(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Date & Time',
                    _formatDateTime(notification.timestamp),
                    Icons.access_time,
                  ),
                  const Divider(color: AppTheme.borderGray, height: AppTheme.spacing24),
                  _buildDetailRow(
                    'Type',
                    typeName,
                    icon,
                    color: iconColor,
                  ),
                  const Divider(color: AppTheme.borderGray, height: AppTheme.spacing24),
                  _buildDetailRow(
                    'Status',
                    notification.isRead ? 'Read' : 'Unread',
                    notification.isRead
                        ? Icons.mark_email_read
                        : Icons.mark_email_unread,
                    color: notification.isRead
                        ? AppTheme.accentGreen
                        : AppTheme.primaryGold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Action Button (if available)
            if (isTransaction)
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
                  onPressed: () => _handleTransactionNavigation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Details',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Icon(
                        Icons.arrow_forward,
                        color: AppTheme.primaryDark,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  void _handleTransactionNavigation(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || notification.transactionId == null) return;
    
    // Using simple box retrieval - assumes boxes are open
    try {
      final transactionsBox = BoxManager().getBox<Transaction>(
        BoxManager.transactionsBoxName,
        userId,
      );
      final transaction = transactionsBox.get(notification.transactionId);

      if (transaction != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(transaction: transaction),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
             content: Text('Transaction details not found'),
             backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } catch (e) {
      print('Error navigating: $e');
    }
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing8),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.primaryGold).withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radius8),
            border: Border.all(
              color: (color ?? AppTheme.primaryGold).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color ?? AppTheme.primaryGold,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppTheme.primaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Other dates
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

