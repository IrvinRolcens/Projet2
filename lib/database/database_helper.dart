import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'todo_tasks.db';
  static const _databaseVersion = 2;

  static const table = 'tasks';
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnDetails = 'details';
  static const columnStatus = 'status';
  static const columnCreatedAt = 'createdAt';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
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
      version: _databaseVersion + 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table(
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnDetails TEXT,
        $columnStatus INTEGER NOT NULL,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertTask(Task task) async {
    Database db = await instance.database;
    return await db.insert(table, task.toMap());
  }

  Future<int> updateTask(Task task) async {
    Database db = await instance.database;
    return await db.update(
      table,
      task.toMap(),
      where: '$columnId = ?',
      whereArgs: [task.id],
    );
  }

  Future<List<Task>> getAllTasks() async {
    Database db = await instance.database;
    var result = await db.query(table);
    return result.isNotEmpty
        ? result.map((task) => Task.fromMap(task)).toList()
        : [];
  }

  Future<int> deleteTask(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<Task>> getTasksByStatus(int status) async {
    Database db = await instance.database;
    var result = await db.query(
      table,
      where: '$columnStatus = ?',
      whereArgs: [status],
    );
    return result.isNotEmpty
        ? result.map((task) => Task.fromMap(task)).toList()
        : [];
  }
}

class Task {
  final int? id;
  final String title;
  final String? details;
  final int status;
  final String createdAt;

  Task({
    this.id,
    required this.title,
    this.details,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'details': details,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      details: map['details'],
      status: map['status'],
      createdAt: map['createdAt'],
    );
  }
}
