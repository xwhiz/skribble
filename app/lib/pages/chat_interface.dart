import 'dart:ui';
import 'package:app/viewmodels/chat_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/services/firestore_service.dart';

class ChatInterface extends StatefulWidget {
  final String roomId;

  const ChatInterface({super.key, required this.roomId});

  @override
  // ignore: library_private_types_in_public_api
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final TextEditingController messageController = TextEditingController();
  //final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService firestoreService = FirestoreService();

  late Timestamp loginTimestamp;
  late ChatViewModel chatViewModel;
  bool isSendingButton = false; // Track sending status for button

  @override
  void initState() {
    super.initState();
    loginTimestamp = Timestamp.now();
    chatViewModel = ChatViewModel(roomId: widget.roomId);
  }

  Future<void> sendMessage() async {
    final String message = messageController.text.trim();
    final String userName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous';

    if (message.isNotEmpty) {
      setState(() {
        isSendingButton = true;
      });

      messageController.clear();

      try {
        await chatViewModel.sendMessage(message);
      } catch (e) {
        // ignore: avoid_print
        print('Failed to send message: $e');
      } finally {
        setState(() {
          isSendingButton = false;
        });
      }
    }
  }

  // Stream<QuerySnapshot> getMessages() {
  //   return _firestore.collection('playerbook').orderBy('timestamp').snapshots();
  // }

  @override
  Widget build(BuildContext context) {
    final List<Color> messageColors = [
      const Color(0xFFFFD3B6),
      const Color(0xFFFFAAA5),
      const Color(0xFFFCB0B3),
      const Color(0xFFAEDFF7),
      const Color(0xFFF7D6E0),
      const Color(0xFFB5EAD7),
    ];

    return Container(
      //color: const Color(0xFFE0EAFC),
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getMessages(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  final filteredMessages =
                      messages.where((msg) {
                        final Timestamp messageTimestamp =
                            msg['timestamp'] ?? Timestamp(0, 0);
                        return messageTimestamp.compareTo(loginTimestamp) >= 0;
                      }).toList();

                  return ListView.builder(
                    itemCount: filteredMessages.length,
                    itemBuilder: (context, index) {
                      final messageData = filteredMessages[index];
                      final String senderName = messageData['name'];
                      final String message = messageData['message'];

                      final Color bgColor =
                          messageColors[index % messageColors.length];

                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: bgColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '$senderName: $message',
                            style: const TextStyle(
                              color: Color.fromARGB(179, 32, 42, 53),
                              fontSize: 16,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            style: const TextStyle(
                              color: Color.fromARGB(179, 32, 42, 53),
                              fontFamily: 'ComicNeue',
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(
                                color: Color.fromARGB(179, 32, 42, 53),
                                fontFamily: 'ComicNeue',
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        isSendingButton
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.fromARGB(179, 32, 42, 53),
                                ),
                              ),
                            )
                            : IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Color.fromARGB(179, 32, 42, 53),
                              ),
                              onPressed: sendMessage,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
