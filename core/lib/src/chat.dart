import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:p2p_chat_core/src/connection/connection.dart';
import 'package:p2p_chat_core/src/network.dart';
import 'connection/websocket_connection.dart';
import 'util.dart';

import 'chat_automation.dart';
import 'chat_discovery.dart';
import 'model.dart';

/// class used to store keys per user id
/// This will be useful to verify user identity (prevent identity theft)
class UserKeyStore {
  final Map<String, String> _userKeys = HashMap();

  void put(UserData userData, String key) {
    _userKeys[userData.id] = key;
  }

  bool verify(UserData userData, String key) {
    var userKey = _userKeys[userData.id];
    return userKey != null && userKey == key;
  }
}

/// base class for a chat
abstract class Chat {

  /// Maps the user id -> key
  /// Used to verify user and therefore prevent identity theft
  @protected
  UserKeyStore userKeyStore = UserKeyStore();

  /// Sends the [text] message to the other peer
  Message sendText(String text) {
    final message = VerifiedMessage(address.address, userData, text, DateTime.now(), key);
    sendMessage(message);
    return message;
  }

  /// Sends the [message] to the other peer
  void sendMessage(VerifiedMessage message) {
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
  // the key is the address
  String get key;
  int get port;
}

typedef MessageCallback = void Function(Message message);
typedef ConnectionDoneCallback = void Function(UserData? userData);
typedef ConnectionErrorCallback = void Function(Object exception, UserData? userData);

/// return false if user should be filtered
typedef ChatConnectionCallback = bool Function(Chat chat, UserData data);

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
  // for the server, the key is the address. The client won't perform any verification anyway
  @override
  String get key => address.address;

  Function? onServerError;
  ConnectionErrorCallback? onConnectionError;
  void Function()? onServerDone;
  ConnectionDoneCallback? onConnectionDone;
  Set<UserData> connectedUsers = HashSet();

  ChatPeer get chatPeer => ChatPeer.from(address, PeerType.SERVER, port, userData);

  ChatServer(this.server, this.onMessageReceived, {this.onNewSocket, this.userData = ANONYMOUS_USER, this.onServerError, this.onConnectionError, this.onServerDone, this.onConnectionDone});

  static Future<ChatServer> from(NetworkProvider networkProvider, MessageCallback onMessageReceived,
      {ChatConnectionCallback? onNewSocket, UserData userData = ANONYMOUS_USER, Function? onServerError,
        ConnectionErrorCallback? onConnectionError, void Function()? onServerDone, ConnectionDoneCallback? onConnectionDone}) async {
    final server = await WebSocketServer.from(await networkProvider.getIpAddress(), ChatServer.PORT);
    return ChatServer(server, onMessageReceived, onNewSocket: onNewSocket, userData: userData, onServerError: onServerError, onServerDone: onServerDone, onConnectionDone: onConnectionDone, onConnectionError: onConnectionError);
  }

  void start() {
    server.listen((final connection) {
      final automaton = ChatServerAutomaton(onMessageReceived,
              (chat, handshakeData) => _automatonOnNewSocket(connection, chat, handshakeData),
          userKeyStore);
      connection.automaton = automaton;
      connection.listen((bytes) => automaton.act(this, bytes), onError: (e) => _doOnConnectionError(e, automaton.user), onDone: () => _doOnConnectionDone(automaton.user));
    }, onError: _doOnServerError, onDone: _doOnServerDone);
  }

  // useful because onServerError is not final, same for below functions
  void _doOnServerError(e) {
    if (onServerError != null) {
      onServerError!(e);
    }
  }

  void _doOnServerDone() {
    if (onServerDone != null) {
      onServerDone!();
    }
  }

  void _doOnConnectionError(e, UserData? user) {
    if (onConnectionError != null) {
      onConnectionError!(e, user);
    }
    connectedUsers.remove(user);
  }

  void _doOnConnectionDone(UserData? user) {
    if (onConnectionDone != null) {
      onConnectionDone!(user);
    }
    connectedUsers.remove(user);
  }

