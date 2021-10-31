import 'dart:io';

import 'package:p2p_chat_core/p2p_chat_core.dart';

import 'constants.dart';

class AndroidNetworkProvider extends NetworkProvider {

  @override
  Future<InternetAddress> getIpAddress() async {
    print((await _listNetworkInterfaces())
        .firstWhere((nInterface) => nInterface.name.startsWith('w'))
        .addresses);
    return (await _listNetworkInterfaces())
        // get the wifi network interface. Should be 'wlan0'
        .firstWhere((nInterface) => nInterface.name.startsWith('w'))
        .addresses
        // using IPv4. YES.
        .firstWhere((address) => address.type == InternetAddressType.IPv4);
  }

  @override
  Future<List<NetworkInterface>> listMulticastNetworkInterfaces() async {
    return (await _listNetworkInterfaces())
        .where((nInterface) => nInterface.supportsMulticast)
        .toList();
  }

  Future<List<_AndroidNetworkInterface>> _listNetworkInterfaces() async {
    List maps = (await androidMethodChannel.invokeListMethod("listNetworkInterfaces"))!;
    List<_AndroidNetworkInterface> result = [];
    for (var map in maps) {
      result.add(await _AndroidNetworkInterface.fromMap(map));
    }
    return result;
  }
}

class _AndroidNetworkInterface extends NetworkInterface {

  static fromMap(Map<dynamic, dynamic> map) async {
    List stringAddresses = map['addresses'] as List;
    List<InternetAddress> addresses = [];
    for (var string in stringAddresses) {
      addresses.add(await toAddress(string));
    }
    return _AndroidNetworkInterface(map['name'], map['index'], map['supportsMulticast'],
        addresses);
  }

  @override
  final String name;
  @override
  final int index;
  final bool supportsMulticast;
  @override
  final List<InternetAddress> addresses;

  _AndroidNetworkInterface(this.name, this.index, this.supportsMulticast, this.addresses);

}