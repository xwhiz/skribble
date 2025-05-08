class PlayerModel {
  final String userId;
  final String? username;
  final int? score;
  final bool? isDrawing;

  PlayerModel({
    required this.userId,
    this.username,
    this.score,
    this.isDrawing,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      userId: json['userId'] ?? '',
      username: json['username'],
      score: json['score'],
      isDrawing: json['isDrawing'] ?? false,
    );
  }
}