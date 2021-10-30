import 'dart:io';

import 'package:p2p_chat_core/p2p_chat_core.dart';
import 'package:p2p_chat_core/src/chat_discovery.dart';
import 'package:p2p_chat_core/src/datagram.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {

    setUp(() {
      // Additional setup goes here.
    });

    test('Test multicast Test', () async {
      var multicaster = await ChatPeerMulticaster.newInstance();
      multicaster.chatPeers = [
        ChatPeer.from(InternetAddress.loopbackIPv4, PeerType.ANY, PEER_DISCOVERY_PORT, UserData('sisi', 'sisi')),
        ChatPeer.from(InternetAddress.loopbackIPv4, PeerType.SERVER, PEER_DISCOVERY_PORT, UserData('soso', 'sisi'))
      ];

      multicaster.start();
      await Future.delayed(Duration(seconds: 60));
      multicaster.close();

    });

    test('Test receive', () async {
      var chatPeerListener = ChatPeerListener([DatagramSocket(await RawDatagramSocket.bind(await getDesktopIpAddress(), 0))]);
      chatPeerListener.listen((chatPeer) {
        print(chatPeer);
      });
      await Future.delayed(Duration(seconds: 60));
    });
  });
}
