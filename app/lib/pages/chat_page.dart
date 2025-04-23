// pages/game_page.dart
import 'package:flutter/material.dart';
import 'package:app/components/chat_component.dart';

class GamePage extends StatelessWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Drawing Game Chat"),
      ),
      body: Column(
        children: [
          // Placeholder for the game canvas area
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: const Center(
                child: Text(
                  "Game Canvas Area\n(To be implemented)",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color.fromARGB(255, 120, 120, 120), fontSize: 18),
                ),
              ),
            ),
          ),
          
          // Divider between game area and chat
          Divider(height: 1, color: Colors.grey[400]),
          
          // Chat component - the focus of our implementation
          const SizedBox(
            height: 300, // Increased height for better visibility during testing
            child: ChatComponent(),
          ),
        ],
      ),
    );
  }
}