import 'package:app/components/FullChatDrawer.dart';
import 'package:flutter/material.dart';
class Message {
  final String text;
  final bool isMe;

  Message({required this.text, required this.isMe});
}

List<Message> messages = [
  Message(text: "Hey, how are you?", isMe: false),
  Message(text: "I'm good, you?", isMe: true),
  Message(text: "Same here!", isMe: false),
];

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap : () {
        showModalBottomSheet(
          context: context, 
          builder: (context) => FullChatDrawer(),
          );
      },
      child: Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(Icons.person),),
          title: Text("John"),
          subtitle: Text("Hey, how are you?"),
          trailing: Icon(Icons.chat),
        ),
      ),
    );
  }
}

