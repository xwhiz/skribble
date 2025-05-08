import 'package:flutter/material.dart';
import 'chat_interface.dart'; // Import your ChatInterface
import 'package:provider/provider.dart';
import '../viewmodels/matchmaking_view_model.dart'; // Import your MatchmakingViewModel

class GameLayout extends StatelessWidget {
  const GameLayout({super.key});

  @override
  Widget build(BuildContext context) {

    final matchMakingViewModel = Provider.of<MatchmakingViewModel>(context);
    print("joined room with room id: ${matchMakingViewModel.room?.roomCode}");

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: GUESS THIS, Clock, and Hint
            Container(
              height: 60,
              color: Color.fromARGB(179, 32, 42, 53),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Clock and Round info
                  Flexible(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 16,
                          ),
                          Text(
                            '12:45', // eplace with dynamic clock
                            style: TextStyle(
                              fontSize: 10, // Adjusted font size
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                          Text(
                            'Round 1 / 5', // eplace with dynamic info
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Text(
                    'GUESS THIS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'ComicNeue',
                    ),
                  ),

                  // Right side: Hint
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      'Hint: [word]', // Replace with actual dynamic hint
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'ComicNeue',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 20,
              color: Color.fromARGB(179, 32, 42, 53),
              alignment: Alignment.center,
              child: const Text(
                '- - - - - -', // Adjust the dashes as needed
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'ComicNeue',
                ),
              ),
            ),
            // Top Half: Drawing Area
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.white,
                child: const Center(
                  child: Text(
                    'Drawing Area',
                    style: TextStyle(fontSize: 20, fontFamily: 'ComicNeue'),
                  ),
                ),
              ),
            ),

            // Bottom Half: Split into 2 vertical sections
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  // Bottom Left Section (Players List)
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.green[100],
                      child: const Center(
                        child: Text(
                          'Players List',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'ComicNeue',
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Right Section (Chat Interface)
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      child: Container(
                        color: Colors.blueGrey[50],
                        child: const ChatInterface(),
                      ),
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
}
