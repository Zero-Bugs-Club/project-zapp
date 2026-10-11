import 'slot_pattern.dart';
import 'timetable_entry.dart';

class TimetableParseResult {
  final List<TimetableEntry> entries;
  final List<String> errors;
  const TimetableParseResult(this.entries, this.errors);
  bool get canSave => entries.isNotEmpty && errors.isEmpty;
}

/// Parses multi-line block format or tab/pipe-delimited VTOP registration text.
///
/// Converts raw registration data into cleanly separated [CourseRegistration] records:
/// - [CourseRegistration.courseCode]
/// - [CourseRegistration.courseName]
/// - [CourseRegistration.slot]
/// - [CourseRegistration.venue]
/// - [CourseRegistration.facultyName]
///
/// Then validates and maps each slot to day/time [TimetableEntry] items.
TimetableParseResult previewVitTable(String rawText) {
  if (rawText.trim().isEmpty) {
    return const TimetableParseResult(
      [],
      ['No classes found. Copy the VTOP course table including its column headings.'],
    );
  }

  final errors = <String>[];
  final seen = <String>{};
  final entries = <TimetableEntry>[];

  // 1. Try block-based registration parser (multi-line VTOP blocks)
  var registrations = parseRegistrationBlocks(rawText);

  // 2. If no blocks found, use tabular parser (TSV / pipe-delimited)
  if (registrations.isEmpty) {
    registrations = parseRegistrationTable(rawText, errors);
  }

  // 3. Map slot to day/time entries
  for (var index = 0; index < registrations.length; index++) {
    final reg = registrations[index];
    if (reg.courseCode.isEmpty || reg.courseName.isEmpty || reg.slot.isEmpty) {
      errors.add('Line ${index + 1}: missing course or readable slot/venue columns.');
      continue;
    }
    if (reg.facultyName.isEmpty || reg.venue.isEmpty) {
      errors.add('Line ${index + 1}: missing faculty or venue. Include these columns.');
      continue;
    }

    final slotTokens = reg.slot
        .split('+')
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty && s != 'NIL');

    for (final slotCode in slotTokens) {
      final times = timetablePattern[slotCode];
      if (times == null) {
        errors.add('Line ${index + 1}: unsupported slot $slotCode. Saved data is unchanged.');
        continue;
      }
      for (final time in times) {
        final entry = TimetableEntry(
          day: time.$1,
          slotCode: slotCode,
          course: reg.courseName,
          startTime: time.$2,
          endTime: time.$3,
          courseCode: reg.courseCode,
          teacher: reg.facultyName,
          venue: reg.venue,
          registrationSlot: reg.slot,
        );
        final key = '${entry.day}|${entry.slotCode}|${entry.startTime}|${entry.endTime}|${entry.courseCode}|${entry.venue}';
        if (seen.add(key)) {
          entries.add(entry);
        }
      }
    }
  }

  entries.sort((a, b) {
    final day = a.day.compareTo(b.day);
    return day != 0 ? day : a.startTime.compareTo(b.startTime);
  });

  if (entries.isEmpty && errors.isEmpty) {
    errors.add('No classes found. Copy the VTOP course table including its column headings.');
  }

  return TimetableParseResult(
    List.unmodifiable(entries),
    List.unmodifiable(errors),
  );
}

/// Parses multi-line VTOP registration blocks (where each course starts with "CODE - Name").
List<CourseRegistration> parseRegistrationBlocks(String input) {
  final headerRegex = RegExp(
    r'^(?:\d+\s+)?([A-Z]{2,}\d{3,}[A-Z]?)\s*-\s*(\S.*)$',
    caseSensitive: false,
  );
  final slotRegex = RegExp(
    r'^(NIL|[A-G][12]|T[A-Z]{1,3}[12]|L\d{1,3}|V\d{1,2}|(?:[A-G][12]|T[A-Z]{1,3}[12]|L\d{1,3}|V\d{1,2})(?:\s*\+\s*(?:[A-G][12]|T[A-Z]{1,3}[12]|L\d{1,3}|V\d{1,2}))*)\s*(?:-\s*(.*))?$',
    caseSensitive: false,
  );
  final dateRegex = RegExp(r'^\d{1,2}-[A-Za-z]{3}-\d{4}');

  final lines = input
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\u00a0', ' ')
      .split('\n')
      .map((l) => l.trim())
      .toList();

  final starts = <int>[];
  for (var i = 0; i < lines.length; i++) {
    // Only treat as block header if not containing tabs or pipes (which indicate a table row)
    if (!lines[i].contains('\t') && !lines[i].contains('|') && headerRegex.hasMatch(lines[i])) {
      starts.add(i);
    }
  }

  if (starts.isEmpty) return const [];

  final registrations = <CourseRegistration>[];
  for (var h = 0; h < starts.length; h++) {
    final start = starts[h];
    final end = h + 1 < starts.length ? starts[h + 1] : lines.length;
    final headMatch = headerRegex.firstMatch(lines[start])!;
    final courseCode = headMatch.group(1)!.trim().toUpperCase();
    final rawName = headMatch.group(2)!.trim();
    final courseName = cleanCourseName(rawName);

    final blockLines = lines.sublist(start + 1, end).where((l) => l.isNotEmpty).toList();

    String slot = '';
    String venue = '';
    String faculty = '';

    int slotLineIndex = -1;
    for (var i = 0; i < blockLines.length; i++) {
      final line = blockLines[i];
      final m = slotRegex.firstMatch(line);
      if (m != null) {
        slot = m.group(1)!.trim().toUpperCase();
        slotLineIndex = i;
        final candidateVenue = m.group(2)?.trim() ?? '';
        if (candidateVenue.isNotEmpty && candidateVenue != 'NIL' && candidateVenue != '-') {
          venue = cleanVenue(candidateVenue);
        }
        break;
      }
    }

    if (slotLineIndex >= 0) {
      var nextIdx = slotLineIndex + 1;
      // If venue was not on the slot line, look at the next line
      if (venue.isEmpty && nextIdx < blockLines.length) {
        final candidate = blockLines[nextIdx].replaceAll(RegExp(r'\s*-\s*$'), '').trim();
        if (candidate.isNotEmpty && !dateRegex.hasMatch(candidate) && !slotRegex.hasMatch(candidate)) {
          venue = cleanVenue(candidate);
          nextIdx++;
        }
      }
      // Next line after venue is the faculty
      if (nextIdx < blockLines.length) {
        final candidate = blockLines[nextIdx].trim();
        if (candidate.isNotEmpty && !dateRegex.hasMatch(candidate) && !slotRegex.hasMatch(candidate)) {
          faculty = cleanFacultyName(candidate);
        }
      }
    }

    if (slot.isNotEmpty && slot != 'NIL') {
      registrations.add(CourseRegistration(
        courseCode: courseCode,
        courseName: courseName,
        slot: slot,
        venue: venue.isEmpty ? 'NIL' : venue,
        facultyName: faculty.isEmpty ? 'Unknown' : faculty,
      ));
    }
  }

  return registrations;
}

