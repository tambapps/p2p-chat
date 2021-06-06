import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:p2p_chat_core/src/util.dart';

import 'io.dart';
import 'model.dart';

/// base class for a chat
abstract class Chat {

  /// Sends the [text] message to the other peer
  void sendText(String text) {
    sendMessage(Message(address.address, userData, text, DateTime.now()));
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

  UserData get userData;
  InternetAddress get address;
}

typedef MessageCallback = void Function(Message message);

// TODO create a DOJO (POJO for dart) for user data (username)
/// return false if user should be filtered
typedef ConnectionCallback = bool Function(dynamic data);

// TODO handle server errors
class ChatServer extends Chat {


  // HTTP port. Required since we're using an Http Server for the Web Socket
  static const PORT = 8000;

  final WebsocketServer server;
  final MessageCallback onMessageReceived;
  final ConnectionCallback? onNewSocket;
  final List<WebSocket> sockets = [];
  @override
  UserData userData;

  ChatServer(this.server, this.onMessageReceived, {this.onNewSocket, this.userData = const UserData('anonymous')});

  static Future<ChatServer> from(address, MessageCallback onMessageReceived,
      {ConnectionCallback? onNewSocket}) async {
    final server = await WebsocketServer.from(await toAddress(address), ChatServer.PORT);
    return ChatServer(server, onMessageReceived, onNewSocket: onNewSocket);
  }

  StreamSubscription<HttpRequest> start() {
    return server.listen((socket) {
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

  @override
  InternetAddress get address {
    return server.server.address;
  }
}

class ChatClient extends Chat {

  final WebSocket socket;
  @override
  UserData userData;

  /// [address] must be the String address, or the InternetAddress
  static Future<ChatClient> from(addressArg,
      MessageCallback onMessageReceived, {Function? onError}) async {
    var address = await toAddress(addressArg);
    final socket = await WebSocket.connect('ws://${address.address}:${ChatServer.PORT}');
    return ChatClient(socket, onMessageReceived, onError: onError);
  }

  ChatClient(this.socket, MessageCallback onMessageReceived, {Function? onError, this.userData = const UserData('anonymous')}) {
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

  @override
  InternetAddress get address {
    // TODO replace this getter by get identifier, the server should give the client an identifier through handshake
    return InternetAddress.loopbackIPv4;
  }
}
