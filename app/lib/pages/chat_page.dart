import 'package:flutter/material.dart';
import 'package:app/data/dummy_data.dart';



class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.person),),
            title: Text("John"),
            subtitle: Text("Hey, how are you?"),
            trailing: Icon(Icons.chat),
          ),
        );
      });
  }
}

