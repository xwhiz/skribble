import 'dart:ui';

import 'package:provider/provider.dart';
import 'package:app/pages/create_room.dart';
import 'package:app/pages/exisitng_rooms.dart';
import 'package:app/pages/game_layout.dart';
import 'package:app/pages/join_private_room.dart';
import 'package:flutter/material.dart';
import 'package:app/viewmodels/matchmaking_view_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    //Access the ViewModel
    final viewModel = Provider.of<MatchmakingViewModel>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0EAFC), // Soft blue
              Color(0xFFCFDEF3), // Very light purple/blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    // ignore: deprecated_member_use
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          viewModel.isLoading
                            ? null // Disable button while loading
                            : () async {
                                await viewModel.joinRoom();
                                
                                // Check if joining was successful
                                if (viewModel.room != null && viewModel.error == null) {
                                  Navigator.push(
                                    // ignore: use_build_context_synchronously
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const GameLayout(),
                                    ),
                                  );
                                } else if (viewModel.error != null) {
                                  // Show error message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(viewModel.error!)),
                                  );
                                }
                              };
                        },
                        style: ElevatedButton.styleFrom(
                          // ignore: deprecated_member_use
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.public,
                              color: Color.fromARGB(179, 32, 42, 53),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Join Public Game",
                              style: TextStyle(
                                fontSize: 24,
                                color: Color.fromARGB(179, 32, 42, 53),
                                fontWeight: FontWeight.normal,
                                fontFamily:
                                    'ComicNeue', // Applying Comic Neue font
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                              builder: (_) => const JoinPrivateRoom(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          // ignore: deprecated_member_use
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.privacy_tip,
                              color: Color.fromARGB(179, 32, 42, 53),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Join Private Game",
                              style: TextStyle(
                                fontSize: 24,
                                color: Color.fromARGB(179, 32, 42, 53),
                                fontWeight: FontWeight.normal,
                                fontFamily:
                                    'ComicNeue', // Applying Comic Neue font
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateRoom(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Color.fromARGB(179, 32, 42, 53),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Create Room",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Color.fromARGB(179, 32, 42, 53),
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ExisitngRooms(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Existing Rooms",
                              style: TextStyle(
                                fontSize: 20,
                                color: Color.fromARGB(179, 32, 42, 53),
                                fontFamily: 'ComicNeue',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
