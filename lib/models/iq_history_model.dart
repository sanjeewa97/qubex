import 'package:cloud_firestore/cloud_firestore.dart';

class IQHistoryModel {
  final DateTime date;
  final double score;

  IQHistoryModel({required this.date, required this.score});

  factory IQHistoryModel.fromMap(Map<String, dynamic> map) {
    return IQHistoryModel(
      date: (map['date'] as Timestamp).toDate(),
      score: (map['score'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'score': score,
    };
  }
}
