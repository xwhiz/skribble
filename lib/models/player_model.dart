import 'message_model.dart'; // make sure to import your Message model

class PlayerModel {
  final String userId;
  final String? username;
  final int? score;
  final bool? isDrawing;
  final List<Message>? messages;

  PlayerModel({
    required this.userId,
    this.username,
    this.score,
    this.isDrawing,
    this.messages,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    List<Message>? messageList;
    if (json['messages'] != null) {
      messageList =
          (json['messages'] as List).map((m) => Message.fromJson(m)).toList();
    }

    return PlayerModel(
      userId: json['userId'] ?? '',
      username: json['username'],
      score: json['score'],
      isDrawing: json['isDrawing'] ?? false,
      messages: messageList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'score': score,
      'isDrawing': isDrawing,
      'messages': messages?.map((m) => m.toJson()).toList(),
    };
  }
}
