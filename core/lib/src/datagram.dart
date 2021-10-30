import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:p2p_chat_core/p2p_chat_core.dart';

/// class to send/receive datagrams. Also handles multicast
class DatagramSocket {

  final RawDatagramSocket datagramSocket;

  DatagramSocket(this.datagramSocket);

  static Future<DatagramSocket> from(int port, {InternetAddress? address, InternetAddress? groupAddress, required NetworkInterface networkInterface}) async {
    final socket = await RawDatagramSocket.bind(address ?? InternetAddress.anyIPv6, port);
    socket.readEventsEnabled = true;
    socket.setRawOption(RawSocketOption.fromInt(RawSocketOption.levelIPv6, RawSocketOption.IPv6MulticastInterface, networkInterface.index));
    if (groupAddress != null) {
      socket.joinMulticast(groupAddress);
    }
    return DatagramSocket(socket);
  }

  void joinGroup(InternetAddress address) {
    datagramSocket.joinMulticast(address);
  }

  void listen(void Function(Uint8List data) onData) {
    datagramSocket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = datagramSocket.receive();
        if (datagram != null) {
          onData(datagram.data);
        }
      }
    });
  }

  void multicastObject(Object object, InternetAddress address, int port) {
    multicastString(jsonEncode(object), address, port);
  }

  void multicastString(String data, InternetAddress address, int port) {
    multicast(data.codeUnits, address, port);
  }

  void multicast(List<int> buffer, InternetAddress address, int port) {
    datagramSocket.send(buffer, address, port);
  }

  void close() {
    datagramSocket.close();
  }
}