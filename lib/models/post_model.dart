import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String school;
  final String content;
  final String type; // 'Question' or 'Achievement'
  final int likes;
  final int comments;
  final DateTime timestamp;
  final bool isAchievement;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.school,
    required this.content,
    required this.type,
    required this.likes,
    required this.comments,
    required this.timestamp,
    this.isAchievement = false,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      school: map['school'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'Question',
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAchievement: map['isAchievement'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'school': school,
      'content': content,
      'type': type,
      'likes': likes,
      'comments': comments,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAchievement': isAchievement,
    };
  }
}
