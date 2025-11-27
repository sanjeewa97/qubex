import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type; // 'comment', 'like', etc.
  final String fromUserId;
  final String fromUserName;
  final String postId;
  final String message;
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.fromUserName,
    required this.postId,
    required this.message,
    required this.isRead,
    required this.timestamp,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      type: map['type'] ?? 'unknown',
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? 'Someone',
      postId: map['postId'] ?? '',
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'postId': postId,
      'message': message,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
