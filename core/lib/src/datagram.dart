import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:p2p_chat_core/p2p_chat_core.dart';

/// class to send/receive datagrams. Also handles multicast
class DatagramSocket {

  final RawDatagramSocket datagramSocket;

  DatagramSocket(this.datagramSocket);

  static Future<DatagramSocket> from(int port, {InternetAddress? groupAddress}) async {
    final socket = await RawDatagramSocket.bind(InternetAddressType.any, port);
    if (groupAddress != null) {
      socket.joinMulticast(groupAddress);
    }
    return DatagramSocket(socket);
  }

  void listen(void Function(Uint8List event) onData) {
    datagramSocket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = datagramSocket.receive();
        if (datagram != null) {
          onData(datagram.data);
        }
      }
    });
  }

  void multicastObject(Object object, Peer peer) {
    multicastString(jsonEncode(object), peer);
  }

  void multicastString(String data, Peer peer) {
    multicast(data.codeUnits, peer);
  }

  void multicast(List<int> buffer, Peer peer) {
    datagramSocket.send(buffer, peer.address, peer.port);
  }

  void close() {
    datagramSocket.close();
  }
}