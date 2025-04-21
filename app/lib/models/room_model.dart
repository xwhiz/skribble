import 'package:app/models/message_model.dart';
import 'package:app/models/user_model.dart';

class RoomModel {
  final String id;
  final List<User> users;
  final List<Message> messages;

  RoomModel({required this.id, required this.users, required this.messages});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'users': users.map((user) => user.toJson()).toList(),
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      users: (json['users'] as List)
          .map((userJson) => User.fromJson(userJson))
          .toList(),
      messages: (json['messages'] as List)
          .map((messageJson) => Message.fromJson(messageJson))
          .toList(),
    );
  }
}