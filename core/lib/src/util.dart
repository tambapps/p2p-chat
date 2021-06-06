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