/// Parses tabular VTOP rows (TSV, pipe-delimited, multiple spaces).
List<CourseRegistration> parseRegistrationTable(String rawText, List<String> errors) {
  final registrations = <CourseRegistration>[];
  Map<String, int>? header;
  final lines = rawText.replaceAll('\r', '').split('\n');

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty || RegExp(r'^[| :\-]+$').hasMatch(line)) continue;

    final cells = line
        .split(RegExp(r'\t|\|| {2,}'))
        .map((s) => s.trim())
        .toList();
    if (line.startsWith('|')) cells.removeAt(0);
    if (line.endsWith('|')) cells.removeLast();

    final names = cells.map(_headerName).toList();
    if (names.contains('courseCode') && names.contains('slot')) {
      header = {for (var i = 0; i < names.length; i++) names[i]: i};
      continue;
    }

    final courseIndex = cells.indexWhere(
      (s) => RegExp(
        r'^[A-Z]{2,5}\d{3,4}[A-Z]?$',
        caseSensitive: false,
      ).hasMatch(s),
    );

    if (courseIndex < 0) {
      if (RegExp(
        r'\b(?:[A-G][12]|T[A-Z]{1,2}[12]|L\d{1,3})\b',
        caseSensitive: false,
      ).hasMatch(line)) {
        errors.add('Line ${index + 1}: copy the full course row with columns.');
      }
      continue;
    }

    String value(String key) {
      final column = header?[key];
      return column != null && column < cells.length ? cells[column] : '';
    }

    var code = value('courseCode');
    var course = value('course');
    var slotCell = value('slot');
    var teacher = value('teacher');
    var venue = value('venue');

    if (header == null) {
      code = cells[courseIndex];
      course = courseIndex + 1 < cells.length ? cells[courseIndex + 1] : '';
      final slotIndex = cells.indexWhere(
        (s) => RegExp(
          r'^(?:[A-G][12]|T[A-Z]{1,2}[12]|L\d{1,3}|V\d)(?:\s*\+|\s*-|$)',
          caseSensitive: false,
        ).hasMatch(s),
      );
      if (slotIndex >= 0) {
        slotCell = cells[slotIndex];
        teacher = slotIndex + 1 < cells.length ? cells[slotIndex + 1] : '';
      }
    }

    final slotMatch = RegExp(
      r'^([A-Z]+\d+(?:\s*\+\s*[A-Z]+\d+)*)(?:\s*-\s*(.+))?$',
      caseSensitive: false,
    ).firstMatch(slotCell);

    if (venue.isEmpty && slotMatch?.group(2) != null) {
      venue = slotMatch!.group(2)!;
    }

    if (code.isEmpty || course.isEmpty || slotMatch == null) {
      errors.add('Line ${index + 1}: missing course or readable slot/venue columns.');
      continue;
    }
    if (teacher.isEmpty || venue.isEmpty) {
      errors.add('Line ${index + 1}: missing faculty or venue. Include these columns.');
      continue;
    }

    final cleanCode = code.toUpperCase();
    final cleanName = cleanCourseName(course);
    final cleanFaculty = cleanFacultyName(teacher);
    final cleanVen = cleanVenue(venue);
    final slotString = slotMatch.group(1)!.replaceAll(RegExp(r'\s+'), '').toUpperCase();

    registrations.add(CourseRegistration(
      courseCode: cleanCode,
      courseName: cleanName,
      slot: slotString,
      venue: cleanVen,
      facultyName: cleanFaculty,
    ));
  }

  return registrations;
}

String _headerName(String value) {
  final name = value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  return switch (name) {
    'coursecode' => 'courseCode',
    'coursetitle' || 'coursename' || 'course' => 'course',
    'slot' || 'slots' || 'slotvenue' || 'slotandvenue' => 'slot',
    'faculty' || 'facultyname' || 'teacher' || 'teachername' => 'teacher',
    'venue' || 'room' => 'venue',
    _ => name,
  };
}

/// Compatibility entry point. Partial results never become a saved timetable.
List<TimetableEntry> parseVitTable(
  String rawText, {
  String courseFallback = '',
}) {
  final result = previewVitTable(rawText);
  return result.canSave ? result.entries : const [];
}
