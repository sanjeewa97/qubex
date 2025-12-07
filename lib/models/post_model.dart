import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String school;
  final String grade;
  final String content;
  final String type; // 'Question', 'Achievement', 'Poll', 'Quiz'
  final int likes;
  final List<String> likedBy;
  final int comments;
  final String? acceptedCommentId;
  final DateTime timestamp;
  final bool isAchievement;
  final String? imageUrl; // New field
  final bool isEdited;
  
  // Poll/Quiz Fields
  final List<String> pollOptions;
  final Map<String, int> pollVotes; // UserId -> OptionIndex
  final int? correctOptionIndex; // Null for Poll, Index for Quiz

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl = '',
    required this.school,
    required this.grade,
    required this.content,
    required this.type,
    required this.likes,
    this.likedBy = const [], 
    required this.comments,
    this.acceptedCommentId,
    required this.timestamp,
    this.isAchievement = false,
    this.imageUrl,
    this.isEdited = false,
    this.pollOptions = const [],
    this.pollVotes = const {},
    this.correctOptionIndex,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      authorPhotoUrl: map['authorPhotoUrl'] ?? '',
      school: map['school'] ?? '',
      grade: map['grade'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'Question',
      likes: map['likes'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      comments: map['comments'] ?? 0,
      acceptedCommentId: map['acceptedCommentId'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAchievement: map['isAchievement'] ?? false,
      imageUrl: map['imageUrl'],
      isEdited: map['isEdited'] ?? false,
      pollOptions: List<String>.from(map['pollOptions'] ?? []),
      pollVotes: Map<String, int>.from(map['pollVotes'] ?? {}),
      correctOptionIndex: map['correctOptionIndex'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'school': school,
      'grade': grade,
      'content': content,
      'type': type,
      'likes': likes,
      'likedBy': likedBy,
      'comments': comments,
      'acceptedCommentId': acceptedCommentId,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAchievement': isAchievement,
      'imageUrl': imageUrl,
      'isEdited': isEdited,
      'pollOptions': pollOptions,
      'pollVotes': pollVotes,
      'correctOptionIndex': correctOptionIndex,
    };
  }
}
