import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// Displays real-time booking notifications received via Redis Pub/Sub.
/// Shows a notification bell with badge count and opens a bottom sheet.
class NotificationPanel extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final VoidCallback? onClear;
  final Function(int)? onMarkRead;

  const NotificationPanel({
    super.key,
    required this.notifications,
    required this.unreadCount,
    this.onClear,
    this.onMarkRead,
  });

  static IconData _iconForType(String type) {
    switch (type) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'accepted':
        return Icons.thumb_up_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'expired':
        return Icons.timer_off_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color _colorForType(String type) {
    switch (type) {
      case 'confirmed':
        return AppTheme.success;
      case 'accepted':
        return AppTheme.accepted;
      case 'rejected':
        return AppTheme.error;
      case 'expired':
        return AppTheme.warning;
      case 'completed':
        return AppTheme.success;
      default:
        return AppTheme.primary;
    }
  }

  /// Show the notification bottom sheet
  static void show(
    BuildContext context, {
    required List<Map<String, dynamic>> notifications,
    required int unreadCount,
    VoidCallback? onClear,
    Function(int)? onMarkRead,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NotificationPanel(
        notifications: notifications,
        unreadCount: unreadCount,
        onClear: onClear,
        onMarkRead: onMarkRead,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Notifications',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Real-time updates via Redis',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notifications.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      onClear?.call();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Notification list
          if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_off_rounded,
                    color: AppTheme.textMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You\'ll see real-time booking updates here',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 72,
                  color: AppTheme.textMuted.withValues(alpha: 0.15),
                ),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final type = notif['type'] ?? '';
                  final isRead = notif['isRead'] == true;
                  final timestamp = notif['timestamp'] ?? '';
                  
                  String timeAgo = '';
                  try {
                    final dt = DateTime.parse(timestamp);
                    final diff = DateTime.now().difference(dt);
                    if (diff.inMinutes < 1) {
                      timeAgo = 'Just now';
                    } else if (diff.inMinutes < 60) {
                      timeAgo = '${diff.inMinutes}m ago';
                    } else if (diff.inHours < 24) {
                      timeAgo = '${diff.inHours}h ago';
                    } else {
                      timeAgo = '${diff.inDays}d ago';
                    }
                  } catch (_) {}

                  return InkWell(
                    onTap: () => onMarkRead?.call(index),
                    child: Container(
                      color: isRead
                          ? Colors.transparent
                          : AppTheme.primary.withValues(alpha: 0.04),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _colorForType(type).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _iconForType(type),
                              color: _colorForType(type),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif['title'] ?? '',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  notif['message'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (timeAgo.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    timeAgo,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
