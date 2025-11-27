import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String title;
  final String subject;
  final String authorName;
  final String school;
  final String grade;
  final String fileUrl;
  final String size;
  final DateTime timestamp;

  NoteModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.authorName,
    required this.school,
    required this.grade,
    required this.fileUrl,
    required this.size,
    required this.timestamp,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteModel(
      id: id,
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      school: map['school'] ?? '',
      grade: map['grade'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      size: map['size'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'authorName': authorName,
      'school': school,
      'grade': grade,
      'fileUrl': fileUrl,
      'size': size,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
