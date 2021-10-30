import 'dart:io';

import 'package:intl/intl.dart';

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
  return (await NetworkInterface.list(includeLoopback: false, includeLinkLocal: true))
  // we want the wifi network interface
      .where((nInterface) => nInterface.name == 'wlan0')
      .toList();
}

Future<NetworkInterface> getWifiNetworkInterface() async {
  return (await NetworkInterface.list(includeLoopback: false, includeLinkLocal: true))
  // we want the wifi network interface
      .where((nInterface) => nInterface.name == 'wlan0')
      .first;
}

// TODO rename it. It also works on Android
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

final _MONTH_FORMAT = DateFormat("MMM");

String formatDate(DateTime dateTime) {
  final now = DateTime.now();
  final yesterday = DateTime.now().subtract(Duration(days: 1));
  String time = _twoDigitsNumber(dateTime.hour) + ":" + _twoDigitsNumber(dateTime.minute);
  if (_isSameDay(dateTime, now)) {
    return _twoDigitsNumber(dateTime.hour) + ":" + _twoDigitsNumber(dateTime.minute);
  }
  String monthAndDay =  dateTime.day.toString() + " " + _MONTH_FORMAT.format(dateTime) + ".";
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