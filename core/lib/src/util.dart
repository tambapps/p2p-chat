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

Future<List<NetworkInterface>> getNetworkInterfaces() async {
  return NetworkInterface.list(includeLoopback: false, includeLinkLocal: true);
}

Future<NetworkInterface> getWifiNetworkInterface() async {
  List<NetworkInterface> interfaces = await getNetworkInterfaces();
  print(interfaces.map((e) => e.name));
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

/// doesn't work on android according to https://stackoverflow.com/questions/52411168/how-to-get-device-ip-in-dart-flutter
/// use WifiFlutter instead for android
// TODO improve me like in fandem. also work on android (?) so just rename it getIpAddress
Future<InternetAddress> getDesktopIpAddress() async {
  final addresses = await getDesktopAddresses();
  if (addresses.isEmpty) {
    throw StateError("Couldn't find IP address");
  }
  // didn't find any better way to choose when there are several IPs
  return addresses[0];
}

String formatMonth(int month) {
  switch (month) {
    case 1:
      return 'Jan';
    case 2:
      return 'Feb';
    case 3:
      return 'Mar';
    case 4:
      return 'Apr';
    case 5:
      return 'May';
    case 6:
      return 'Jun';
    case 7:
      return 'Jul';
    case 8:
      return 'Aug';
    case 9:
      return 'Sep';
    case 10:
      return 'Oct';
    case 11:
      return 'Nov';
    case 12:
      return 'Dec';
    default:
      return '???';
  }
}

String formatDate(DateTime dateTime) {
  final now = DateTime.now();
  String time = _twoDigitsNumber(dateTime.hour) + ":" + _twoDigitsNumber(dateTime.minute);
  if (_isSameDay(dateTime, now)) {
    return _twoDigitsNumber(dateTime.hour) + ":" + _twoDigitsNumber(dateTime.minute);
  }
  String monthAndDay =  dateTime.day.toString() + " " + formatMonth(dateTime.month) + ".";
  if (_isSameYear(dateTime, now)) {
    return monthAndDay + " " + time;
  }
  return monthAndDay + " " + dateTime.year.toString() + ", " + time;
}

String _twoDigitsNumber(int n) {
  return n < 10 ? "0" + n.toString() : n.toString();
}

bool _isSameDay(DateTime d1, DateTime d2) {
  return d1.day == d2.day && d1.month == d1.month && d1.year == d2.year;
}

bool _isSameYear(DateTime d1, DateTime d2) {
  return d1.year == d2.year;
}