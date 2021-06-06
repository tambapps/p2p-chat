import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';
// annotation allowing code auto-generation
// run 'dart run build_runner build' to auto-generate code
@JsonSerializable()
class Message {

  String text;
  DateTime sentAt;

  Message(this.text, this.sentAt);

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

}
@JsonSerializable()
class UserData {
  final String username;
 const UserData(this.username);

  factory UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}

class Peer {
  final InternetAddress address;
  final int port;

  Peer(this.address, this.port);

}