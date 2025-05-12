import 'dart:async';
import 'dart:ui';
<<<<<<< HEAD
import 'package:flutter/material.dart';
=======
import 'package:app/pages/round_page.dart';
>>>>>>> 1304c50d7811a0bc00fba252c4e3137b2f1e9799
import 'package:provider/provider.dart';
import 'package:app/pages/create_room.dart';
import 'package:app/pages/game_layout.dart';
import 'package:app/pages/join_private_room.dart';
<<<<<<< HEAD
import 'package:app/viewmodels/main_view_model.dart';
=======
import 'package:flutter/material.dart';
import 'package:app/viewmodels/matchmaking_view_model.dart';
>>>>>>> 1304c50d7811a0bc00fba252c4e3137b2f1e9799

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    //Access the ViewModel
    final viewModel = Provider.of<MainViewModel>(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
<<<<<<< HEAD
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                // ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.3),
                              ),
=======
                      ElevatedButton(
                        onPressed:
                            viewModel.isLoading
                                ? null
                                : () async {
                                  print("Hello");
                                  // log.info("Joining public game...");
                                  await viewModel.joinRoom();

                                  // Check if joining was successful
                                  if (viewModel.room != null &&
                                      viewModel.error == null) {
                                    // Show RoundPage temporarily, then navigate to GameLayout
                                    Navigator.push(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => RoundPage(
                                              onFinish: () {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            const GameLayout(),
                                                  ),
                                                );
                                              },
                                            ),
                                      ),
                                    );
                                  } else if (viewModel.error != null) {
                                    // Show error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(viewModel.error!)),
                                    );
                                  }
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
                      SizedBox(
                        width: 300,
                        child: ElevatedButton(
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
>>>>>>> 1304c50d7811a0bc00fba252c4e3137b2f1e9799
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SkribbleLogo(),
                                SizedBox(height: 16),
                                _buildButton(
                                  context,
                                  icon: Icons.public,
                                  text: "Join Public Game",
                                  onTap: viewModel.isLoading
                                      ? null
                                      : () async {
                                          await viewModel.joinPublicRoom();

                                          // Check if joining was successful
                                          if (viewModel.room != null &&
                                              viewModel.error == null) {
                                            Navigator.push(
                                              // ignore: use_build_context_synchronously
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const GameLayout(),
                                              ),
                                            );
                                          } else if (viewModel.error != null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  viewModel.error!,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                ),
                                const SizedBox(height: 10),
                                _buildButton(
                                  context,
                                  icon: Icons.privacy_tip,
                                  text: "Join Private Game",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const JoinPrivateRoom(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                _buildButton(
                                  context,
                                  icon: Icons.add,
                                  text: "Create Room",
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CreateRoom(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required FutureOr<void> Function()? onTap,
  }) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color.fromARGB(179, 32, 42, 53)),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color.fromARGB(179, 32, 42, 53),
                fontWeight: FontWeight.normal,
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkribbleLogo extends StatelessWidget {
  const SkribbleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          '../assets/images/splash-animation.png',
          height: 130,
          fit: BoxFit.contain,
        ),
        const Positioned(
          bottom: 0,
          child: Text(
            "SKRIBBLE",
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              fontFamily: 'ComicNeue',
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
