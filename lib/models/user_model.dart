class UserModel {
  final String id;
  final String name;
  final String school;
  final String avatarUrl; // Keeping this for backward compatibility or mapping to photoUrl
  final String photoUrl;
  final String grade;
  final int age;
  final String gender;
  final int iqScore;
  final String rank;
  final int solvedCount;

  UserModel({
    required this.id,
    required this.name,
    required this.school,
    required this.avatarUrl,
    this.photoUrl = '',
    this.grade = '',
    this.age = 0,
    this.gender = '',
    required this.iqScore,
    required this.rank,
    required this.solvedCount,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      school: map['school'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      photoUrl: map['photoUrl'] ?? map['avatarUrl'] ?? '',
      grade: map['grade'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      iqScore: map['iqScore'] ?? 0,
      rank: map['rank'] ?? 'Novice',
      solvedCount: map['solvedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'school': school,
      'avatarUrl': avatarUrl,
      'photoUrl': photoUrl,
      'grade': grade,
      'age': age,
      'gender': gender,
      'iqScore': iqScore,
      'rank': rank,
      'solvedCount': solvedCount,
    };
  }
}
