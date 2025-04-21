// lib/dummy_data.dart
import 'package:app/models/user_model.dart';
import 'package:app/models/room_model.dart';
import 'package:app/models/message_model.dart';

List<User> dummyUsers = [
  User(id: 'u1', name: 'Alice'),
  User(id: 'u2', name: 'Bob'),
  User(id: 'u3', name: 'Charlie'),
];

List<Message> dummyMessages = [
  Message(id: 'm1', content: 'Hello!', user: dummyUsers[0]),
  Message(id: 'm2', content: 'Hi there!', user: dummyUsers[1]),
  Message(id: 'm3', content: 'Let’s play!', user: dummyUsers[2]),
];

List<RoomModel> dummyRooms = [
  RoomModel(
    id: 'room1',
    users: dummyUsers,
    messages: dummyMessages,
  ),
];
