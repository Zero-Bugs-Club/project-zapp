import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'timetable_entry.dart';

abstract class TimetableRepository {
  Future<List<TimetableEntry>> load(String ownerId);
  Future<void> save(String ownerId, List<TimetableEntry> entries);
}

/// One atomic snapshot per authenticated user, shared by both role views.
class TimetableStore implements TimetableRepository {
  TimetableStore({DatabaseFactory? factory, this.databasePath})
    : _factory = factory ?? databaseFactory;
  final DatabaseFactory _factory;
  final String? databasePath;
  Future<Database>? _opening;
  Future<Database> _database() async {
    final pending = _opening;
    if (pending != null) return pending;
    final opening = _open();
    _opening = opening;
    try {
      return await opening;
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async => _factory.openDatabase(
    databasePath ??
        p.join(await _factory.getDatabasesPath(), 'zapp_timetables.db'),
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE timetables ('
          'owner_id TEXT PRIMARY KEY, snapshot TEXT NOT NULL)',
        );
      },
    ),
  );
  @override
  Future<List<TimetableEntry>> load(String ownerId) async {
    final db = await _database();
    final rows = await db.query(
      'timetables',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
    );
    if (rows.isEmpty) return [];
    final snapshot =
        jsonDecode(rows.first['snapshot'] as String) as Map<String, dynamic>;
    if (snapshot['schemaVersion'] != 1) {
      throw const FormatException('Unsupported timetable version');
    }
    return (snapshot['entries'] as List)
        .map(
          (entry) =>
              TimetableEntry.fromJson(Map<String, Object?>.from(entry as Map)),
        )
        .toList();
  }

  @override
  Future<void> save(String ownerId, List<TimetableEntry> entries) async {
    if (ownerId.isEmpty || entries.isEmpty) {
      throw ArgumentError('A user and a non-empty timetable are required');
    }
    final db = await _database();
    await db.transaction((txn) async {
      await txn.insert('timetables', {
        'owner_id': ownerId,
        'snapshot': jsonEncode({
          'schemaVersion': 1,
          'slotPattern': 'vellore-weekday-v1',
          'entries': entries.map((e) => e.toJson()).toList(),
        }),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> close() async {
    final pending = _opening;
    _opening = null;
    if (pending != null) await (await pending).close();
  }
}
