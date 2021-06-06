import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'io.dart';
import 'model.dart';

/// base class for a chat
abstract class _AbstractChat {

  /// Sends the [text] message to the other peer
  void sendText(String text) {
    sendMessage(Message(text, DateTime.now()));
  }

  /// Sends the [message] to the other peer
  void sendMessage(Message message) {
    // if I send String, the triggered event data will be String
    // if I send bytes, it will be bytes. For simplicity, let's send bytes (and therefore
    // handle bytes) everytime
    sendData(jsonEncode(message).codeUnits);
  }

  @protected
  void sendData(data);

  @protected
  Message toMessage(Uint8List data) {
    return Message.fromJson(jsonDecode(String.fromCharCodes(data)));
  }

  void close();
}

typedef MessageCallback = void Function(Message message);

class ChatServer extends _AbstractChat {

  static const PORT = 8000;

  final WebsocketServer server;
  final MessageCallback onMessageReceived;
  final MessageCallback? onNewSocket;
  final List<WebSocket> sockets = [];

  ChatServer(this.server, this.onMessageReceived, {this.onNewSocket});

  void start() {
    server.listen((socket) { 
      // TODO do handshake and stuff
      //   add optional key password
      socket.listen((bytes) => onMessageReceived(toMessage(bytes)));
      sockets.add(socket);
    });
  }

  @override
  void sendData(data) {
    for (var client in sockets) {
      client.add(data);
    }
  }

  @override
  void close({bool force = false}) {
    server.close(force: force);
  }
}

class Chat extends _AbstractChat {

  final WebSocket socket;

  Chat(this.socket, MessageCallback onMessageReceived, {Function? onError}) {
    socket.listen((bytes) => onMessageReceived(toMessage(bytes)), onError: onError);
  }

  @override
  void sendData(data) {
    socket.add(data);
  }

  @override
  void close() {
    socket.close();
  }
}
