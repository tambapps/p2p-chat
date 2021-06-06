import 'dart:convert';
import 'dart:io';

import 'package:p2p_chat_core/src/chat.dart';
import 'package:test/test.dart';

void main() {
  group('Message handler tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('send text Test', () async {
      final chatServer = await server();
      final chat = await ChatClient.from(InternetAddress.loopbackIPv4, (message) => print('Client received message ' + jsonEncode(message)));
      print('Connected to socket');
      chat.sendText('Hello');
      chatServer.sendText('World');
      await Future.delayed(Duration(seconds: 2));
      chatServer.close();
      chat.close();
    });
  });
}

Future<ChatServer> server() async {
  final chatServer = await ChatServer.from(InternetAddress.loopbackIPv4, (message) {
    print('Server received message ' + jsonEncode(message));
  });
  chatServer.start();
  print('Server started');
  return chatServer;
}