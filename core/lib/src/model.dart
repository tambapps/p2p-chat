import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

// auto-generated file (see below how)
part 'model.g.dart';
// annotation allowing code auto-generation
// run 'dart pub run build_runner build' to auto-generate code
@JsonSerializable()
class Message {

  String text;
  DateTime sentAt;

  Message(this.text, this.sentAt);

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

}


class Peer {
  final InternetAddress address;
  final int port;

  Peer(this.address, this.port);

}