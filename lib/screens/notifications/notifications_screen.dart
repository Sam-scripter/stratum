import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import 'notification_detail_screen.dart';

enum NotificationType {
  transaction,
  budget,
  investment,
  reminder,
  insight,
  system,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
  final String? actionLabel;
  final VoidCallback? onTap;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionLabel,
    this.onTap,
  });

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.transaction:
        return Icons.account_balance_wallet;
      case NotificationType.budget:
        return Icons.pie_chart;
      case NotificationType.investment:
        return Icons.trending_up;
      case NotificationType.reminder:
        return Icons.notifications;
      case NotificationType.insight:
        return Icons.lightbulb;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.transaction:
        return AppTheme.accentBlue;
      case NotificationType.budget:
        return AppTheme.accentRed;
      case NotificationType.investment:
        return AppTheme.accentGreen;
      case NotificationType.reminder:
        return AppTheme.primaryGold;
      case NotificationType.insight:
        return AppTheme.accentOrange;
      case NotificationType.system:
        return AppTheme.textGray;
    }
  }

  String get typeName {
    switch (type) {
      case NotificationType.transaction:
        return 'Transaction';
      case NotificationType.budget:
        return 'Budget';
      case NotificationType.investment:
        return 'Investment';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.insight:
        return 'AI Insight';
      case NotificationType.system:
        return 'System';
    }
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    // Simulate loading notifications
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _notifications = _generateMockNotifications();
        _isLoading = false;
      });
    });
  }

  List<NotificationItem> _generateMockNotifications() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: '1',
        title: 'Budget Alert',
        message: 'You\'ve spent 85% of your Food & Dining budget for this month.',
        type: NotificationType.budget,
        timestamp: now.subtract(const Duration(minutes: 5)),
        isRead: false,
        actionLabel: 'View Budget',
      ),
      NotificationItem(
        id: '2',
        title: 'Transaction Added',
        message: 'KES 2,500 expense added for Grocery Shopping',
        type: NotificationType.transaction,
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
        actionLabel: 'View Transaction',
      ),
      NotificationItem(
        id: '3',
        title: 'AI Insight',
        message: 'Your savings rate has improved by 12% this month. Keep it up!',
        type: NotificationType.insight,
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: true,
        actionLabel: 'View Insights',
      ),
      NotificationItem(
        id: '4',
        title: 'Investment Update',
        message: 'Your CIC Money Market Fund has gained 2.5% this week.',
        type: NotificationType.investment,
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: true,
        actionLabel: 'View Investment',
      ),
      NotificationItem(
        id: '5',
        title: 'Payment Reminder',
        message: 'Don\'t forget: Rent payment due in 2 days',
        type: NotificationType.reminder,
        timestamp: now.subtract(const Duration(hours: 12)),
        isRead: false,
        actionLabel: 'Set Reminder',
      ),
      NotificationItem(
        id: '6',
        title: 'Welcome to Stratum',
        message: 'Thank you for joining! Start tracking your finances today.',
        type: NotificationType.system,
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationItem(
        id: '7',
        title: 'Expense Alert',
        message: 'Large transaction detected: KES 15,000 at Electronics Store',
        type: NotificationType.transaction,
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
        actionLabel: 'Review Transaction',
      ),
      NotificationItem(
        id: '8',
        title: 'Budget Goal Reached',
        message: 'Congratulations! You\'ve successfully stayed within your Transport budget.',
        type: NotificationType.budget,
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
        actionLabel: 'View Details',
      ),
    ];
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        backgroundColor: AppTheme.accentRed,
      ),
    );
  }

  void _markAsRead(String id) {
    setState(() {
      final notification = _notifications.firstWhere((n) => n.id == id);
      notification.isRead = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            if (_unreadCount > 0) ...[
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
                  '$_unreadCount',
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
          if (_unreadCount > 0)
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
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

  Widget _buildNotificationCard(NotificationItem notification) {
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationDetailScreen(
                  notification: notification,
                  onMarkAsRead: () => _markAsRead(notification.id),
                ),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread indicator + Icon Container
              Stack(
                children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      decoration: BoxDecoration(
                      color: notification.iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                      border: Border.all(
                        color: notification.iconColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      notification.icon,
                      color: notification.iconColor,
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
                              color: notification.isRead
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Text(
                          notification.formattedTime,
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
                      notification.message,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textGray,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Type badge (only show, no action button on list)
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
                        notification.typeName,
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
}

