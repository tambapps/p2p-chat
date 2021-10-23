import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

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