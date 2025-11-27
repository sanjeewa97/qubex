import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String postId;
  final String authorName;
  final String authorId;
  final String authorPhotoUrl;
  final String content;
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorName,
    this.authorId = '',
    this.authorPhotoUrl = '',
    required this.content,
    required this.timestamp,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      postId: map['postId'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      authorId: map['authorId'] ?? '',
      authorPhotoUrl: map['authorPhotoUrl'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorName': authorName,
      'authorId': authorId,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
