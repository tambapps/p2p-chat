import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';
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
  int get port;
}

typedef MessageCallback = void Function(Message message);

// TODO create a DOJO (POJO for dart) for user data (username)
/// return false if user should be filtered
typedef ConnectionCallback = bool Function(Chat chat, dynamic data);

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
  @override
  InternetAddress get address => server.server.address;
  @override
  int get port => server.server.port;

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
      if (onNewSocket == null || onNewSocket!.call(this, socket)) {
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
  @override
  UserData userData;

  @override
  InternetAddress get address {
    // TODO replace this getter by get identifier, the server should give the client an identifier through handshake
    return InternetAddress.loopbackIPv4;
  }

  @override
  int get port => ChatServer.PORT;

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
}


/// Chat that starts a server AND listen for chat peers
/// if a chat peer is found, the chat server is stopped
/// if a connection is made under the server, it stops listening for chat peers
class SmartChat extends Chat {

  final PeerType peerType;
  final MessageCallback onMessageReceived;
  final ChatServer chatServer;
  final ChatPeerMulticaster multicaster;
  final ChatPeerListener listener;
  Chat chat;

  static Future<SmartChat> from(address, MessageCallback onMessageReceived,
      {ConnectionCallback? onNewSocket, PeerType peerType = PeerType.ANY}) async {
    final multicaster = await ChatPeerMulticaster.newInstance();
    final listener = await ChatPeerListener.newInstance();
    final server = await ChatServer.from(address, onMessageReceived, onNewSocket: (chat, data) {
      if (onNewSocket == null || onNewSocket(chat, data)) {
        multicaster.close();
        listener.close();
        return true;
      }
      return false;
    });

    // the chat is the server by default, if it will be overriden by a client chat
    // if one chat peer is found
    return SmartChat(peerType, onMessageReceived, server, server, multicaster, listener);
  }

  SmartChat(this.peerType, this.onMessageReceived, this.chatServer, this.chat, this.multicaster, this.listener);

  void start() {
    chatServer.start();
    if (peerType != PeerType.SERVER) {
      listener.listen(_listenChatPeers);
    }
    multicaster.chatPeers = [
      ChatPeer(chatServer.address.address, peerType, chatServer.port)
    ];
    multicaster.start();
  }

  void _listenChatPeers(List<ChatPeer> chatPeers) async {
    for (var chatPeer in chatPeers) {
      if (chatPeer.type == PeerType.ANY && this.peerType == PeerType.ANY) {
        // TODO find a way to determine which should be the server
      } else {
        chat = await ChatClient.from(chatPeers[0], onMessageReceived);
        chatServer.close();
        multicaster.close();
        listener.close();
        // TODO rethink what data should be passed for onNewSocket (maybe user data?)
        // calling onNewSocket to let the handler of smart chat that a connection has been
        // made
        chatServer.onNewSocket?.call(chat, 'something');
      }
    }
  }

  @override
  InternetAddress get address => chat.address;

  @override
  void close() {
    chatServer.close();
    chat.close();
    multicaster.close();
    listener.close();
  }

  @override
  void sendData(data) {
    chat.sendData(data);
  }

  @override
  void sendMessage(Message message) {
    chat.sendMessage(message);
  }

  @override
  void sendText(String text) {
    chat.sendText(text);
  }
  @override
  UserData get userData => chat.userData;

  @override
  int get port => chat.port;

}