import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_model.dart';

class RoomModel {
  final String roomCode;
  final String status; // 'waiting', 'playing', 'ended'
  final int? maxPlayers;
  final int? currentPlayers;
  final int? currentRound;
  final int? totalRounds;
  final String? currentDrawerId;
  final String? currentWord;
  final String? hint;
  final String? hiddenWord; // Word with dashes for players to guess
  final String? timeLeft; // Formatted time left "01:25"
  final List<PlayerModel>? players;

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
    this.players,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // Parse players list if it exists
    List<PlayerModel>? playersList;
    if (json['players'] != null) {
      playersList = (json['players'] as List)
          .map((playerJson) => PlayerModel.fromJson(playerJson))
          .toList();
    }

    return RoomModel(
      roomCode: json['roomCode'] ?? '',
      status: json['status'] ?? 'waiting',
      maxPlayers: json['maxPlayers'],
      currentPlayers: json['currentPlayers'],
      currentRound: json['currentRound'],
      totalRounds: json['totalRounds'],
      currentDrawerId: json['currentDrawerId'],
      currentWord: json['currentWord'],
      hint: json['hint'],
      hiddenWord: json['hiddenWord'],
      timeLeft: json['timeLeft'],
      players: playersList,
    );
  }
}