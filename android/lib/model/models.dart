

import 'dart:typed_data';

import 'package:p2p_chat_android/sql/database_helper.dart';

class Context {
  final DatabaseHelper dbHelper;

  Context(this.dbHelper);

}

// UserData
class Conversation {
  int id;
  String? name;

  Conversation(this.id, this.name);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

enum MessageType {
  TEXT, IMAGE, AUDIO
}

// to avoid conflict with p2p_core Message
class DatabaseMessage {
  int id;
  int conversationId;
  String userId;
  MessageType type;
  Uint8List data;
  DateTime sentAt;

  DatabaseMessage(this.id, this.conversationId, this.userId, this.type, this.data, this.sentAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'type': type.toString(),
      'data': data,
      'sent_at': sentAt,
    };
  }

  DatabaseMessage.fromMap(Map map)
      : this(map['id'], map['user_id'], map['conversation_id'], fromString(map['type']), map['data'], map['sent_at']);

  static MessageType fromString(String t) {
    switch (t) {
      case "IMAGE":
        return MessageType.IMAGE;
      case "AUDIO":
        return MessageType.AUDIO;
      default:
        return MessageType.TEXT;
    }
  }
}
