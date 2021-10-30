import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

// annotation allowing code auto-generation
// run the following command to auto-generate code
// dart run build_runner build
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
class VerifiedMessage extends Message {
  // used to verify user identity. Not used yet
  String key;

  VerifiedMessage(String address, UserData userData, String text, DateTime sentAt, this.key) : super(address, userData, text, sentAt);

  factory VerifiedMessage.fromJson(Map<String, dynamic> json) => _$VerifiedMessageFromJson(json);

  Map<String, dynamic> toJson() => _$VerifiedMessageToJson(this);

}

const ANONYMOUS_USER = UserData('anonymous', 'anonymous');
@JsonSerializable()
class UserData {
  final String username;
  final String id;
  const UserData(this.id, this.username);

  factory UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataToJson(this);

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is UserData && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  UserData copyWithUsername(String username) {
    return UserData(id, username);
  }
}

@JsonSerializable()
class HandshakeData {
  final UserData userData;
  /// will be used to verify user identity
  final String key;

  HandshakeData(this.userData, this.key);

  factory HandshakeData.fromJson(Map<String, dynamic> json) => _$HandshakeDataFromJson(json);

  Map<String, dynamic> toJson() => _$HandshakeDataToJson(this);

}


class Peer {
  final InternetAddress address;
  final int port;

  Peer(this.address, this.port);

}

enum PeerType {
  SERVER, ANY
}

@JsonSerializable()
class ChatPeer {

  ChatPeer.from(InternetAddress address, PeerType type, int port, UserData userData) : this(address.address, type, port, userData);

  ChatPeer(this.address, this.type, this.port, this.userData);

  final String address;
  final PeerType type;
  final int? port;
  final UserData userData;

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

  InternetAddress get internetAddress {
    return InternetAddress(address);
  }

}