import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseController {
  static final DatabaseController instance = DatabaseController._privateConstructor();
  //?-exist
  static Database? _database;

  DatabaseController._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'guide_me_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_data (
        id INTEGER PRIMARY KEY,
        name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tag_names (
        id INTEGER PRIMARY KEY,
        name TEXT,
        key_word Text
      )
    ''');
  }

  Future<int> insertData(String tableName, Map<String, dynamic> data) async {
    Database db = await instance.database;
    return await db.insert(tableName, data);
  }

  Future<List<Map<String, dynamic>>> getData(String tableName) async {
    Database db = await instance.database;
    return await db.query(tableName);
  }

  Future<int> insertTagName(String name) async {
    Database db = await instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tag_names (
        id INTEGER PRIMARY KEY,
        name TEXT,
        key_word Text
      )
    ''');
    Map<String, dynamic> row = {
      'name': name,
      'key_word': name,
    };
    return await db.insert('tag_names', row);
  }

  Future<List<Map<String, dynamic>>> getTagNames() async {
    Database db = await instance.database;
    return await db.query('tag_names');
  }

  Future<void> deleteTagName(String tagName) async {
    final db = await database;
    await db.delete(
      'tag_names',
      where: 'name = ?',
      whereArgs: [tagName],
    );
  }

  Future<void> deleteAllTagNames() async {
    final db = await database;
    await db.delete('tag_names');
  }

  Future<void> updateUserData(int id, String name, String value) async {
    final db = await instance.database;

    await db.update(
      'user_data',
      {
        'name': name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}
