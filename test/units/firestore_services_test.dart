import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/firestore_service.dart';

class FirestoreService {
  String _generateRoomCode() {
    const length = 6;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<String> getRandomWord() async {
    final jsonString = await rootBundle.loadString("assets/wordbank.json");
    var json = jsonDecode(jsonString);
    List<Map<String, dynamic>> wordObjects =
        List<Map<String, dynamic>>.from(json);
    List<String> words = wordObjects.map((e) => e['word'] as String).toList();
    words.shuffle();
    return words.take(1).toList()[0];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirestoreService - Random word Generation', () {
    late FirestoreService firestoreService;

    const mockJson = '''
      [
        {"word": "apple"},
        {"word": "banana"},
        {"word": "cherry"}
      ]
    ''';

    setUp(() {
      firestoreService = FirestoreService();
      ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          final String key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/wordbank.json') {
            return ByteData.view(utf8.encode(mockJson).buffer);
          }
          return null;
        },
      );
    });

    test('getRandomWord returns a word from the wordbank', () async {
      final word = await firestoreService.getRandomWord();
      expect(['apple', 'banana', 'cherry'], contains(word));
    });

    test('getRandomWord returns a non-empty string', () async {
      final word = await firestoreService.getRandomWord();
      expect(word.isNotEmpty, true);
    });
  });

  group('FirestoreService - Room Code Generation', () {
    late FirestoreService firestoreService;

    setUp(() {
      firestoreService = FirestoreService();
    });

    test('generated room code should be 6 characters long', () {
      final roomCode = firestoreService._generateRoomCode();
      expect(roomCode.length, equals(6));
    });

    test('generated room code should contain only uppercase letters and numbers', () {
      final roomCode = firestoreService._generateRoomCode();
      expect(roomCode, matches(r'^[A-Z0-9]+$'));
    });

    test('multiple room codes should be unique', () {
      final codes = List.generate(100, (_) => firestoreService._generateRoomCode());
      final uniqueCodes = codes.toSet();
      expect(codes.length, equals(uniqueCodes.length));
    });
  });
}
