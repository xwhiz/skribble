import 'dart:async';

import 'package:app/data/constants.dart';
import 'package:app/pages/completed_page.dart';
import 'package:app/pages/home_page.dart';
import 'package:app/viewmodels/drawing_view_model.dart';
import 'package:app/viewmodels/main_view_model.dart';
import 'package:app/widgets/chat_widget.dart';
import 'package:app/widgets/drawing_board_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool isWaitingForOtherPlayers = true;
  bool hasChoosenWord = false;
  bool isCompletedOnce = false;

  DrawingViewModel? _drawingViewModel; // initialized late

  @override
  void initState() {
    // Start timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      final mainViewModel = Provider.of<MainViewModel>(context, listen: false);
      var players = mainViewModel.room?.players ?? [];

      if (isCompletedOnce) {
        return;
      }

      if (players.length <= 1) {
        setState(() {
          isWaitingForOtherPlayers = true;
        });

        if (mainViewModel.room?.currentRound != 0) {
          _timer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CompletedPage(),
            ),
          );
        }

        return;
      } else {
        setState(() {
          isWaitingForOtherPlayers = false;
        });
      }

      if (mainViewModel.isGameCompleted) {
        timer.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CompletedPage(),
          ),
        );
        return;
      }

      setState(() {
        if (_seconds > 0) {
          _seconds--;
        }
      });

      if (_seconds <= 0 || mainViewModel.isCurrentDrawingCompleted) {
        setState(() {
          isCompletedOnce = true;
        });
        _drawingViewModel?.clearCanvas();
        await Provider.of<MainViewModel>(context, listen: false)
            .startNextTurn();
        setState(() {
          isCompletedOnce = false;
        });
      }
    });

    super.initState();
    var vm = Provider.of<MainViewModel>(context, listen: false);
    if (vm.room?.currentRound == 0) {
      vm.startNextTurn();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MainViewModel>(context);
    _seconds = getRemainingTime(vm.room?.drawingStartAt);

    bool isChangingTurn = vm.room?.isChangingTurn ?? false;

    print("Current round: ${vm.room?.currentRound}");
    print("round completed: ${vm.isCurrentDrawingCompleted}");
    print("game completed: ${vm.isGameCompleted}");

    if (isWaitingForOtherPlayers) {
      return Scaffold(
        body: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 20,
            children: [
              Text('Searching for players...',
                  style: Theme.of(context).textTheme.displaySmall),
              ElevatedButton(
                onPressed: () async {
                  await vm.leaveRoom();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomePage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  // ignore: deprecated_member_use
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Stop Searching",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ComicNeue', // Applying Comic Neue font
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if we have a valid room ID
    if (vm.currentRoomId == null) {
      return Scaffold(
        body: Center(
          child: Text('No active room. Please join a room first.'),
        ),
      );
    }

    Widget dynamicBoard;
    if (isChangingTurn) {
      dynamicBoard = Column(
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
      );
    } else {
      dynamicBoard = DrawingBoardWidget(roomId: vm.currentRoomId!);
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

              // Drawing board - using Expanded to take remaining space
              Expanded(
                flex: 60,
                child: dynamicBoard,
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

  // Format seconds as mm:ss
  String get _timerText {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int getRemainingTime(Timestamp? drawingStartAt) {
    final currentTime = DateTime.now();
    if (drawingStartAt != null) {
      final timeElapsed = currentTime.difference(drawingStartAt.toDate());
      final remainingTime = K.roundDuration - timeElapsed.inSeconds;
      return remainingTime > 0 ? remainingTime : 0;
    }
    print('No drawing start time available');
    return K.roundDuration; // Default to full duration if no start time
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

    bool isDrawer =
        vm.room?.currentDrawerId == FirebaseAuth.instance.currentUser?.uid;
    bool hasGuessed = vm.room!.guessedCorrectly!.contains(
      FirebaseAuth.instance.currentUser?.uid,
    );

    String currentWord = vm.room!.currentWord!;
    String hiddenWord = vm.room!.hiddenWord!;

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
                isDrawer || hasGuessed ? currentWord : hiddenWord,
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
