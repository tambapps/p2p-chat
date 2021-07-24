import 'dart:typed_data';

import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  final Database db;

  DatabaseHelper(this.db);

  static void createDatabases(Database db) async {
    db.execute('CREATE TABLE users(id VARCHAR(255) PRIMARY KEY, name TEXT NOT NULL)');
    db.execute('CREATE TABLE conversations(id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'name VARCHAR(255),'
    // id of the user with which the conversation started
        'main_user_id VARCHAR(255) NOT NULL,'
        'CONSTRAINT conversations_fk_user_id FOREIGN KEY (main_user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE'
        ')');
    db.execute('CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT,'
            'conversation_id INTEGER NOT NULL,'
            'user_id VARCHAR(255) NOT NULL,'
            'type VARCHAR(32) NOT NULL,'
            'data LONGBLOB NOT NULL,'
            'sent_at VARCHAR(32) NOT NULL,'
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
      return Conversation(maps[i]['id'], maps[i]['name'], maps[i]['main_user_id']);
    });
  }

  Future<Conversation> insertNewConversation(String name, String userId) async {
    int id = await db.insert('conversations', {
      'name': name,
      'main_user_id': userId
    });
    return Conversation(id, name, userId);
  }

  Future<DatabaseMessage> insertNewMessage(int conversationId, UserData userData, MessageType type, Uint8List data, DateTime sentAt) async {
    await _updateOrCreateUser(userData);
    int id = await db.insert('messages', {
      'conversation_id': conversationId,
      'user_id': userData.id,
      'type': type.toString(),
      'data': data,
      'sent_at': sentAt.toString(),
    });
    return DatabaseMessage(id, conversationId, userData.id, type, data, sentAt);
  }

  Future<UserData?> findUserById(String id) async {
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) {
      return null;
    }
    return UserData(maps[0]['id'], maps[0]['name']);

  }
  Future<void> _updateOrCreateUser(UserData userData) async {
    final user = await findUserById(userData.id);
    if (user == null) {
      await createUser(userData);
    } else if (user.username != userData.username) {
      await updateUser(userData);
    }
  }

  Future<void> createUser(UserData userData) async {
    await db.insert('users', {
      'id': userData.id,
      'name': userData.username,
    });
  }

  Future<void> updateUser(UserData userData) async {
    await db.update('users',
        {
          'name': userData.username
        },
    where: 'id = ?',
    whereArgs: [userData.id]
    );
  }
}