// viewmodels/chat_viewmodel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app/models/message_model.dart';
import 'package:app/services/chat_service.dart';
import 'package:app/repositories/dummy_data.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final String currentUserId = "user7"; // This would come from auth in a real app
  final String currentUsername = "Habob (You)";
  final int currentPlayerPosition = 7;
  
  Stream<List<ChatMessage>> get chatStream => _chatService.chatStream;
  
  Map<int, Map<String, dynamic>> get players => DummyChatData.getPlayers();
  
  void sendMessage() {
    if (messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(
        messageController.text.trim(),
        currentUserId,
        currentUsername,
        currentPlayerPosition,
      );
      messageController.clear();
      
      // Auto-scroll to the bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
  
  // In a real game, this would be called when a player guesses correctly
  void simulateCorrectGuess() {
    _chatService.markAsCorrectGuess(currentUserId);
  }
  
  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }
}