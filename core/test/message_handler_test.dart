import 'dart:io';

import 'package:p2p_chat_core/p2p_chat_core.dart';
import 'package:p2p_chat_core/src/message_handler.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () async {
      server();
      final socket = await Socket.connect('localhost', 4567);
      final messageHandler = MessageHandler(socket);
      messageHandler.sendText('hello');
      await Future.delayed(Duration(seconds: 2));

    });
  });
}

void server() async {
  // bind the socket server to an address and port
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, 4567);

  // listen for clent connections to the server
  server.listen((client) {
    final messageHandler = MessageHandler(client);


  });
}