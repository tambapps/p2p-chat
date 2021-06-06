import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'io.dart';
import 'model.dart';

/// base class for a chat
abstract class Chat {

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

// TODO create a DOJO (POJO for dart) for user data (username)
/// return false if user should be filtered
typedef ConnectionCallback = bool Function(dynamic data);

class ChatServer extends Chat {

  // HTTP port. Required since we're using an Http Server for the Web Socket
  static const PORT = 8000;

  final WebsocketServer server;
  final MessageCallback onMessageReceived;
  final ConnectionCallback? onNewSocket;
  final List<WebSocket> sockets = [];

  ChatServer(this.server, this.onMessageReceived, {this.onNewSocket});

  static Future<ChatServer> from(InternetAddress address, MessageCallback onMessageReceived,
      {ConnectionCallback? onNewSocket}) async {
    final server = await WebsocketServer.from(InternetAddress.loopbackIPv4, ChatServer.PORT);
    return ChatServer(server, onMessageReceived, onNewSocket: onNewSocket);
  }

  void start() {
    server.listen((socket) { 
      // TODO do handshake and stuff
      //   add optional key password
      if (onNewSocket == null || onNewSocket!.call(socket)) {
        socket.listen((bytes) => onMessageReceived(toMessage(bytes)));
        sockets.add(socket);
      }
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

class ChatClient extends Chat {

  final WebSocket socket;

  /// [address] must be the String address, or the InternetAddress
  static Future<ChatClient> from(address,
      MessageCallback onMessageReceived, {Function? onError}) async {
    String addressString;
    if (address is InternetAddress) {
      addressString = address.address;
    } else {
      addressString = address.toString();
    }
    final socket = await WebSocket.connect('ws://$addressString:${ChatServer.PORT}');
    return ChatClient(socket, onMessageReceived, onError: onError);
  }

  ChatClient(this.socket, MessageCallback onMessageReceived, {Function? onError}) {
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
