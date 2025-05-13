import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/data/constants.dart';
import 'player_model.dart';
import 'chat_message_model.dart'; // Import the ChatMessage model

class RoomModel {
  final String roomCode;
  final String status; // 'waiting', 'playing', 'ended'
  final String? currentDrawerId;
  final String? currentWord;
  final String? hint;
  final String? hiddenWord; // Word with dashes for players to guess
  final String? timeLeft; // Formatted time left "01:25"
  final bool? isPrivate;
  final List<PlayerModel>? players;
  final List<String>? drawingQueue;
  final List<ChatMessage>? messages; // New field for player messages
  final int? roundDuration;
  final int? maxPlayers;
  final int? currentPlayers;
  final int? currentRound;
  final int? totalRounds;
  final Timestamp? createAt;
  final Timestamp? drawingStartAt; // New field for drawing start time

  RoomModel({
    required this.roomCode,
    required this.status,
    this.maxPlayers,
    this.currentPlayers,
    this.currentRound,
    this.totalRounds,
    this.currentDrawerId,
    this.currentWord,
    this.hint,
    this.hiddenWord,
    this.timeLeft,
    this.isPrivate,
    this.players,
    this.messages, // Initialize playerMessages
    this.roundDuration,
    this.createAt,
    this.drawingStartAt,
    this.drawingQueue,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // Parse players list if it exists
    List<PlayerModel>? playersList;
    if (json['players'] != null) {
      playersList =
          (json['players'] as List)
              .map((playerJson) => PlayerModel.fromJson(playerJson))
              .toList();
    }
    // print("After players");


    // Parse playerMessages map if it exists
    List<ChatMessage>? messages;

    if (json['messages'] != null) {
      var msgs = List<dynamic>.from(json['messages']);
      messages = msgs.map((msg) => ChatMessage.fromJson(msg)).toList();
    }

    List<String>? drawingQueue;
    if (json['drawingQueue'] != null) {
      var queue = List<dynamic>.from(json['drawingQueue']);
      drawingQueue = queue.map((e) => e.toString()).toList();
    }

    // print("After messages");

    var roomModel = RoomModel(
      roomCode: json['roomCode'] ?? '',
      status: json['status'] ?? 'waiting',
      maxPlayers: json['maxPlayers'] ?? K.maxPlayers,
      currentPlayers: json['currentPlayers'],
      currentRound: json['currentRound'] ?? 0,
      totalRounds: json['totalRounds'] ?? K.totalRounds,
      currentDrawerId: json['currentDrawerId'],
      currentWord: json['currentWord'],
      hint: json['hint'],
      hiddenWord: json['hiddenWord'],
      timeLeft: json['timeLeft'],
      isPrivate: json['isPrivate'] ?? false,
      players: playersList,
      drawingQueue: drawingQueue,//json['drawingQueue'],
      roundDuration: json['roundDuration'] ?? K.roundDuration,
      messages: messages,
      createAt:
          json['createAt'] != null ? (json['createAt'] as Timestamp) : null,
      drawingStartAt:
          json['drawingStartAt'] != null ? (json['drawingStartAt'] as Timestamp) : null,
    );

    // print("After roomModel");

    return roomModel;
  }
}
