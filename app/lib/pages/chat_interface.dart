import 'package:flutter/material.dart';

class ChatInterface extends StatelessWidget {
  const ChatInterface({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 59, 54, 52),
        title: Center(
          child: Text('Chat Interface', style: TextStyle(color: Colors.white)),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: 20,
                itemBuilder: (context, index) {
                  return ListTile(title: Text('Message $index'));
                },
              ),
            ),
            TextField(
              decoration: InputDecoration(
                hintText: 'Type your guess here...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Handle send message
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
