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
      server();
      final socket = await Socket.connect('localhost', 4567);
      final messageHandler = TcpChat(socket, (message) => print('Client received message ' + jsonEncode(message)));
      messageHandler.sendText('World');
      await Future.delayed(Duration(seconds: 2));
    });
  });
}

void server() async {
  // bind the socket server to an address and port
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, 4567);
  server.listen((client) {
    final messageHandler = TcpChat(client, (message) => print('Server received message ' + jsonEncode(message)));
    messageHandler.sendText('Hello');
  });
}