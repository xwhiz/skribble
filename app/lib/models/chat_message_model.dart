import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String name;
  final String message;
  final Timestamp timestamp;

  ChatMessage({
    required this.name,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      name: data['name'] ?? 'Unknown',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap(String roomId) {
    return {
      'name': name,
      'message': message,
      'timestamp': timestamp,
      'roomId': roomId,
    };
  }
}
