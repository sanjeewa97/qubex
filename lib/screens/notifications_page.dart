import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'post_details_page.dart';

import '../widgets/loading_widget.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final FirebaseService firebaseService = FirebaseService();
    final user = authService.currentUser;

    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: firebaseService.getNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("No notifications yet", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () async {
                  // Mark as read
                  if (!notification.isRead) {
                    await firebaseService.markNotificationAsRead(user.uid, notification.id);
                  }
                  
                  // Navigate to post
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailsPage(postId: notification.postId),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead ? Colors.transparent : AppTheme.primary.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondary.withOpacity(0.1),
          child: const Icon(Icons.comment, color: AppTheme.secondary),
        ),
        title: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: notification.fromUserName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: " ${notification.message}"),
            ],
          ),
        ),
        subtitle: Text(
          _formatTimestamp(notification.timestamp),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: notification.isRead 
          ? null 
          : Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        onTap: onTap,
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else {
      return "${difference.inDays}d ago";
    }
  }
}
