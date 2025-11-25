class UserModel {
  final String id;
  final String name;
  final String school;
  final String avatarUrl;
  final int iqScore;
  final String rank;
  final int solvedCount;

  UserModel({
    required this.id,
    required this.name,
    required this.school,
    required this.avatarUrl,
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
      'iqScore': iqScore,
      'rank': rank,
      'solvedCount': solvedCount,
    };
  }
}
