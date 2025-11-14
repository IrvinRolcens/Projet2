import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {
  static const _databaseName = 'user_data.db';
  static const _databaseVersion = 1;

  static const table = 'users';
  static const columnId = 'id';
  static const columnUsername = 'username';
  static const columnPassword = 'password';

  DatabaseManager._privateConstructor();
  static final DatabaseManager instance = DatabaseManager._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    var path = await getDatabasesPath();
    var databasePath = join(path, _databaseName);
    return await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnUsername TEXT NOT NULL,
        $columnPassword TEXT NOT NULL
      )
    ''');
  }

  // Insérer un nouvel utilisateur
  Future<int> insertUser(String username, String password) async {
    Database db = await instance.database;
    var result = await db.insert(table, {
      columnUsername: username,
      columnPassword: password,
    });
    return result;
  }

  // Vérifier les identifiants de l'utilisateur
  Future<Map<String, dynamic>?> getUser(
    String username,
    String password,
  ) async {
    Database db = await instance.database;
    var result = await db.query(
      table,
      where: '$columnUsername = ? AND $columnPassword = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}
