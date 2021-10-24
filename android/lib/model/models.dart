

import 'dart:typed_data';

import 'package:p2p_chat_android/sql/database_helper.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

class Context {
  final DatabaseHelper dbHelper;
  UserData userData;

  Context(this.dbHelper, this.userData);

}

// UserData
class Conversation {
  final int id;
  final String? name;
  final String mainUserId;

  const Conversation(this.id, this.name, this.mainUserId);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'main_user_id': mainUserId
    };
  }

  Conversation copyWith({String? name}) {
    return Conversation(id, name ?? this.name, mainUserId);
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

  factory DatabaseMessage.fromRow(Map<String, dynamic> data) {
    return DatabaseMessage(data['id'], data['conversation_id'], data['user_id'],
        MessageType.values.firstWhere((element) => element.toString().toLowerCase() == data['type'].toString().toLowerCase()),
        data['data'], DateTime.parse(data['sent_at']));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'type': type.toString(),
      'data': data.toString(),
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
