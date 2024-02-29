import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import './membar.dart';

class MembarDatabaseHelper {
  static Database? _database;
  static const String tableName = 'membars';

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'membar_database.db');
    return openDatabase(
      path,
      version: 1, // Increment the version number to trigger an update
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            shopName TEXT,
            memo TEXT,
            date TEXT,
            color INT,
            branchName TEXT,
            userName TEXT,
            barcodeData TEXT,
            picPath TEXT,
            tapCount INT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Handle migrations when upgrading database version
        // You can add more migration logic for different versions if needed
      },
    );
  }

  Future<int> insertMembar(Membar membar) async {
    final db = await database;
    return await db.insert(tableName, membar.toMap());
  }

  Future<int> updateTapCount(int id, int newTapCount) async {
    final db = await database;
    return await db.update(
      tableName,
      {'tapCount': newTapCount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMembar(int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id],);
  }

  Future<List<Membar>> getMembars() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return Membar(
        id: maps[i]['id'],
        shopName: maps[i]['shopName'],
        memo: maps[i]['memo'],
        date: maps[i]['date'],
        color: maps[i]['color'],
        branchName: maps[i]['branchName'],
        userName: maps[i]['userName'],
        barcodeData: maps[i]['barcodeData'],
        picPath: maps[i]['picPath'],
        tapCount: maps[i]['tapCount']
      );
    });
  }
}
