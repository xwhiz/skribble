import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerModel {
  final String uid;
  final String displayName;
  final int score;
  final Timestamp joinedAt;

  PlayerModel({
    required this.uid,
    required this.displayName,
    required this.score,
    required this.joinedAt,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? 'Player',
      score: json['score'] ?? 0,
      joinedAt: json['joinedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'score': score,
      'joinedAt': joinedAt,
    };
  }
}
