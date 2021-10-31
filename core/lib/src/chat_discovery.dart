import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'datagram.dart';
import 'model.dart';

// using IPv6 because multicast in Android only works with IpV6 addresses
final InternetAddress MULTICAST_GROUP_ADDRESS = InternetAddress('ff02::1');
final int PEER_DISCOVERY_PORT = 5001;

class ChatPeerMulticaster {

  // one socket per network interface
  final List<DatagramSocket> datagramSockets;
  List<ChatPeer> chatPeers = [];
  Timer? timer;

  static Future<ChatPeerMulticaster> newInstance(List<NetworkInterface> interfaces) async {
    List<DatagramSocket> sockets = [];
    for (var interface in interfaces) {
      sockets.add(await DatagramSocket.from(PEER_DISCOVERY_PORT, groupAddress: MULTICAST_GROUP_ADDRESS, networkInterface: interface));
    }
    return ChatPeerMulticaster(sockets);
  }

  ChatPeerMulticaster(this.datagramSockets);

  void start() {
    timer = Timer.periodic(Duration(seconds: 1), (t) => multicast());
  }

  void stop() {
    timer?.cancel();
    timer = null;
  }

  void multicast() {
    for (var datagramSocket in datagramSockets) {
      datagramSocket.multicastObject(chatPeers, MULTICAST_GROUP_ADDRESS, PEER_DISCOVERY_PORT);
    }
  }

  void close() {
    for (var datagramSocket in datagramSockets) {
      datagramSocket.close();
    }
  }
}

class ChatPeerListener {

  static Future<ChatPeerListener> newInstance(List<NetworkInterface> interfaces) async {
    List<DatagramSocket> sockets = [];
    for (var interface in interfaces) {
      sockets.add(await DatagramSocket.from(PEER_DISCOVERY_PORT, networkInterface: interface));
    }
    return ChatPeerListener(sockets);
  }

  final List<DatagramSocket> datagramSockets;

  ChatPeerListener(this.datagramSockets) {
    for (var datagramSocket in datagramSockets) {
      datagramSocket.joinGroup(MULTICAST_GROUP_ADDRESS);
    }
  }

  void listen(void Function(List<ChatPeer> chatPeer) onChatPeerDiscovered) {
    for (var datagramSocket in datagramSockets) {
      datagramSocket.listen((data) {
        try {
          Iterable l = jsonDecode(String.fromCharCodes(data));
          var chatPeers = List<ChatPeer>.from(l.map((model) => ChatPeer.fromJson(model)));
          onChatPeerDiscovered(chatPeers);
        } catch (e) {
          // ignore exception
        }
      });
    }
  }

  void close() {
    for (var datagramSocket in datagramSockets) {
      datagramSocket.close();
    }
  }
}