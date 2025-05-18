import 'package:app/pages/home_page.dart';
import 'package:app/viewmodels/main_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HeaderWidget extends StatelessWidget {
  final String timerText;

  const HeaderWidget({super.key, required this.timerText});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MainViewModel>(context);

    bool isDrawer =
        vm.room?.currentDrawerId == FirebaseAuth.instance.currentUser?.uid;
    bool hasGuessed = vm.room!.guessedCorrectly!.contains(
      FirebaseAuth.instance.currentUser?.uid,
    );

    String currentWord = vm.room!.currentWord!;
    String hiddenWord = vm.room!.hiddenWord!;

    return SizedBox(
      height: 40,
      child: Container(
        color: Color.fromARGB(179, 32, 42, 53),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Timer indicator
            Flexible(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      timerText,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ComicNeue',
                        fontSize: 14, // Smaller font size to ensure it fits
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center: Word
            Flexible(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 4,
                children: [
                  Text(
                    isDrawer || hasGuessed ? currentWord : hiddenWord,
                    overflow:
                        TextOverflow.ellipsis, // Ensure text doesn't overflow
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ComicNeue',
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    ' (${currentWord.length})',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ComicNeue',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              flex: 1,
              child: IconButton(
                icon: Icon(Icons.exit_to_app, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(), // Remove default constraints
                onPressed: () {
                  vm.leaveRoom();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
