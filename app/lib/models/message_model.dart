import 'package:app/models/user_model.dart';

class Message {
  final String id;
  final String content;
  final User user;

  Message({required this.id, required this.content, required this.user});
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': user,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      user: json['user'] as User,
    );
  }
}