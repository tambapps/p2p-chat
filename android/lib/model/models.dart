

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
class DMessage {


}
