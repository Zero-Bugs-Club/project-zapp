// Tests stay within the assigned feature folder; flutter_test is a dev dependency.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'timetable_screen_test.dart' show MemoryRepository, openTimetable;

void main() {
  const output = String.fromEnvironment('TIMETABLE_PREVIEW_DIR');
  testWidgets('export representative timetable renders for visual review', (
    tester,
  ) async {
    final config = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    ) as Map;
    final sdk = Directory.fromUri(Uri.parse(config['flutterRoot'] as String));
    final loader = FontLoader('Roboto');
    for (final style in ['regular', 'bold', 'medium']) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '${sdk.path}/bin/cache/artifacts/material_fonts/roboto-$style.ttf',
            ).readAsBytesSync(),
          ),
        ),
      );
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '${sdk.path}/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('timetable-preview')),
      );
      await tester.runAsync(() async {
        final rendered = await boundary.toImage(pixelRatio: 2);
        final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File('$output/$name.png').writeAsBytes(png!.buffer.asUint8List());
        rendered.dispose();
      });
    }

    await openTimetable(tester, MemoryRepository(), height: 844);
    await capture('import');
    await tester.scrollUntilVisible(
      find.text('Sun'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await capture('student');
    await tester.tap(find.text('View class details').first);
    await capture('class-details');
    await tester.tap(find.byTooltip('Close details'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await openTimetable(tester, MemoryRepository(), admin: true, height: 844);
    await tester.scrollUntilVisible(
      find.text('Fri\nLab'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await capture('admin-grid');
    expect(tester.takeException(), isNull);
  }, skip: output.isEmpty);
}
