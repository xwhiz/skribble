import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_model.dart';

class RoomModel {
  final String roomCode;
  final Timestamp createdAt;
  final int currentPlayers;
  final int maxPlayers;
  final String status;
  final List<PlayerModel> players;

  RoomModel({
    required this.roomCode,
    required this.createdAt,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.status,
    required this.players,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      roomCode: json['roomCode'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      currentPlayers: json['currentPlayers'] ?? 0,
      maxPlayers: json['maxPlayers'] ?? 8,
      status: json['status'] ?? 'notFull',
      players: (json['players'] as List<dynamic>? ?? [])
          .map((playerData) => PlayerModel.fromJson(playerData as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomCode': roomCode,
      'createdAt': createdAt,
      'currentPlayers': currentPlayers,
      'maxPlayers': maxPlayers,
      'status': status,
      'players': players.map((player) => player.toJson()).toList(),
    };
  }
}
