import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../lib/data/constants.dart';
import '../../lib/models/room_model.dart';
import '../../lib/models/player_model.dart';
import '../../lib/models/message_model.dart';
import '../../lib/models/chat_message_model.dart';

void main() {
  group('Message Model', () {
    test('fromJson should parse correctly', () {
      final timestamp = Timestamp.now();
      final json = {
        'text': 'Hello',
        'timestamp': timestamp,
      };

      final message = Message.fromJson(json);

      expect(message.text, 'Hello');
      expect(message.timestamp, timestamp);
    });

    test('toJson should serialize correctly', () {
      final timestamp = Timestamp.now();
      final message = Message(text: 'Hi', timestamp: timestamp);
      final json = message.toJson();

      expect(json['text'], 'Hi');
      expect(json['timestamp'], timestamp);
    });
  });

  group('ChatMessage Model', () {
    test('fromJson with missing fields uses defaults', () {
      final json = <String, dynamic>{};
      final chatMessage = ChatMessage.fromJson(json);

      expect(chatMessage.userId, 'anonymous');
      expect(chatMessage.username, 'Anonymous');
      expect(chatMessage.content, '');
      expect(chatMessage.type, 'text');
      expect(chatMessage.timestamp, null);
    });

    test('toJson returns correct map', () {
      final chatMessage = ChatMessage(
        userId: 'user1',
        username: 'User One',
        content: 'Test content',
        timestamp: Timestamp.now(),
        type: 'text',
      );

      final json = chatMessage.toJson();

      expect(json['userId'], 'user1');
      expect(json['username'], 'User One');
      expect(json['content'], 'Test content');
      expect(json['type'], 'text');
      expect(json.containsKey('timestamp'), true);
    });
  });

  group('PlayerModel', () {
    test('fromJson parses messages and fields', () {
      final timestamp = Timestamp.now();
      final json = {
        'userId': '123',
        'username': 'player1',
        'score': 10,
        'isDrawing': true,
        'messages': [
          {'text': 'msg1', 'timestamp': timestamp},
          {'text': 'msg2', 'timestamp': timestamp},
        ],
      };

      final player = PlayerModel.fromJson(json);

      expect(player.userId, '123');
      expect(player.username, 'player1');
      expect(player.score, 10);
      expect(player.isDrawing, true);
      expect(player.messages!.length, 2);
      expect(player.messages![0].text, 'msg1');
    });

    test('toJson serializes properly', () {
      final timestamp = Timestamp.now();
      final player = PlayerModel(
        userId: '321',
        username: 'player2',
        score: 5,
        isDrawing: false,
        messages: [
          Message(text: 'hello', timestamp: timestamp),
        ],
      );

      final json = player.toJson();

      expect(json['userId'], '321');
      expect(json['username'], 'player2');
      expect(json['score'], 5);
      expect(json['isDrawing'], false);
      expect((json['messages'] as List).length, 1);
      expect(json['messages'][0]['text'], 'hello');
    });
  });

  group('RoomModel', () {
    test('fromJson parses all fields correctly', () {
      final timestamp = Timestamp.now();
      final json = {
        'roomCode': 'ABCD',
        'maxPlayers': 6,
        'currentPlayers': 3,
        'currentRound': 1,
        'totalRounds': 5,
        'currentDrawerId': 'drawer1',
        'currentWord': 'apple',
        'hint': 'fruit',
        'hiddenWord': 'a----',
        'timeLeft': '01:30',
        'isPrivate': true,
        'isChangingTurn': false,
        'players': [
          {
            'userId': 'p1',
            'username': 'player1',
            'score': 10,
            'isDrawing': true,
            'messages': [
              {'text': 'msg1', 'timestamp': timestamp}
            ],
          }
        ],
        'messages': [
          {
            'userId': 'p1',
            'username': 'player1',
            'content': 'hello',
            'timestamp': timestamp,
            'type': 'text',
          }
        ],
        'roundDuration': 60,
        'createAt': timestamp,
        'drawingStartAt': timestamp,
        'drawingQueue': ['p1', 'p2'],
        'guessedCorrectly': ['p3'],
      };

      final room = RoomModel.fromJson(json);

      expect(room.roomCode, 'ABCD');
      expect(room.maxPlayers, 6);
      expect(room.currentPlayers, 3);
      expect(room.currentRound, 1);
      expect(room.totalRounds, 5);
      expect(room.currentDrawerId, 'drawer1');
      expect(room.currentWord, 'apple');
      expect(room.hint, 'fruit');
      expect(room.hiddenWord, 'a----');
      expect(room.timeLeft, '01:30');
      expect(room.isPrivate, true);
      expect(room.isChangingTurn, false);
      expect(room.players!.length, 1);
      expect(room.players![0].userId, 'p1');
      expect(room.messages!.length, 1);
      expect(room.messages![0].content, 'hello');
      expect(room.roundDuration, 60);
      expect(room.createAt, timestamp);
      expect(room.drawingStartAt, timestamp);
      expect(room.drawingQueue, ['p1', 'p2']);
      expect(room.guessedCorrectly, ['p3']);
    });

    test('fromJson applies default values if missing', () {
      final json = {
        'roomCode': 'XYZ',
        // no maxPlayers, currentRound, totalRounds, etc.
      };

      final room = RoomModel.fromJson(json);

      expect(room.roomCode, 'XYZ');
      expect(room.maxPlayers, K.maxPlayers);
      expect(room.currentRound, 0);
      expect(room.totalRounds, K.totalRounds);
      expect(room.isPrivate, false);
      expect(room.isChangingTurn, false);
    });
  });
}
