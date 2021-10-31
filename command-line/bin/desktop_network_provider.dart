import 'dart:io';

import 'package:p2p_chat_core/p2p_chat_core.dart';

class DesktopNetworkProvider extends NetworkProvider {

  final InternetAddress? _address;

  DesktopNetworkProvider(this._address);

  @override
  Future<InternetAddress> getIpAddress() async {
    if (this._address != null) {
      return _address!;
    }
    NetworkInterface interface = await _getPublicIpNetworkInterfaces();
    return interface.addresses.first;
  }

  Future<NetworkInterface> _getPublicIpNetworkInterfaces() async {
    List<NetworkInterface> interfaces =
    await NetworkInterface.list(includeLoopback: false, includeLinkLocal: true);
    if (interfaces.length == 1) {
      return interfaces[1];
    }
    try {
      return interfaces
          .where((nInterface) => !nInterface.name.contains('docker'))
          .firstWhere((nInterface) => nInterface.name.startsWith('w'));
    } catch (e) {
      return interfaces[0];
    }
  }
  @override
  Future<List<NetworkInterface>> listMulticastNetworkInterfaces() async {
    return await NetworkInterface.list(includeLoopback: false, includeLinkLocal: true, type: InternetAddressType.IPv6);
  }

}