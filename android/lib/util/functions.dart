import 'dart:io';

import 'package:device_info/device_info.dart';

Future<String> getDeviceName() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  // prefixing IDs to avoid ID collision
  String name = '';
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    name = androidInfo.manufacturer + " " + androidInfo.model;
  } else {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    if (iosInfo.name.isNotEmpty && iosInfo.model.isNotEmpty) {
      name = iosInfo.name + " " + iosInfo.model;
    }
  }
  if (name.isEmpty) {
    return "Me";
  }
  return name;
}

Future<String> getDeviceId() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  // prefixing IDs to avoid ID collision
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return 'android_' + androidInfo.androidId;
  } else {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return 'ios_' + iosInfo.identifierForVendor;
  }
}

const String APP_NAME = "P2P Messenger";