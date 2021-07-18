import 'dart:typed_data';

import 'package:p2p_chat_android/model/models.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  final Database db;

  DatabaseHelper(this.db);

  static void createDatabases(Database db) async {
    db.execute('CREATE TABLE users(id VARCHAR(255) PRIMARY KEY, name TEXT NOT NULL)');
    db.execute('CREATE TABLE conversations(id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(255))');
    db.execute('CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT,'
            'conversation_id INTEGER NOT NULL,'
            'user_id VARCHAR(255) NOT NULL,'
            'type VARCHAR(32) NOT NULL,'
            'data LONGBLOB NOT NULL,'
            'sent_at DATETIME NOT NULL,'
            'CONSTRAINT messages_fk_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,'
            'CONSTRAINT messages_fk_conversation_id FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE ON UPDATE CASCADE'
            ')');
  }

  static Future<DatabaseHelper> newInstance() async {
    final databasePath = join(await getDatabasesPath(), 'p2p_chat_database.db');
    // use the following line in case schema changes
    // deleteDatabase(databasePath);
    final database = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      databasePath,
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return createDatabases(db);
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    return DatabaseHelper(database);
  }

  Future<List<Conversation>> findAllConversations() async {
    final List<Map<String, dynamic>> maps = await db.query('conversations');
    return List.generate(maps.length, (i) {
      return Conversation(maps[i]['id'], maps[i]['name']);
    });
  }

  Future<Conversation> insertNewConversation() async {
    int id = await db.insert('conversations', {});
    return Conversation(id, null);
  }

  Future<DatabaseMessage> insertNewMessage(int conversationId, String userId, MessageType type, Uint8List data, DateTime sentAt) async {
    int id = await db.insert('conversations', {
      'conversation_id': conversationId,
      'user_id': userId,
      'type': type.toString(),
      'data': data,
      'sent_at': sentAt,
    });
    return DatabaseMessage(id, conversationId, userId, type, data, sentAt);
  }
}