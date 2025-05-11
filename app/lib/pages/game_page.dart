import 'package:flutter/material.dart';
import 'package:app/widgets/drawing_board_widget.dart';
import 'package:app/widgets/chat_widget.dart';
import 'dart:async';

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0; // 0 for Players, 1 for Chat

  // Timer countdown
  int _seconds = 60;
  Timer? _timer;

  // Format seconds as mm:ss
  String get _timerText {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // List of players to cycle through
  List<String> players = ["User-1776", "User-965", "User-321", "User-487"];
  int currentDrawerIndex =
      1; // Start with User-965 drawing (matches your screenshot)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Start the timer
    startTimer();
  }

  void startTimer() {
    _seconds = 60; // Reset to 60 seconds
    _timer?.cancel(); // Cancel any existing timer

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          // Time's up! Go to next drawer
          moveToNextDrawer();
        }
      });
    });
  }

  void moveToNextDrawer() {
    setState(() {
      // Move to the next player in the list
      currentDrawerIndex = (currentDrawerIndex + 1) % players.length;
      // Reset the timer
      _seconds = 60;
    });

    // Update the drawing control in Firebase
    _updateDrawingControl();
  }

  void _updateDrawingControl() {
    // This would call into the drawing board widget to change drawer
    // For now, we'll just reset the timer but in a real implementation
    // you would communicate with Firebase

    // You can access the DrawingBoardWidget using a GlobalKey and call methods on it
    // or use a state management solution like Provider
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top header - Now with real timer
            Container(
              height: 40,
              color: Color.fromARGB(179, 32, 42, 53),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Timer - Now shows the actual countdown
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          _timerText, // Using the real timer value
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Center: Word
                  Text(
                    "HOUSE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  // Right: Padding for symmetry
                  SizedBox(width: 60),
                ],
              ),
            ),

            // Drawing status bar - Now showing the current drawer from our list
            // Container(
            //   padding: EdgeInsets.symmetric(vertical: 8),
            //   width: double.infinity,
            //   color: Colors.lightBlue.shade50,
            //   child: Center(
            //     child: Text(
            //       "${players[currentDrawerIndex]} is drawing...",
            //       style: TextStyle(
            //         color: Colors.blue.shade700,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            // ),

            // Drawing board - reduce size to leave more room for bottom panels
            Expanded(
              flex: 60, // Reduced from 65 to leave more space for bottom panels
              child: Container(
                color: Colors.white,
                child: DrawingBoardWidget(),
              ),
            ),

            // Bottom tabs section - increase its size
            Expanded(
              flex: 40, // Increased from 35 to give more space for controls
              child: Column(
                children: [
                  // Tab selector - modified to handle taps
                  Container(
                    color: Colors.grey.shade200,
                    height: 36, // Slightly reduced to save space
                    child: Row(
                      children: [
                        // Players tab
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 0;
                              });
                            },
                            child: Container(
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
                              child: Center(
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
                        ),

                        // Chat tab
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 1;
                              });
                            },
                            child: Container(
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
                              child: Center(
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
                        ),
                      ],
                    ),
                  ),

                  // Content area - use the selected tab index
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTabIndex, // Use the selected index
                      children: [
                        // Players list
                        _buildPlayersList(),

                        // Chat widget
                        ChatWidget(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersList() {
    return Container(
      color: Colors.grey.shade100,
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 4),
        children: [
          _buildPlayerTile("User-1776", true, 120),
          _buildPlayerTile("User-965", false, 80),
          _buildPlayerTile("User-321", false, 65),
          _buildPlayerTile("User-487", false, 45),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(String name, bool isDrawing, int score) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDrawing ? Colors.green.withOpacity(0.2) : Colors.white,
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
              name,
              style: TextStyle(
                fontWeight: isDrawing ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            score.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }
}
