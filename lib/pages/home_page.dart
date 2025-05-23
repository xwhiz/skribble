import 'dart:async';
import 'dart:ui';

import 'package:app/pages/create_room.dart';
import 'package:app/pages/game_layout.dart';
import 'package:app/pages/join_private_room.dart';
import 'package:app/pages/login_page.dart';
import 'package:app/viewmodels/main_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SkribbleLogo(),
                                const SizedBox(height: 16),
                                _buildButton(
                                  context,
                                  icon: Icons.public,
                                  text: "Join Public Game",
                                  onTap: viewModel.isLoading
                                      ? null
                                      : () async {
                                          await viewModel.joinPublicRoom();

                                          if (viewModel.room != null &&
                                              viewModel.error == null) {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
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
                                  icon: Icons.exit_to_app,
                                  text: "Sign Out",
                                  onTap: () async {
                                    await _auth.signOut();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => LoginPage()),
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
          'assets/images/splash-animation.png',
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
