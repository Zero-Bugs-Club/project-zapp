// Tests stay within the assigned feature folder; flutter_test is a dev dependency.
// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../timetable_parser.dart';
import '../timetable_store.dart';
import 'timetable_parser_test.dart' show exampleTable;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.tekartik.sqflite');
  final snapshots = <String, String>{};
  final sqlLog = <String>[];
  Map<String, String>? transaction;
  var failInsert = false;
  var version = 0;
  late TimetableStore store;

  setUp(() {
    snapshots.clear();
    sqlLog.clear();
    transaction = null;
    failInsert = false;
    version = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = (call.arguments as Map?) ?? {};
          final sql = args['sql'] as String? ?? '';
          sqlLog.add(sql);
          switch (call.method) {
            case 'getDatabasesPath':
              return 'C:/tmp';
            case 'openDatabase':
              return {'id': 1};
            case 'closeDatabase':
              return null;
            case 'query':
              if (sql == 'PRAGMA user_version') {
                return [
                  {'user_version': version},
                ];
              }
              final owner = (args['arguments'] as List).single as String;
              final value = snapshots[owner];
              return value == null
                  ? []
                  : [
                      {'snapshot': value},
                    ];
            case 'execute':
              if (sql.startsWith('BEGIN')) {
                transaction = Map.of(snapshots);
                return {'transactionId': 1};
              }
              if (sql == 'COMMIT') {
                snapshots
                  ..clear()
                  ..addAll(transaction!);
                transaction = null;
              } else if (sql == 'ROLLBACK') {
                transaction = null;
              } else if (sql.startsWith('PRAGMA user_version = ')) {
                version = int.parse(sql.split(' ').last);
              }
              return null;
            case 'insert':
              if (failInsert) {
                throw PlatformException(
                  code: 'sqlite_error',
                  message: 'disk full',
                );
              }
              final values = args['arguments'] as List;
              transaction![values[0] as String] = values[1] as String;
              return 1;
            default:
              throw StateError('Unexpected database call: ${call.method}');
          }
        });
    store = TimetableStore(
      factory: databaseFactorySqflitePlugin,
      databasePath: 'timetable-storage-test.db',
    );
  });
  tearDown(() async {
    await store.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'sqflite snapshot survives reopening, replaces and isolates owners',
    () async {
      final entries = previewVitTable(exampleTable).entries;
      await store.save('alice', entries);
      await store.save('bob', [entries.last]);
      await store.close();
      expect(
        (await store.load('alice')).map((e) => e.toJson()).toList(),
        entries.map((e) => e.toJson()).toList(),
      );
      expect(await store.load('bob'), hasLength(1));
      expect(await store.load('unknown'), isEmpty);
      await store.save('alice', [entries.first]);
      expect(await store.load('alice'), hasLength(1));
      expect(
        sqlLog.any((sql) => sql.startsWith('CREATE TABLE timetables')),
        isTrue,
      );
      expect(sqlLog.any((sql) => sql.startsWith('INSERT OR REPLACE')), isTrue);
    },
  );
  test(
    'sqflite rolls back failed replacement and preserves prior snapshot',
    () async {
      final entries = previewVitTable(exampleTable).entries;
      await store.save('alice', entries);
      failInsert = true;
      await expectLater(
        store.save('alice', [entries.first]),
        throwsA(isA<DatabaseException>()),
      );
      expect(await store.load('alice'), hasLength(5));
      expect(sqlLog, contains('ROLLBACK'));
    },
  );
}
