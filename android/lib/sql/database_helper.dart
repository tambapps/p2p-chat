

import 'package:p2p_chat_android/model/models.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  final Database db;

  DatabaseHelper(this.db);

  static Future<DatabaseHelper> newInstance() async {
    final database = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'p2p_chat_database.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          'CREATE TABLE users(id VARCHAR(255) PRIMARY KEY, name TEXT NOT NULL);' +
              'CREATE TABLE conversations(id INTEGER PRIMARY KEY AUTO_INCREMENT, name VARCHAR(255));' +
              'CREATE TABLE messages(id INTEGER PRIMARY KEY AUTO_INCREMENT, '
                  'user_id VARCHAR(255) NOT NULL,'
                  'type VARCHAR(32) NOT NULL,'
                  'data LONGBLOB NOT NULL,'
                  'sent_at DATETIME NOT NULL,'
                  'CONSTRAINT messages_fk_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE'
                  ');' +
              '',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    return DatabaseHelper(database);
  }

  Future<List<Conversation>> findAllConversations() async {
    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('conversations');

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return Conversation(maps[i]['id'], maps[i]['name']);
    });
  }
}