import 'package:app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/viewmodels/main_view_model.dart';
import 'package:app/viewmodels/drawing_view_model.dart';
import 'package:app/widgets/drawing_board_widget.dart';
import 'package:app/widgets/chat_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:app/data/constants.dart';

import 'package:shared_preferences/shared_preferences.dart';

class GameLayout extends StatefulWidget {
  const GameLayout({Key? key}) : super(key: key);

  @override
  State<GameLayout> createState() => _GameLayoutState();
}

class _GameLayoutState extends State<GameLayout>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0; // 0 for Players, 1 for Chat
  late String _guestName;

  // Timer countdown
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    final viewModel = Provider.of<MainViewModel>(context, listen: false);

    viewModel.getGuestName().then((name) {
      setState(() {
        _guestName = name;
      });
    });

    // Start timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Format seconds as mm:ss
  String get _timerText {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }


  int getRemainingTime(drawingStartAt) {
    final currentTime = DateTime.now();
    if (drawingStartAt != null) {
      final timeElapsed = currentTime.difference(drawingStartAt.toDate());
      print('Time elapsed: ${timeElapsed.inSeconds} seconds');
      final remainingTime = K.roundDuration - timeElapsed.inSeconds;
      return remainingTime > 0 ? remainingTime : 0;
    }
    print('No drawing start time available');
    return K.roundDuration; // Default to full duration if no start time
  }
  @override
  Widget build(BuildContext context) {
    final mainViewModel = Provider.of<MainViewModel>(context);
    final drawingStartAt = mainViewModel.room?.drawingStartAt;
    print("drawingStartAt: $drawingStartAt");
    final remainingTime = getRemainingTime(drawingStartAt);
    print('Remaining time: $remainingTime');
    _seconds = remainingTime;
    // Check if we have a valid room ID
    if (mainViewModel.currentRoomId == null) {
      return Scaffold(
        body: Center(
          child: Text('No active room. Please join a room first.'),
        ),
      );
    }

    // Create a new DrawingViewModel for this room
    return ChangeNotifierProvider<DrawingViewModel>(
      // Use create instead of value to ensure a fresh instance
      create: (_) => DrawingViewModel(roomId: mainViewModel.currentRoomId!),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top header with timer - FIXED HEIGHT to prevent overflow
              SizedBox(
                height: 40,
                child: Container(
                  color: Color.fromARGB(179, 32, 42, 53),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Timer indicator
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              _timerText,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    14, // Smaller font size to ensure it fits
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Center: Word
                      Flexible(
                        child: Text(
                          mainViewModel.room?.currentWord?.toUpperCase() ??
                              "HOUSE",
                          overflow: TextOverflow
                              .ellipsis, // Ensure text doesn't overflow
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // Right: Exit button - Using IconButton with smaller constraints
                      IconButton(
                        icon: Icon(Icons.exit_to_app, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints:
                            BoxConstraints(), // Remove default constraints
                        onPressed: () {
                          mainViewModel.leaveRoom();
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Word display bar
              Container(
                height: 20,
                color: Color.fromARGB(179, 32, 42, 53),
                alignment: Alignment.center,
                child: Text(
                  mainViewModel.room?.hiddenWord ?? '_ _ _ _ _',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // Drawing board - using Expanded to take remaining space
              Expanded(
                flex: 60,
                child: DrawingBoardWidget(roomId: mainViewModel.currentRoomId!),
              ),

              // Tabs and bottom area
              Expanded(
                flex: 40,
                child: Column(
                  children: [
                    // Tab selector
                    Container(
                      height: 36,
                      color: Colors.grey[200],
                      child: Row(
                        children: [
                          // Players tab
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 0),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _selectedTabIndex == 0
                                          ? Colors.blue
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Players',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTabIndex == 0
                                        ? Colors.blue
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Chat tab
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedTabIndex = 1),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _selectedTabIndex == 1
                                          ? Colors.blue
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Chat',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTabIndex == 1
                                        ? Colors.blue
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab content - takes remaining space
                    Expanded(
                      child: IndexedStack(
                        index: _selectedTabIndex,
                        children: [
                          // Players tab
                          _buildPlayersList(mainViewModel.currentRoomId!),

                          // Chat tab
                          ChatWidget(
                              roomId: mainViewModel.currentRoomId!,
                              guestName: _guestName),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersList(String roomId) {
    return Container(
      color: Colors.grey.shade100,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Room')
            .doc(roomId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return Center(child: Text('No player data'));
          }

          final players = data['players'] as List<dynamic>? ?? [];

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 4),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index] as Map<String, dynamic>;
              final isDrawing = player['userId'] == data['currentDrawerId'];

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isDrawing ? Colors.green.withOpacity(0.2) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDrawing ? Icons.brush : Icons.person,
                      size: 18,
                      color: isDrawing ? Colors.green : Colors.grey[700],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        player['username']?.toString().isNotEmpty == true
                            ? player['username']
                            : (player['userId'] ==
                                    FirebaseAuth.instance.currentUser?.uid
                                ? _guestName
                                : 'Guest'),
                        style: TextStyle(
                          fontWeight:
                              isDrawing ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      (player['score'] ?? 0).toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
