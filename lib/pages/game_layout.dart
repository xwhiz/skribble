import 'dart:async';

import 'package:app/data/constants.dart';
import 'package:app/models/player_model.dart';
import 'package:app/pages/completed_page.dart';
import 'package:app/pages/home_page.dart';
import 'package:app/viewmodels/drawing_view_model.dart';
import 'package:app/viewmodels/main_view_model.dart';
import 'package:app/widgets/chat_widget.dart';
import 'package:app/widgets/drawing_board_widget.dart';
import 'package:app/widgets/header_widget.dart';
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
  bool isWaitingForOtherPlayers = true;

  DrawingViewModel? _drawingViewModel; // initialized late

  @override
  void initState() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      final mainViewModel = Provider.of<MainViewModel>(context, listen: false);
      var players = mainViewModel.room?.players ?? [];
      bool showRoundAndPlayerInfo = mainViewModel.room?.showRoundInfo ?? false;

      if (players.length <= 1) {
        setState(() {
          isWaitingForOtherPlayers = true;
        });

        // game is running already and all players have left
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

      if (showRoundAndPlayerInfo) {
        return;
      }

      if (mainViewModel.isGameCompleted) {
        _timer?.cancel();
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
        _drawingViewModel?.clearCanvas();
        await Provider.of<MainViewModel>(context, listen: false)
            .startNextTurn();
        resetRoundAndInfoFlag();
      }
    });

    super.initState();
    var vm = Provider.of<MainViewModel>(context, listen: false);
    if (vm.room?.currentRound == 0) {
      vm.startNextTurn().then((val) {
        print(
            "before reseting info flag: ${vm.room?.showRoundInfo} ${vm.room?.players?.length}");
        if (vm.room?.showRoundInfo == true && vm.room!.players!.length > 1) {
          resetRoundAndInfoFlag();
        }
      });
    }
  }

  Future<void> resetRoundAndInfoFlag() async {
    final vm = Provider.of<MainViewModel>(context, listen: false);
    await Future.delayed(Duration(seconds: 5), () async {
      print("reseting info flag");
      await FirebaseFirestore.instance
          .collection(K.roomCollection)
          .doc(vm.currentRoomId)
          .update({'showRoundInfo': false});

      print("reseted info flag");

      setState(() {
        _seconds = K.roundDuration;
      });
    });
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
    bool showRoundInfo = vm.room?.showRoundInfo ?? false;

    // print("Current round: ${vm.room?.currentRound}");
    // print("round completed: ${vm.isCurrentDrawingCompleted}");
    // print("game completed: ${vm.isGameCompleted}");

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

    if (vm.isGameCompleted) {
      return Scaffold(
        body: Center(
          child:
              Text('Game completed', style: TextStyle(fontFamily: 'ComicNeue')),
        ),
      );
    }

    // Check if we have a valid room ID
    if (vm.currentRoomId == null) {
      return Scaffold(
        body: Center(
          child: Text('No active room. Please join a room first.',
              style: TextStyle(fontFamily: 'ComicNeue')),
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
            style: TextStyle(fontSize: 18, fontFamily: 'ComicNeue'),
          ),
        ],
      );
    } else if (showRoundInfo &&
        vm.room!.currentRound! <= vm.room!.totalRounds! &&
        vm.room?.currentRound != 0) {
      List<PlayerModel> drawer = vm.room?.players
              ?.where(
                (player) => player.userId == vm.room?.currentDrawerId,
              )
              .toList() ??
          [];
      String drawerName =
          drawer.isNotEmpty ? drawer.first.username! : 'Unknown';

      dynamicBoard = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Round ${vm.room?.currentRound}",
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'ComicNeue',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Player $drawerName is drawing...",
            style: TextStyle(fontSize: 18, fontFamily: 'ComicNeue'),
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
                                    fontFamily: 'ComicNeue',
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
                                    fontFamily: 'ComicNeue',
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
    return K.roundDuration; // Default to full duration if no start time
  }

  Widget _buildPlayersList(String roomId) {
    return Container(
      color: Colors.grey.shade100,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(K.roomCollection)
            .doc(roomId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return Center(
                child: Text('No player data',
                    style: TextStyle(fontFamily: 'ComicNeue')));
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
                          fontFamily: 'ComicNeue',
                          fontWeight:
                              isDrawing ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      (player['score'] ?? 0).toString(),
                      style: TextStyle(
                        fontFamily: 'ComicNeue',
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