  /// automaton callback to know if it must put
  bool _automatonOnNewSocket(Connection connection, Chat chat, HandshakeData handshakeData) {
    if (connectedUsers.add(handshakeData.userData) && (onNewSocket == null || onNewSocket!(chat, handshakeData.userData))) {
      userKeyStore.put(handshakeData.userData, handshakeData.key);
      connections.add(connection);
      return true;
    } else {
      connection.close();
      return false;
    }
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
  // I wanted to use UUID but I have to import a dependency for that. FLEMME
  @override
  final String key = Random().nextDouble().toString();

  Function? onError;
  void Function()? onDone;

  @override
  UserData userData;

  /// [address] must be the String address, or the InternetAddress
  static Future<ChatClient> from(addressArg,
      MessageCallback onMessageReceived, {Function? onError, void Function()? onDone, UserData userData = ANONYMOUS_USER}) async {
    var address = await toAddress(addressArg);
    var port = ChatServer.PORT;

    final connection = await WebSocketConnection.from(address, port);
    return ChatClient(connection, onMessageReceived, onError: onError, onDone: onDone, userData: userData);
  }

  ChatClient(this.connection, MessageCallback onMessageReceived,
      {Function? onError, void Function()? onDone, this.userData = ANONYMOUS_USER}) {
    automaton = ChatClientAutomaton(onMessageReceived);
    // sending handshake data
    // using the IP as key
    connection.sendText(jsonEncode(HandshakeData(userData, key)));
    connection.listen((bytes) => automaton.act(this, bytes), onError: _doOnError, onDone: _doOnDone);
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

  void _doOnError(e) {
    if (onError != null) {
      onError!(e);
    }
  }

  void _doOnDone() {
    if (onDone != null) {
      onDone!();
    }
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
  @override
  String get key => chat.key;
  Set<UserData> get connectedUsers => chatServer.connectedUsers;

  final ConnectionErrorCallback? onConnectionError;
  final ConnectionDoneCallback? onConnectionDone;

  static Future<SmartChat> from(NetworkProvider networkProvider, MessageCallback onMessageReceived,
      {ChatConnectionCallback? onNewSocket, PeerType peerType = PeerType.ANY, UserData userData = ANONYMOUS_USER,
        Function? onServerError, ConnectionErrorCallback? onConnectionError, Function()? onServerDone, ConnectionDoneCallback? onConnectionDone}) async {
    final multicastInterfaces = await networkProvider.listMulticastNetworkInterfaces();
    final multicaster = await ChatPeerMulticaster.newInstance(multicastInterfaces);
    final listener = await ChatPeerListener.newInstance(multicastInterfaces);
    final server = await ChatServer.from(networkProvider, onMessageReceived, userData: userData, onNewSocket: (chat, data) {
      if (onNewSocket == null || onNewSocket(chat, data)) {
        multicaster.close();
        listener.close();
        return true;
      }
      return false;
    }, onServerError: onServerError, onServerDone: onServerDone, onConnectionError: onConnectionError, onConnectionDone: onConnectionDone);

    // the chat is the server by default, if it will be overridden by a client chat
    // if one chat peer is found
    return SmartChat(peerType, onMessageReceived, server, server, multicaster, listener);
  }

  SmartChat(this.peerType, this.onMessageReceived, this.chatServer, this.chat, this.multicaster, this.listener,
  {this.onConnectionError, this.onConnectionDone});

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
    Chat chat = await ChatClient.from(chatPeer.internetAddress, onMessageReceived, userData: chatServer.userData,
        onError: onConnectionError != null ? (e) => onConnectionError!(e, null) : null,
        onDone: onConnectionDone != null ? () => onConnectionDone!(null) : null);
    if (connectedUsers.add(chatPeer.userData) && (chatServer.onNewSocket?.call(chat, chatPeer.userData) ?? true)) {
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
  void sendMessage(VerifiedMessage message) {
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