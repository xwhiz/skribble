import 'dart:ui';

import 'package:app/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuestLogin extends StatefulWidget {
  const GuestLogin({super.key});

  @override
  State<GuestLogin> createState() => _GuestLoginState();
}

class _GuestLoginState extends State<GuestLogin> {
  final nameController = TextEditingController();

  Future<void> saveGuestName() async {
    String name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please provide a name")));
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    try {
      var auth = FirebaseAuth.instance;
      auth.currentUser!.updateDisplayName(name);
      auth.currentUser?.reload();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } catch (e) {
      print("Error during login: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    }
  }

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
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: "Enter your username",
                          hintStyle: const TextStyle(
                            color: Color.fromARGB(179, 32, 42, 53),
                            fontSize: 14,
                            fontFamily: 'ComicNeue',
                          ),
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
                        ),
                        style: const TextStyle(
                          color: Color.fromARGB(179, 32, 42, 53),
                          fontFamily: 'ComicNeue',
                        ),
                      ),
                      const SizedBox(height: 20), // Add some space between
                      SizedBox(
                        width: 400,
                        child: ElevatedButton(
                          onPressed: () async {
                            await saveGuestName();
                          },
                          style: ElevatedButton.styleFrom(
                            // ignore: deprecated_member_use
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Enter",
                            style: TextStyle(
                              fontSize: 24,
                              color: Color.fromARGB(179, 32, 42, 53),
                              fontWeight: FontWeight.bold,
                              fontFamily:
                                  'ComicNeue', // Applying Comic Neue font
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
