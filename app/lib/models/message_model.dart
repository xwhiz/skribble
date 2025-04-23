// models/chat_message.dart
class ChatMessage {
  final String username;
  final String message;
  final bool isCorrectGuess;
  final bool isSystemMessage;
  final DateTime timestamp;
  final String userId;
  final int playerPosition; // To display different colors based on player position

  ChatMessage({
    required this.username,
    required this.message,
    this.isCorrectGuess = false,
    this.isSystemMessage = false,
    required this.timestamp,
    required this.userId,
    required this.playerPosition,
  });
}