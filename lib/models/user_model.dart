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
  final int iqScore;
  final String rank;
  final int solvedCount;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.name,
    required this.searchName,
    required this.school,
    required this.avatarUrl,
    this.photoUrl = '',
    this.grade = '',
    this.stream = '', // Default empty
    this.age = 0,
    this.gender = '',
    required this.iqScore,
    required this.rank,
    required this.solvedCount,
    this.fcmToken,
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
      stream: map['stream'] ?? '', // Load stream
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      iqScore: map['iqScore'] ?? 0,
      rank: map['rank'] ?? 'Novice',
      solvedCount: map['solvedCount'] ?? 0,
      fcmToken: map['fcmToken'],
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
      'stream': stream, // Save stream
      'age': age,
      'gender': gender,
      'iqScore': iqScore,
      'rank': rank,
      'solvedCount': solvedCount,
      'fcmToken': fcmToken,
    };
  }
}
