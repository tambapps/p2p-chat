import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';
// annotation allowing code auto-generation
// run 'dart run build_runner build' to auto-generate code
// TODO store key in messages. It will be given by the server when connecting,
// (should be different for each user) and it will verify for each incoming messages
@JsonSerializable()
class Message {

  String address;
  UserData userData;
  String text;
  DateTime sentAt;

  Message(this.address, this.userData, this.text, this.sentAt);

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

// TODO remove client
enum PeerType {
  SERVER, CLIENT, ANY
}

@JsonSerializable()
class ChatPeer {

  final String address;
  final PeerType type;
  final int? port;


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatPeer &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          type == other.type &&
          port == other.port;

  @override
  int get hashCode => address.hashCode ^ type.hashCode ^ port.hashCode;

  factory ChatPeer.fromJson(Map<String, dynamic> json) => _$ChatPeerFromJson(json);

  Map<String, dynamic> toJson() => _$ChatPeerToJson(this);

  ChatPeer.from(InternetAddress address, PeerType type, int port) : this(address.address, type, port);
  ChatPeer(this.address, this.type, this.port);

  InternetAddress get internetAddress {
    return InternetAddress(address);
  }

}