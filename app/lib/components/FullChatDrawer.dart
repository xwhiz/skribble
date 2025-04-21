import 'package:flutter/material.dart';

class Message {
  final String text;
  final String sender;

  Message({required this.text, required this.sender});
}

List<Message> messages = [
  Message(text: "Hey, how are you?", sender: "Hamze", ),
  Message(text: "I'm good, you?", sender: "Haseeb"),
  Message(text: "Same here!", sender: "Abdullah"),
];


class FullChatDrawer extends StatefulWidget {
  const FullChatDrawer({super.key});

  @override
  State<FullChatDrawer> createState() => _FullChatDrawerState();
}

class _FullChatDrawerState extends State<FullChatDrawer> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      builder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.person),),
                title: Text(message.sender),
                subtitle: Text(message.text),
                trailing: Icon(Icons.chat),
              ),
            );  
          }
        );
      },
    );
  }
}
