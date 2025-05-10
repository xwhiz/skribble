import 'dart:ui';

import 'package:app/pages/game_layout.dart';
import 'package:app/viewmodels/main_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateRoom extends StatefulWidget {
  const CreateRoom({super.key});

  @override
  State<CreateRoom> createState() => _CreateRoomState();
}

class _CreateRoomState extends State<CreateRoom> {
  TextEditingController roomNameController = TextEditingController();
  TextEditingController wordBankController = TextEditingController();
  TextEditingController maxPlayerController = TextEditingController();
  TextEditingController roundDurationController = TextEditingController();
  int? totalRounds;
  int? maxPlayers;
  int? roundDuration;
  @override
  Widget build(BuildContext context) {
    final matchMakingViewModel = Provider.of<MainViewModel>(context);

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
                      // Total Rounds Dropdown
                      DropdownButtonFormField<int>(
                        value: totalRounds,
                        decoration: _inputDecoration(),
                        hint: Text(
                          "Select total rounds",
                          style: TextStyle(
                            color: const Color.fromARGB(179, 32, 42, 53),
                            fontFamily: 'ComicNeue',
                            fontSize: 14,
                          ),
                        ),
                        items:
                            [1, 2, 3, 4, 5]
                                .map(
                                  (round) => DropdownMenuItem(
                                    value: round,
                                    child: Text('$round'),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            totalRounds = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // Max Players Dropdown
                      DropdownButtonFormField<int>(
                        value: maxPlayers,
                        decoration: _inputDecoration(),
                        hint: Text(
                          "Select maximum players",
                          style: TextStyle(
                            color: const Color.fromARGB(179, 32, 42, 53),
                            fontFamily: 'ComicNeue',
                            fontSize: 14,
                          ),
                        ),
                        items:
                            [8, 12, 16]
                                .map(
                                  (player) => DropdownMenuItem(
                                    value: player,
                                    child: Text('$player'),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            maxPlayers = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // Round Duration Dropdown
                      DropdownButtonFormField<int>(
                        value: roundDuration,
                        decoration: _inputDecoration(),
                        hint: Text(
                          "Select round duration",
                          style: TextStyle(
                            color: const Color.fromARGB(179, 32, 42, 53),
                            fontFamily: 'ComicNeue',
                            fontSize: 14,
                          ),
                        ),
                        items:
                            [60, 70, 80, 90, 100]
                                .map(
                                  (duration) => DropdownMenuItem(
                                    value: duration,
                                    child: Text('$duration sec'),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            roundDuration = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: 400,
                        child: ElevatedButton(
                          onPressed: () {
                            if (maxPlayers != null &&
                                roundDuration != null &&
                                totalRounds != null) {
                              matchMakingViewModel.createRoom(
                                maxPlayers: maxPlayers!,
                                roundDuration: roundDuration!,
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GameLayout(),
                                ),
                              );
                            } else {
                              // Show a dialog or snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please select all options"),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Create",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(179, 32, 42, 53),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
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

InputDecoration _inputDecoration() {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Color.fromARGB(179, 32, 42, 53),
        width: 2,
      ),
    ),
  );
}
