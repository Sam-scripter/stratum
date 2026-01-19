import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/box_manager.dart';
import '../../models/notification/notification_model.dart';
import '../../models/transaction/transaction_model.dart';
import 'notification_detail_screen.dart';
import '../transactions/transaction_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Box<NotificationModel>? _notificationsBox;
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      await BoxManager().openAllBoxes(_userId!);
      if (mounted) {
        setState(() {
          _notificationsBox = BoxManager().getBox<NotificationModel>(
            BoxManager.notificationsBoxName,
            _userId!,
          );
          _isLoading = false;
        });
      }
    }
  }

  void _markAllAsRead() {
    if (_notificationsBox == null) return;
    for (var key in _notificationsBox!.keys) {
      final notification = _notificationsBox!.get(key);
      if (notification != null && !notification.isRead) {
        // Create copy with isRead = true
        final updated = notification.copyWith(isRead: true);
        _notificationsBox!.put(key, updated);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _deleteNotification(String id) {
    if (_notificationsBox == null) return;
    _notificationsBox!.delete(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        backgroundColor: AppTheme.accentRed,
      ),
    );
  }

  void _markAsRead(NotificationModel notification) {
    if (_notificationsBox == null) return;
    final updated = notification.copyWith(isRead: true);
    _notificationsBox!.put(notification.id, updated);
  }

  void _handleNotificationTap(NotificationModel notification) async {
    _markAsRead(notification);

    if (notification.transactionId != null && _userId != null) {
      try {
        final transactionsBox = BoxManager().getBox<Transaction>(
          BoxManager.transactionsBoxName,
          _userId!,
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
        print('Error navigating to transaction: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
          ),
        ),
      );
    }

    if (_notificationsBox == null) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(child: Text('Error loading notifications')),
      );
    }

    return ValueListenableBuilder<Box<NotificationModel>>(
      valueListenable: _notificationsBox!.listenable(),
      builder: (context, box, _) {
        final notifications = box.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          appBar: AppBar(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: AppTheme.spacing8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing8,
                      vertical: AppTheme.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed,
                      borderRadius: BorderRadius.circular(AppTheme.radius20),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: AppTheme.primaryDark,
            elevation: 0,
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: _markAllAsRead,
                  child: Text(
                    'Mark all as read',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          body: notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceGray,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryGold.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            'No Notifications',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'You\'re all caught up!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    // Determine icon and color based on content presence
    // Default to info/system
    IconData icon = Icons.info_outline;
    Color color = AppTheme.textGray;
    String typeName = 'System';

    if (notification.transactionId != null) {
      icon = Icons.account_balance_wallet;
      color = AppTheme.accentBlue;
      typeName = 'Transaction';
      
      // Simple heuristic for income vs expense based on body text
      if (notification.body.contains('+')) {
         color = AppTheme.accentGreen;
      }
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
        decoration: BoxDecoration(
          color: AppTheme.accentRed,
          borderRadius: BorderRadius.circular(AppTheme.radius16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacing20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) => _deleteNotification(notification.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
        child: PremiumCard(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          hasGlow: !notification.isRead,
          backgroundColor: notification.isRead
              ? AppTheme.surfaceGray
              : AppTheme.surfaceGray.withOpacity(0.7),
          onTap: () => _handleNotificationTap(notification),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread indicator + Icon Container
              Stack(
                children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  if (!notification.isRead)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.accentRed,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppTheme.spacing12),
              // Content - Compact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppTheme.primaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Text(
                          _formatTime(notification.timestamp),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    // Message
                    Text(
                      notification.body,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textGray,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Type badge
                    const SizedBox(height: AppTheme.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8,
                        vertical: AppTheme.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGray.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppTheme.radius8),
                      ),
                      child: Text(
                        typeName,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd').format(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }
}

