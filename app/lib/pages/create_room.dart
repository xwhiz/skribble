import 'dart:ui';

import 'package:app/pages/game_layout.dart';
import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
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
                        controller: roomNameController,
                        decoration: InputDecoration(
                          hintText: "Enter Room ID",
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(179, 32, 42, 53),
                            fontSize: 14,
                            fontFamily: 'ComicNeue',
                            // Applying Comic Neue font
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

                      TextField(
                        controller: wordBankController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Enter number of rounds",
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
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     Expanded(
                      //       child: RadioListTile<WordBank>(
                      //         title: const Text(
                      //           'Easy',
                      //           style: TextStyle(
                      //             fontSize: 14,
                      //             fontFamily: 'ComicNeue',
                      //             color: Color.fromARGB(179, 32, 42, 53),
                      //           ),
                      //         ),
                      //         value: WordBank.easy,
                      //         groupValue: _wordBank,
                      //         onChanged: (WordBank? value) {
                      //           setState(() {
                      //             _wordBank = value;
                      //           });
                      //         },
                      //         dense: true,
                      //         contentPadding: EdgeInsets.zero,
                      //         activeColor: Color.fromARGB(179, 32, 42, 53),
                      //       ),
                      //     ),
                      //     Expanded(
                      //       child: RadioListTile<WordBank>(
                      //         title: const Text(
                      //           'Medium',
                      //           style: TextStyle(
                      //             fontSize: 14,
                      //             fontFamily: 'ComicNeue',
                      //             color: Color.fromARGB(179, 32, 42, 53),
                      //           ),
                      //         ),
                      //         value: WordBank.medium,
                      //         groupValue: _wordBank,
                      //         onChanged: (WordBank? value) {
                      //           setState(() {
                      //             _wordBank = value;
                      //           });
                      //         },
                      //         dense: true,
                      //         contentPadding: EdgeInsets.zero,
                      //         activeColor: Color.fromARGB(179, 32, 42, 53),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: 10),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     Expanded(
                      //       child: RadioListTile<WordBank>(
                      //         title: const Text(
                      //           'Hard',
                      //           style: TextStyle(
                      //             fontSize: 14,
                      //             fontFamily: 'ComicNeue',
                      //             color: Color.fromARGB(179, 32, 42, 53),
                      //           ),
                      //         ),
                      //         value: WordBank.hard,
                      //         groupValue: _wordBank,
                      //         onChanged: (WordBank? value) {
                      //           setState(() {
                      //             _wordBank = value;
                      //           });
                      //         },
                      //         dense: true,
                      //         contentPadding: EdgeInsets.zero,
                      //         activeColor: Color.fromARGB(179, 32, 42, 53),
                      //       ),
                      //     ),
                      //     Expanded(
                      //       child: RadioListTile<WordBank>(
                      //         title: const Text(
                      //           'Custom Word Bank',
                      //           style: TextStyle(
                      //             fontSize: 14,
                      //             fontFamily: 'ComicNeue',
                      //             color: Color.fromARGB(179, 32, 42, 53),
                      //           ),
                      //         ),
                      //         value: WordBank.customBank,
                      //         groupValue: _wordBank,
                      //         onChanged: (WordBank? value) {
                      //           setState(() {
                      //             _wordBank = value;
                      //           });
                      //         },
                      //         dense: true,
                      //         contentPadding: EdgeInsets.zero,
                      //         activeColor: Color.fromARGB(179, 32, 42, 53),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      TextField(
                        controller: maxPlayerController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Enter maximum players",
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
                      TextField(
                        controller: roundDurationController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Enter round time duration",
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
                        onPressed: () {
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
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Create",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(179, 32, 42, 53),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ComicNeue', // Applying Comic Neue font
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
