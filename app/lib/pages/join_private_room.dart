import 'dart:ui';

import 'package:app/pages/game_layout.dart';
import 'package:flutter/material.dart';
import 'package:app/viewmodels/matchmaking_view_model.dart';
import 'package:provider/provider.dart';


class JoinPrivateRoom extends StatefulWidget {
  const JoinPrivateRoom({super.key});

  @override
  State<JoinPrivateRoom> createState() => _JoinPrivateRoomState();
}

class _JoinPrivateRoomState extends State<JoinPrivateRoom> {
  final TextEditingController codeController = TextEditingController();
  @override
  Widget build(BuildContext context) {
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
                      TextField(
                        controller: codeController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Enter private room code",
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(179, 32, 42, 53),
                            fontSize: 14,
                            fontFamily: 'ComicNeue', // Applying Comic Neue font
                          ),
                          filled: true,
                          // ignore: deprecated_member_use
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: const Color.fromARGB(179, 32, 42, 53),
                              width: 2,
                            ), // Highlight effect
                          ),
                        ),
                        style: TextStyle(
                          color: Color.fromARGB(179, 32, 42, 53),
                          fontFamily: 'ComicNeue',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await viewModel.joinPrivateRoom(codeController.text);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GameLayout(),
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
                            const Text(
                              "Join",
                              style: TextStyle(
                                fontSize: 24,
                                color: Color.fromARGB(179, 32, 42, 53),
                                fontWeight: FontWeight.bold,
                                fontFamily:
                                    'ComicNeue', // Applying Comic Neue font
                              ),
                            ),
                          ],
                        ),
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
