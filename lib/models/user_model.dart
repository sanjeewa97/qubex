import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String searchName; // For case-insensitive search
  final String school;
  final String avatarUrl; // Keeping this for backward compatibility or mapping to photoUrl
  final String photoUrl;
  final String grade;
  final String stream; // New field for A/L stream
  final int age;
  final String gender;
  final double iqScore; // Changed to double
  final String rank;
  final int solvedCount;
  final String? fcmToken;
  final int streakCount;
  final DateTime? lastActiveDate;

  UserModel({
    required this.id,
    required this.name,
    required this.searchName,
    required this.school,
    required this.avatarUrl,
    this.photoUrl = '',
    this.grade = '',
    this.stream = '',
    this.age = 0,
    this.gender = '',
    this.iqScore = 0.0,
    this.rank = 'Novice',
    this.solvedCount = 0,
    this.fcmToken,
    this.streakCount = 0,
    this.lastActiveDate,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      searchName: map['searchName'] ?? (map['name'] ?? '').toLowerCase(),
      school: map['school'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      photoUrl: map['photoUrl'] ?? map['avatarUrl'] ?? '',
      grade: map['grade'] ?? '',
      stream: map['stream'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      iqScore: (map['iqScore'] ?? 0).toDouble(),
      rank: map['rank'] ?? 'Novice',
      solvedCount: map['solvedCount'] ?? 0,
      fcmToken: map['fcmToken'],
      streakCount: map['streakCount'] ?? 0,
      lastActiveDate: map['lastActiveDate'] is Timestamp 
          ? (map['lastActiveDate'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'searchName': searchName,
      'school': school,
      'avatarUrl': avatarUrl,
      'photoUrl': photoUrl,
      'grade': grade,
      'stream': stream,
      'age': age,
      'gender': gender,
      'iqScore': iqScore,
      'rank': rank,
      'solvedCount': solvedCount,
      'fcmToken': fcmToken,
      'streakCount': streakCount,
      'lastActiveDate': lastActiveDate,
    };
  }
}
