import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

Future<UserData> getUserData() async {
  final deviceId = await getDeviceId();
  return UserData(deviceId, 'Android smartphone');
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