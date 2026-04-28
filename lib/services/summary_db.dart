import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SummaryDb {
  static Database? _db;

  static Future<Database> get _instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = join(await getDatabasesPath(), 'ai_summaries.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE summaries (
          game_id    TEXT PRIMARY KEY,
          status     TEXT NOT NULL DEFAULT 'idle',
          content    TEXT,
          created_at INTEGER NOT NULL
        )
      '''),
    );
  }

  static Future<Map<String, dynamic>?> get(String gameId) async {
    final rows = await (await _instance).query(
      'summaries',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  static Future<void> save(String gameId, String status, {String? content}) async {
    await (await _instance).insert(
      'summaries',
      {
        'game_id': gameId,
        'status': status,
        'content': content,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
