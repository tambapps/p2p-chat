import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:p2p_chat_core/src/connection/connection.dart';
import 'connection/websocket_connection.dart';
import 'util.dart';

import 'chat_automation.dart';
import 'chat_discovery.dart';
import 'model.dart';

/// base class for a chat
abstract class Chat {

  /// Sends the [text] message to the other peer
  Message sendText(String text) {
    final message = VerifiedMessage(address.address, userData, text, DateTime.now(), "");
    sendMessage(message);
    return message;
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

  void setMessageCallback(MessageCallback messageCallback);

  void close();

  UserData get userData;
  InternetAddress get address;
  int get port;
}

typedef MessageCallback = void Function(Message message);

/// return false if user should be filtered
typedef ChatConnectionCallback = bool Function(Chat chat, UserData data);

// TODO handle server errors
class ChatServer extends Chat {


  // HTTP port. Required since we're using an Http Server for the Web Socket
  static const PORT = 8000;

  final ConnectionServer server;
  final MessageCallback onMessageReceived;
  final ChatConnectionCallback? onNewSocket;
  final List<Connection> connections = [];
  @override
  UserData userData;
  @override
  InternetAddress get address => server.address;
  @override
  int get port => server.port;

  ChatPeer get chatPeer => ChatPeer.from(address, PeerType.SERVER, port, userData);

  ChatServer(this.server, this.onMessageReceived, {this.onNewSocket, this.userData = ANONYMOUS_USER});

  static Future<ChatServer> from(address, MessageCallback onMessageReceived,
      {ChatConnectionCallback? onNewSocket, UserData userData = ANONYMOUS_USER}) async {
    final server = await WebSocketServer.from(await toAddress(address), ChatServer.PORT);
    return ChatServer(server, onMessageReceived, onNewSocket: onNewSocket, userData: userData);
  }

  void start() {
    server.listen((final connection) {
      connection.automaton = ChatServerAutomaton(onMessageReceived, onNewSocket ?? (chat, data) => true);
      connection.listen((bytes) => connection.automaton.act(this, bytes));
      connections.add(connection);
    });
  }

  @override
  void sendData(data) {
    for (var client in connections) {
      client.send(data);
    }
  }

  @override
  void close({bool force = false}) {
    server.close();
  }

  @override
  void setMessageCallback(MessageCallback messageCallback) {
    for (var client in connections) {
      client.automaton.onMessageReceived = messageCallback;
    }
  }

}

class ChatClient extends Chat {

  final Connection connection;
  late final ChatClientAutomaton automaton;
  @override
  InternetAddress get address => connection.address;
  @override
  int get port => connection.port;

  @override
  UserData userData;

  /// [address] must be the String address, or the InternetAddress
  static Future<ChatClient> from(addressArg,
      MessageCallback onMessageReceived, {Function? onError, UserData userData = ANONYMOUS_USER}) async {
    var address = await toAddress(addressArg);
    var port = ChatServer.PORT;

    final connection = await WebSocketConnection.from(address, port);
    return ChatClient(connection, onMessageReceived, onError: onError, userData: userData);
  }

  ChatClient(this.connection, MessageCallback onMessageReceived,
      {Function? onError, this.userData = ANONYMOUS_USER}) {
    automaton = ChatClientAutomaton(onMessageReceived);
    // sending handshake data
    connection.sendText(jsonEncode(HandshakeData(userData)));
    connection.listen((bytes) => automaton.act(this, bytes), onError: onError);
  }

  @override
  void sendData(data) {
    connection.send(data);
  }

  @override
  void close() {
    connection.close();
  }

  @override
  void setMessageCallback(MessageCallback messageCallback) {
    automaton.onMessageReceived = messageCallback;
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
      {ChatConnectionCallback? onNewSocket, PeerType peerType = PeerType.ANY, UserData userData = ANONYMOUS_USER}) async {
    final multicaster = await ChatPeerMulticaster.newInstance();
    final listener = await ChatPeerListener.newInstance();
    final server = await ChatServer.from(address, onMessageReceived, userData: userData, onNewSocket: (chat, data) {
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
      ChatPeer(chatServer.address.address, peerType, chatServer.port, userData)
    ];
    multicaster.start();
  }

  void _listenChatPeers(List<ChatPeer> chatPeers) async {
    for (var chatPeer in chatPeers) {
      if (chatPeer.type == PeerType.ANY && this.peerType == PeerType.ANY) {
        // these are Strings
        final ownAddress = chatServer.address.address;
        final peerAddress = chatPeer.address;

        if (ownAddress.hashCode < peerAddress.hashCode) {
          if (await _connectTo(chatPeer)) {
            break;
          }
        } else {
          // do nothing, the other peer will connect to me
        }
        break;
      } else {
        if (await _connectTo(chatPeer)) {
          break;
        }
      }
    }
  }

  Future<bool> _connectTo(ChatPeer chatPeer) async {
    Chat chat = await ChatClient.from(chatPeer.internetAddress, onMessageReceived, userData: chatServer.userData);
    if (chatServer.onNewSocket?.call(chat, chatPeer.userData) ?? true) {
      this.chat = chat;
      chatServer.close();
      multicaster.close();
      listener.close();
      return true;
    } else {
      chat.close();
      return false;
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
  Message sendText(String text) {
    return chat.sendText(text);
  }
  @override
  UserData get userData => chat.userData;

  @override
  int get port => chat.port;

  @override
  void setMessageCallback(MessageCallback messageCallback) {
    chat.setMessageCallback(messageCallback);
  }
}