
import 'dart:io';

abstract class NetworkProvider {

  Future<List<NetworkInterface>> listMulticastNetworkInterfaces();

  Future<InternetAddress> getIpAddress();

}