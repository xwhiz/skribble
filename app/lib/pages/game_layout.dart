import 'dart:async';

import 'package:app/data/constants.dart';
import 'package:app/pages/home_page.dart';
import 'package:app/viewmodels/drawing_view_model.dart';
import 'package:app/viewmodels/main_view_model.dart';
import 'package:app/widgets/chat_widget.dart';
import 'package:app/widgets/drawing_board_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameLayout extends StatefulWidget {
  const GameLayout({super.key});

  @override
  State<GameLayout> createState() => _GameLayoutState();
}

class _GameLayoutState extends State<GameLayout>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0; // 0 for Players, 1 for Chat

  // Timer countdown
  int _seconds = K.roundDuration;
  Timer? _timer;

  bool _isChangingTurn = false;
  bool _isLeavingRoom = false;

  DrawingViewModel? _drawingViewModel;

  @override
  void initState() {
    super.initState();

    final mainViewModel = Provider.of<MainViewModel>(context, listen: false);

    // Start timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        }
      });

      if (_seconds <= 0) {
        setState(() {
          _isChangingTurn = true;
        });
        _drawingViewModel?.clearCanvas();
        mainViewModel.startDrawing().then(
          (value) {
            setState(() {
              _isChangingTurn = false;
            });
          },
        );
      }
    });

    super.initState();
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
      final remainingTime = K.roundDuration - timeElapsed.inSeconds;
      return remainingTime > 0 ? remainingTime : 0;
    }
    print('No drawing start time available');
    return K.roundDuration; // Default to full duration if no start time
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MainViewModel>(context);

    _seconds = getRemainingTime(vm.room?.drawingStartAt);

    // Check if we have a valid room ID
    if (vm.currentRoomId == null) {
      return Scaffold(
        body: Center(
          child: Text('No active room. Please join a room first.'),
        ),
      );
    }

    // Create a new DrawingViewModel for this room
    return ChangeNotifierProvider<DrawingViewModel>(
      // Use create instead of value to ensure a fresh instance
      create: (_) {
        var drawingVM = DrawingViewModel(roomId: vm.currentRoomId!);
        _drawingViewModel = drawingVM;
        return drawingVM;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top header with timer - FIXED HEIGHT to prevent overflow
              HeaderWidget(
                timerText: _timerText,
              ),

              // // Word display bar
              // Container(
              //   height: 20,
              //   color: Color.fromARGB(179, 32, 42, 53),
              //   alignment: Alignment.center,
              //   child: Text(
              //     vm.room?.hiddenWord ?? '_ _ _ _ _',
              //     style: TextStyle(
              //       fontSize: 16,
              //       fontWeight: FontWeight.bold,
              //       color: Colors.white,
              //     ),
              //   ),
              // ),

              // Drawing board - using Expanded to take remaining space
              Expanded(
                flex: 60,
                child: _isChangingTurn
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: CircularProgressIndicator(),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Changing turn...',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      )
                    : DrawingBoardWidget(roomId: vm.currentRoomId!),
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
                          _buildPlayersList(vm.currentRoomId!),

                          // Chat tab
                          ChatWidget(
                            roomId: vm.currentRoomId!,
                          ),
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
                        player['username'],
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

class HeaderWidget extends StatefulWidget {
  final String timerText;

  const HeaderWidget({super.key, required this.timerText});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  bool _isLeavingRoom = false;

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MainViewModel>(context);

    return SizedBox(
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
                    widget.timerText,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Smaller font size to ensure it fits
                    ),
                  ),
                ],
              ),
            ),

            // Center: Word
            Flexible(
              child: Text(
                vm.room?.currentWord?.toUpperCase() ?? "HOUSE",
                overflow: TextOverflow.ellipsis, // Ensure text doesn't overflow
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            // Right: Exit button - Using IconButton with smaller constraints
            IconButton(
              icon: _isLeavingRoom
                  ? CircularProgressIndicator()
                  : Icon(Icons.exit_to_app, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(), // Remove default constraints
              onPressed: () async {
                setState(() {
                  _isLeavingRoom = true;
                });

                await vm.leaveRoom();

                setState(() {
                  _isLeavingRoom = false;
                });

                Navigator.canPop(context)
                    ? Navigator.pop(context)
                    : Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
