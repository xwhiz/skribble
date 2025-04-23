// services/chat_service.dart
import 'dart:async';
import 'package:app/models/message_model.dart';
import 'package:app/repositories/dummy_data.dart';

class ChatService {
  final _chatController = StreamController<List<ChatMessage>>.broadcast();
  List<ChatMessage> _messages = [];
  
  Stream<List<ChatMessage>> get chatStream => _chatController.stream;
  
  ChatService() {
    // Load dummy data initially
    _messages = DummyChatData.getChatMessages();
    _chatController.add(_messages);
  }

  void sendMessage(String message, String userId, String username, int playerPosition) {
    final newMessage = ChatMessage(
      username: username,
      message: message,
      timestamp: DateTime.now(),
      userId: userId,
      playerPosition: playerPosition,
    );
    
    _messages.add(newMessage);
    _chatController.add(_messages);
    
    // In a real app, you would send this to Firebase here
  }

  void addSystemMessage(String message) {
    final systemMessage = ChatMessage(
      username: "System",
      message: message,
      isSystemMessage: true,
      timestamp: DateTime.now(),
      userId: "system",
      playerPosition: 0,
    );
    
    _messages.add(systemMessage);
    _chatController.add(_messages);
  }

  void markAsCorrectGuess(String userId) {
    // Find the last message from this user and mark it as correct
    final index = _messages.lastIndexWhere((msg) => msg.userId == userId);
    if (index != -1) {
      final correctMessage = ChatMessage(
        username: _messages[index].username,
        message: "guessed the word!",
        isCorrectGuess: true,
        timestamp: DateTime.now(),
        userId: userId,
        playerPosition: _messages[index].playerPosition,
      );
      
      _messages.add(correctMessage);
      _chatController.add(_messages);
    }
  }

  void dispose() {
    _chatController.close();
  }
}