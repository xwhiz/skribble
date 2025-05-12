import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String userId;
  final String username;
  final String content;
  final Timestamp? timestamp;

  ChatMessage({
    required this.userId,
    required this.username,
    required this.content,
    this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      userId: json['userId'] as String? ?? 'anonymous',
      username: json['username'] as String? ?? 'Anonymous',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'content': content,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }
}
// import 'package:cloud_firestore/cloud_firestore.dart';

// class ChatMessage {
//   final String name;
//   final String message;
//   final Timestamp timestamp;
//   final String? userId;

//   ChatMessage({
//     required this.name,
//     required this.message,
//     required this.timestamp,
//     required this.userId,
//   });

//   factory ChatMessage.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return ChatMessage(
//       name: data['name'] ?? 'Unknown',
//       message: data['message'] ?? '',
//       timestamp: data['timestamp'] ?? Timestamp.now(),
//       userId: data['userId'],
//     );
//   }

//   // Add a fromJson method to parse data
//   factory ChatMessage.fromJson(Map<String, dynamic> json) {
//     return ChatMessage(
//       name: json['name'] ?? 'Unknown',
//       message: json['message'] ?? '',
//       timestamp: json['timestamp'] ?? Timestamp.now(),
//       userId: json['userId'],
//     );
//   }

//   Map<String, dynamic> toMap(String roomId) {
//     return {
//       'name': name,
//       'message': message,
//       'timestamp': timestamp,
//       'roomId': roomId,
//     };
//   }

//   // Optionally, you can add a toJson method if you need to write to Firestore
//   Map<String, dynamic> toJson() {
//     return {'name': name, 'message': message, 'timestamp': timestamp};
//   }
// }
