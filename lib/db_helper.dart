import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._();
  static Database? _database;

  DBHelper._();

  factory DBHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'cards.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL UNIQUE,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT,
        folder_id INTEGER,
        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE
      );
    ''');

    await _insertInitialFoldersAndCards(db);
  }

  Future<void> _insertInitialFoldersAndCards(Database db) async {
    await _insertFolderIfNotExists(db, 'Hearts', [
      // Cards data for Hearts
    ]);
    await _insertFolderIfNotExists(db, 'Spades', [
      // Cards data for Spades
    ]);
    await _insertFolderIfNotExists(db, 'Diamonds', [
      // Cards data for Diamonds
    ]);
    await _insertFolderIfNotExists(db, 'Clubs', [
      // Cards data for Clubs
    ]);
  }

  Future<void> _insertFolderIfNotExists(
      Database db, String folderName, List<Map<String, String>> cards) async {
    List<Map<String, dynamic>> folder = await db
        .query('folders', where: 'folder_name = ?', whereArgs: [folderName]);

    if (folder.isEmpty) {
      int folderId = await db.insert('folders', {'folder_name': folderName});
      for (final card in cards) {
        await db.insert('cards', {
          'name': card['name'],
          'suit': folderName,
          'image_url': card['image_url'],
          'folder_id': folderId,
        });
      }
    }
  }

  // This is the missing insertCard method you were referring to
  Future<int> insertCard(
      String name, String suit, String imageUrl, int folderId) async {
    final db = await database;

    // Check how many cards are already in the folder
    List<Map<String, dynamic>> cardCount = await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );

    // If there are already 6 cards in the folder, return an error code (-1)
    if (cardCount.length >= 6) {
      return -1; // Error code to indicate the folder is full
    }

    // Otherwise, insert the card into the database
    return await db.insert('cards', {
      'name': name,
      'suit': suit,
      'image_url': imageUrl,
      'folder_id': folderId,
    });
  }

  Future<int> insertFolder(String folderName) async {
    final db = await database;

    // Check if folder exists
    List<Map<String, dynamic>> folder = await db.query(
      'folders',
      where: 'folder_name = ?',
      whereArgs: [folderName],
    );

    if (folder.isNotEmpty) {
      return folder.first['id'] as int; // Ensure we're returning an int
    }

    // If folder doesn't exist, create a new one and return its id
    return await db.insert('folders', {'folder_name': folderName});
  }

  Future<List<Map<String, dynamic>>> fetchFolders() async {
    final db = await database;
    return await db.query('folders');
  }

  Future<List<Map<String, dynamic>>> fetchCards(int folderId) async {
    final db = await database;
    return await db
        .query('cards', where: 'folder_id = ?', whereArgs: [folderId]);
  }

  Future<int> deleteCard(int id) async {
    final db = await database;
    return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteFolder(int folderId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cards', where: 'folder_id = ?', whereArgs: [folderId]);
      await txn.delete('folders', where: 'id = ?', whereArgs: [folderId]);
    });
  }
}
