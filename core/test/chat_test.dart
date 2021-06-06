import 'dart:convert';
import 'dart:io';

import 'package:p2p_chat_core/src/chat.dart';
import 'package:p2p_chat_core/src/io.dart';
import 'package:test/test.dart';

void main() {
  group('Message handler tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('send text Test', () async {
      final chatServer = await server();
      print('Connecting to socket');
      final socket = await WebSocket.connect('ws://localhost:${ChatServer.PORT}');
      print('Connected to socket');
      final chat = Chat(socket, (message) => print('Client received message ' + jsonEncode(message)));
      chat.sendText('Hello');
      chatServer.sendText('World');
      await Future.delayed(Duration(seconds: 2));
      chatServer.close();
      chat.close();
    });
  });
}

Future<ChatServer> server() async {
  // bind the socket server to an address and port
  final server = await WebsocketServer.from('localhost', ChatServer.PORT);
  print('Server started');
  final chatServer = ChatServer(server, (message) {
    print('Server received message ' + jsonEncode(message));
  });
  chatServer.start();
  return chatServer;
}