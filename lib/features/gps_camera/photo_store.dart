import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';

/// Local photo metadata store. Owned by the gps-camera feature developer.
///
/// Photos stay on-device: this table records the file path plus the GPS
/// fix and capture time. No cloud upload.
class PhotoStore {
  PhotoStore._();
  static final PhotoStore instance = PhotoStore._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      p.join(dir.path, photoDbFileName),
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE photos('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'path TEXT NOT NULL, lat REAL NOT NULL, lng REAL NOT NULL, '
        'capturedAt TEXT NOT NULL)',
      ),
    );
    return _db!;
  }

  /// Insert one captured photo. Returns the row id.
  Future<int> insertPhoto({
    required String path,
    required double lat,
    required double lng,
    required DateTime capturedAt,
  }) async {
    final db = await database;
    return db.insert('photos', {
      'path': path,
      'lat': lat,
      'lng': lng,
      'capturedAt': capturedAt.toIso8601String(),
    });
  }

  /// All saved photos, newest first.
  Future<List<Map<String, Object?>>> listPhotos() async {
    final db = await database;
    return db.query('photos', orderBy: 'capturedAt DESC');
  }
}
