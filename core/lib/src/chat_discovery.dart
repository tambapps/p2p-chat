
// will contain ChatDirector, a class making handshake and deciding who should be
// the sender peer


import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:p2p_chat_core/p2p_chat_core.dart';
import 'package:p2p_chat_core/src/datagram.dart';

// TODO use another one because fandom uses same
final InternetAddress MULTICAST_GROUP_ADDRESS = InternetAddress('ff02::1');
final int PEER_DISCOVERY_PORT = 5001;


class ChatPeerMulticaster {

  final DatagramSocket datagramSocket;
  List<ChatPeer> chatPeers = [];
  Timer? timer;

  static Future<ChatPeerMulticaster> newInstance() async {
    return ChatPeerMulticaster(await DatagramSocket.newInstance());
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
    print('object');
    datagramSocket.multicastObject(chatPeers, MULTICAST_GROUP_ADDRESS, PEER_DISCOVERY_PORT);
  }

  void close() {
    datagramSocket.close();
  }
}

class ChatPeerListener {

  final DatagramSocket datagramSocket;

  ChatPeerListener(this.datagramSocket);

  void listen(void Function(ChatPeer chatPeer) onChatPeerDiscovered) {
    datagramSocket.listen((data) {
      try {
        onChatPeerDiscovered(ChatPeer.fromJson(jsonDecode(String.fromCharCodes(data))));
      } catch (e) {
        // ignore exception
      }
    });
  }

  void close() {
    datagramSocket.close();
  }
}