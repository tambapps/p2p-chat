import 'dart:io';

import 'package:p2p_chat_core/p2p_chat_core.dart';
import 'package:p2p_chat_core/src/chat_discovery.dart';
import 'package:p2p_chat_core/src/datagram.dart';
import 'package:test/test.dart';

Future<List<NetworkInterface>> getNetworkInterfaces() async {
  return NetworkInterface.list(includeLoopback: false, includeLinkLocal: true);
}

Future<NetworkInterface> getWifiNetworkInterface() async {
  List<NetworkInterface> interfaces = await getNetworkInterfaces();
  if (interfaces.length == 1) {
    return interfaces[1];
  }
  try {
    return interfaces.firstWhere((nInterface) => nInterface.name == 'wlan0');
  } catch (e) {
    return interfaces[1];
  }
}

Future<List<InternetAddress>> getDesktopAddresses() async {
  return (await getWifiNetworkInterface()).addresses;
}

Future<InternetAddress> getDesktopIpAddress() async {
  final addresses = await getDesktopAddresses();
  if (addresses.isEmpty) {
    throw StateError("Couldn't find IP address");
  }
  // didn't find any better way to choose when there are several IPs
  return addresses[0];
}

void main() {
  group('A group of tests', () {

    setUp(() {
      // Additional setup goes here.
    });

    test('Test multicast Test', () async {
      var multicaster = await ChatPeerMulticaster.newInstance(await NetworkInterface.list(includeLoopback: false, includeLinkLocal: true, type: InternetAddressType.IPv6));
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
