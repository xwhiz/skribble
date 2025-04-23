// components/chat_bubble.dart
import 'package:flutter/material.dart';
import 'package:app/models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  Color _getUserColor(int position) {
    switch (position) {
      case 1:
        return Colors.red[300]!;
      case 2:
        return Colors.green;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.purple[300]!;
      case 5:
        return Colors.cyan;
      case 6:
        return Colors.amber;
      case 7:
        return Colors.blue[800]!;
      default:
        return Colors.grey[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = message.isSystemMessage ? Colors.grey[700]! : _getUserColor(message.playerPosition);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          children: [
            if (!message.isSystemMessage)
              TextSpan(
                text: "${message.username}: ",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            TextSpan(
              text: message.message,
              style: TextStyle(
                color: message.isCorrectGuess ? Colors.green : textColor,
                fontWeight: message.isCorrectGuess ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}