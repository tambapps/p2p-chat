import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:udp/udp.dart';

import 'datagram.dart';
import 'model.dart';

// using IPv6 because multicast in Android only works with IpV6 addresses
final InternetAddress MULTICAST_GROUP_ADDRESS = InternetAddress('ff02::1');
final int PEER_DISCOVERY_PORT = 5001;

class ChatPeerMulticaster {

  // one socket per network interface
  final UDP datagramSockets;
  List<ChatPeer> chatPeers = [];
  Timer? timer;

  static Future<ChatPeerMulticaster> newInstance(List<NetworkInterface> interfaces) async {
    var sender = await UDP.bind(Endpoint.any());

    return ChatPeerMulticaster(sender);
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
    var multicastEndpoint =
    Endpoint.multicast(MULTICAST_GROUP_ADDRESS, port: Port(PEER_DISCOVERY_PORT));
    datagramSockets.send(jsonEncode(chatPeers).codeUnits, multicastEndpoint);
  }

  void close() {
    datagramSockets.close();
  }
}

class ChatPeerListener {

  static Future<ChatPeerListener> newInstance(List<NetworkInterface> interfaces) async {
    var receiver = await UDP.bind(Endpoint.any());

    return ChatPeerListener(receiver);
  }

  final UDP datagramSockets;

  ChatPeerListener(this.datagramSockets) {
  }

  void listen(void Function(List<ChatPeer> chatPeer) onChatPeerDiscovered) {
    datagramSockets.asStream().listen((datagram) {
      if (datagram != null) {
        var str = String.fromCharCodes(datagram.data);

        try {
          Iterable l = jsonDecode(str);
          var chatPeers = List<ChatPeer>.from(l.map((model) => ChatPeer.fromJson(model)));
          onChatPeerDiscovered(chatPeers);
        } catch (e) {
          // ignore exception
        }
      }
    });
  }

  void close() {
    datagramSockets.close();
  }
}