// Tests stay within the assigned feature folder; flutter_test is a dev dependency.
// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/models/user.dart';
import '../../auth/auth_provider.dart';
import '../timetable_entry.dart';
import '../timetable_parser.dart';
import '../timetable_screen.dart';
import '../timetable_store.dart';
import 'timetable_parser_test.dart' show exampleTable;

class MemoryRepository implements TimetableRepository {
  List<TimetableEntry> entries = previewVitTable(exampleTable).entries;
  bool fail = false;
  @override
  Future<List<TimetableEntry>> load(String ownerId) async => entries;
  @override
  Future<void> save(String ownerId, List<TimetableEntry> entries) async {
    if (fail) throw StateError('Storage unavailable');
    this.entries = entries;
  }
}

Future<void> openTimetable(
  WidgetTester tester,
  MemoryRepository repo, {
  bool admin = false,
  double width = 390,
  double height = 1200,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(
          AppUser(
            id: 'student',
            username: 'Student',
            role: admin ? UserRole.admin : UserRole.user,
          ),
        ),
        timetableRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
        builder: (context, child) => RepaintBoundary(
          key: const ValueKey('timetable-preview'),
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
        home: const TimetableScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'student selects all seven vertical days and opens class details',
    (tester) async {
      await openTimetable(tester, MemoryRepository());
      await tester.scrollUntilVisible(
        find.text('Sun'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sun'));
      await tester.pumpAndSettle();
      expect(find.text('No classes scheduled.'), findsOneWidget);
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View class details').first);
      await tester.pumpAndSettle();
      expect(find.text('Dr Ada'), findsOneWidget);
      expect(find.text('Faculty'), findsOneWidget);
      expect(find.text('Venue'), findsOneWidget);
      await tester.tap(find.byTooltip('Close details'));
      await tester.pumpAndSettle();
      expect(find.text('Faculty'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('admin renders one local upload in theory/lab grid', (
    tester,
  ) async {
    await openTimetable(tester, MemoryRepository(), admin: true);
    await tester.scrollUntilVisible(
      find.text('LOCAL TIMETABLE'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('Mon\nTheory'), findsOneWidget);
    expect(find.text('Sun\nLab'), findsOneWidget);
    await tester.tap(find.text('BMAT101L\nSJT101').first);
    await tester.pumpAndSettle();
    expect(find.text('Dr Ada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('preview must be accepted; save failure preserves saved data', (
    tester,
  ) async {
    final repo = MemoryRepository()..fail = true;
    await openTimetable(tester, repo);
    await tester.enterText(find.byType(TextField), exampleTable);
    await tester.tap(find.text('Preview timetable'));
    await tester.pumpAndSettle();
    expect(find.text('5 weekly class periods found'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save timetable'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save timetable'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save.'), findsOneWidget);
    expect(repo.entries, hasLength(5));
    repo.fail = false;
    await tester.tap(find.text('Save timetable'));
    await tester.pumpAndSettle();
    expect(find.text('Timetable saved on this device.'), findsOneWidget);
    expect(find.text('Save timetable'), findsNothing);
  });
  testWidgets('narrow screen and enlarged text do not overflow', (
    tester,
  ) async {
    await openTimetable(tester, MemoryRepository(), width: 320, scale: 1.5);
    await tester.scrollUntilVisible(
      find.text('Sun'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
