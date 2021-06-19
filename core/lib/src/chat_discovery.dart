
// will contain ChatDirector, a class making handshake and deciding who should be
// the sender peer


import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:p2p_chat_core/p2p_chat_core.dart';
import 'package:p2p_chat_core/src/datagram.dart';

final InternetAddress MULTICAST_GROUP_ADDRESS = InternetAddress('224.0.0.8');
final int PEER_DISCOVERY_PORT = 5001;


class ChatPeerMulticaster {

  final DatagramSocket datagramSocket;
  List<ChatPeer> chatPeers = [];
  Timer? timer;

  static Future<ChatPeerMulticaster> newInstance() async {
    return ChatPeerMulticaster(await DatagramSocket.from(PEER_DISCOVERY_PORT,
        address: await getDesktopIpAddress(), groupAddress: MULTICAST_GROUP_ADDRESS));
  }

  ChatPeerMulticaster(this.datagramSocket);

  void start() {
    timer = Timer.periodic(Duration(seconds: 1), (t) => multicast());
  }

  void stop() {
    timer?.cancel();
    timer = null;
  }

  void multicast() {
    datagramSocket.multicastObject(chatPeers, MULTICAST_GROUP_ADDRESS, PEER_DISCOVERY_PORT);
  }

  void close() {
    datagramSocket.close();
  }
}

class ChatPeerListener {

  static Future<ChatPeerListener> newInstance() async {
    var datagramSocket = await DatagramSocket.from(PEER_DISCOVERY_PORT);
    return ChatPeerListener(datagramSocket);
  }

  final DatagramSocket datagramSocket;

  ChatPeerListener(this.datagramSocket) {
    datagramSocket.joinGroup(MULTICAST_GROUP_ADDRESS);
  }

  void listen(void Function(List<ChatPeer> chatPeer) onChatPeerDiscovered) {
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

  void close() {
    datagramSocket.close();
  }
}