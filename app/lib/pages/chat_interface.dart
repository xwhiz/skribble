import 'dart:ui';
import 'package:app/models/chat_message_model.dart';
import 'package:app/viewmodels/chat_view_model.dart';
import 'package:app/viewmodels/matchmaking_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatInterface extends StatefulWidget {
  final String roomId;

  const ChatInterface({super.key, required this.roomId});

  @override
  // ignore: library_private_types_in_public_api
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final TextEditingController messageController = TextEditingController();
  bool isSendingButton = false; // Track sending status for button
  late ChatViewModel chatViewModel;

  @override
  void initState() {
    super.initState();
    chatViewModel = ChatViewModel(roomId: widget.roomId);
  }

  Future<void> sendMessage() async {
    final String message = messageController.text.trim();
    final String userName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous';
    final String userId =
        FirebaseAuth.instance.currentUser?.uid ??
        ''; // Get the current user's UID

    if (message.isNotEmpty && userId.isNotEmpty) {
      setState(() {
        isSendingButton = true;
      });

      messageController.clear();

      try {
        // Ensure the message is passed to the ViewModel or directly to Firestore with the necessary parameters
        await chatViewModel.sendMessage(
          message,
          userName,
          userId,
          widget.roomId,
        );
      } catch (e) {
        print('Failed to send message: $e');
      } finally {
        setState(() {
          isSendingButton = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var roomViewModel = Provider.of<MatchmakingViewModel>(context);

    final List<Color> messageColors = [
      const Color(0xFFFFD3B6),
      const Color(0xFFFFAAA5),
      const Color(0xFFFCB0B3),
      const Color(0xFFAEDFF7),
      const Color(0xFFF7D6E0),
      const Color(0xFFB5EAD7),
    ];

    return Container(
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
              child: StreamBuilder<List<ChatMessage>>(
                stream: chatViewModel.getMessagesStream(
                  roomViewModel.room!.roomCode,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageData = messages[index];
                      final String senderName = messageData.name;
                      final String message = messageData.message;

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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
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
