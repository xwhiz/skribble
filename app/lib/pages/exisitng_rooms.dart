import 'package:flutter/material.dart';

class ExisitngRooms extends StatelessWidget {
  const ExisitngRooms({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Existing Rooms will be displayed here...',
          style: TextStyle(
            fontFamily: 'ComicNeue',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(179, 32, 42, 53),
          ),
        ),
      ),
    );
  }
}
