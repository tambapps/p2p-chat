import 'dart:io';

Future<InternetAddress> toAddress(address) async {
  if (address == null) {
    throw ArgumentError('address cannot be null');
  }
  if (address is InternetAddress) {
    return address;
  } else {
    var addresses = await InternetAddress.lookup(address);
    if (addresses.isEmpty) {
      throw ArgumentError('address $address was not found');
    } else {
      return addresses[0];
    }
  }
}

/// doesn't work on android according to https://stackoverflow.com/questions/52411168/how-to-get-device-ip-in-dart-flutter
/// use WifiFlutter instead for android
// TODO improve me like in fandem
// TODO also work on android so just rename it getIpAddress
Future<InternetAddress> getDesktopIpAddress() async {
  final addresses = (await NetworkInterface.list(includeLoopback: false, includeLinkLocal: true))
      .expand((interface) => interface.addresses).toList(growable: false);
  if (addresses.isEmpty) {
    throw StateError("Couldn't find IP address");
  }
  // didn't find any better way to choose when there are several IPs
  return addresses[0];
}