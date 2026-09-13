import '../../core/models/timetable_slot.dart';
import '../../core/vit_slot_grid.dart';

/// Parser for the pasted VIT course registration table.
/// Owned by the timetable feature developer.
///
/// Input: raw pasted text whose rows contain a slot/venue cell such as
///   "A1+TA1 - AB3-405"  (one or more slot codes joined by '+').
/// Output: one [TimetableSlot] per recognised slot code, timed via
/// [vitSlotGrid]. Unknown codes are skipped.
List<TimetableSlot> parseVitTable(
  String rawText, {
  String courseFallback = '',
}) {
  // Matches codes like A1, TA1, L11. Case-insensitive; normalised to upper.
  final codeExp = RegExp(r'\b([A-Z]{1,2}\d{1,2})\b', caseSensitive: false);
  final slots = <TimetableSlot>[];
  for (final line in rawText.split('\n')) {
    final course = _courseFromLine(line, courseFallback);
    for (final m in codeExp.allMatches(line)) {
      final code = m.group(1)!.toUpperCase();
      final grid = vitSlotGrid[code];
      if (grid == null) {
        continue; // Unknown code: skip, do not fail the row.
      }
      slots.add(
        TimetableSlot(
          day: grid.$1,
          slotCode: code,
          course: course,
          startTime: grid.$2,
          endTime: grid.$3,
        ),
      );
    }
  }
  return slots;
}

// First non-slot, non-venue token on the line is treated as the course name.
String _courseFromLine(String line, String fallback) {
  for (final token in line.split(RegExp(r'\s{2,}|\t|\|'))) {
    final t = token.trim();
    if (t.isEmpty) continue;
    if (t.contains('-') &&
        RegExp(r'[A-Z]+\d', caseSensitive: false).hasMatch(t)) {
      continue; // Slot/venue cell.
    }
    if (RegExp(r'^[A-Z]{1,3}\d{3,4}$', caseSensitive: false).hasMatch(t)) {
      continue;
    }
    return t;
  }
  return fallback;
}
