import 'package:app/models/message_model.dart';

class DummyChatData {
  static List<ChatMessage> getChatMessages() {
    return [
      ChatMessage(
        username: "skribblBot",
        message: "guessed the word!",
        isCorrectGuess: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        userId: "bot1",
        playerPosition: 5,
      ),
      ChatMessage(
        username: "Toj",
        message: "guessed the word!",
        isCorrectGuess: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1, seconds: 40)),
        userId: "user2",
        playerPosition: 2,
      ),
      ChatMessage(
        username: "Nerd",
        message: "Is it a horse?",
        isCorrectGuess: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        userId: "user1",
        playerPosition: 4,
      ),
      ChatMessage(
        username: "System",
        message: "Pew is drawing now!",
        isSystemMessage: true,
        timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
        userId: "system",
        playerPosition: 0,
      ),
      ChatMessage(
        username: "Pew",
        message: "This is hard to draw",
        isCorrectGuess: false,
        timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
        userId: "user6",
        playerPosition: 6,
      ),
    ];
  }

  static Map<int, Map<String, dynamic>> getPlayers() {
    return {
      1: {'name': 'Nerd', 'points': 1320, 'isDrawing': false},
      2: {'name': 'Toj', 'points': 1295, 'isDrawing': false},
      3: {'name': 'speech', 'points': 1075, 'isDrawing': false},
      4: {'name': '#4', 'points': 895, 'isDrawing': false},
      5: {'name': 'skribblBot', 'points': 275, 'isDrawing': false},
      6: {'name': 'Pew', 'points': 260, 'isDrawing': true},
      7: {'name': 'Habob (You)', 'points': 0, 'isDrawing': false},
    };
  }
}