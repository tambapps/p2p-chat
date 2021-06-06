import 'dart:io';

InternetAddress toAddress(address) {
  if (address == null) {
    throw ArgumentError('address cannot be null');
  }
  if (address is InternetAddress) {
    return address;
  } else {
    var maybeAddress = InternetAddress.tryParse(address);
    if (maybeAddress == null) {
      throw ArgumentError('address $address is malformed');
    } else {
      return maybeAddress;
    }
  }
}