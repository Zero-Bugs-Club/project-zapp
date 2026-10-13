import '../../core/models/timetable_slot.dart';

/// Represents a single course registration row from VTOP
/// containing clearly separated values.
class CourseRegistration {
  final String courseCode;
  final String courseName;
  final String slot;
  final String venue;
  final String facultyName;

  const CourseRegistration({
    required this.courseCode,
    required this.courseName,
    required this.slot,
    required this.venue,
    required this.facultyName,
  });

  Map<String, dynamic> toMap() => {
    'courseCode': courseCode,
    'courseName': courseName,
    'slot': slot,
    'venue': venue,
    'facultyName': facultyName,
  };

  factory CourseRegistration.fromMap(Map<String, dynamic> map) => CourseRegistration(
    courseCode: map['courseCode'] as String? ?? '',
    courseName: map['courseName'] as String? ?? '',
    slot: map['slot'] as String? ?? 'NIL',
    venue: map['venue'] as String? ?? 'NIL',
    facultyName: map['facultyName'] as String? ?? 'Unknown',
  );
}

/// Feature-owned details; the shared API model remains source-compatible.
class TimetableEntry extends TimetableSlot {
  final String courseCode;
  final String teacher;
  final String venue;
  final String? registrationSlot;

  const TimetableEntry({
    required super.day,
    required super.slotCode,
    required super.course,
    required super.startTime,
    required super.endTime,
    required this.courseCode,
    required this.teacher,
    required this.venue,
    this.registrationSlot,
  });

  /// User-friendly alias for `course` (the course name).
  String get courseName => course;

  /// User-friendly alias for `teacher` (the faculty name).
  String get facultyName => teacher;

  int get startMinute => minutes(startTime);
  int get endMinute => minutes(endTime);
  static int minutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Map<String, Object?> toJson() => {
    'day': day,
    'slotCode': slotCode,
    'course': course,
    'courseCode': courseCode,
    'teacher': teacher,
    'venue': venue,
    'startTime': startTime,
    'endTime': endTime,
    if (registrationSlot != null) 'registrationSlot': registrationSlot,
  };

  factory TimetableEntry.fromJson(Map<String, Object?> json) => TimetableEntry(
    day: json['day'] as int,
    slotCode: json['slotCode'] as String,
    course: cleanCourseName(json['course'] as String? ?? ''),
    startTime: json['startTime'] as String,
    endTime: json['endTime'] as String,
    courseCode: (json['courseCode'] as String? ?? '').toUpperCase(),
    teacher: cleanFacultyName(json['teacher'] as String? ?? ''),
    venue: cleanVenue(json['venue'] as String? ?? ''),
    registrationSlot: json['registrationSlot'] as String?,
  );
}

/// Strips VTOP metadata suffixes from a raw course title string.
String cleanCourseName(String raw) {
  var name = raw.trim();
  // Strip "( Theory Only )", "( Lab Only )", etc.
  name = name.replaceFirst(
    RegExp(
      r'\s*\(?\s*(?:Theory|Lab|Embedded|Project|Soft(?:ware)?)\s+(?:Only|and)\b.*',
      caseSensitive: false,
    ),
    '',
  );
  // Strip VTOP credit numbers: "3 1 0 0 4.0"
  name = name.replaceFirst(
    RegExp(r'\s+\d+\s+\d+\s+\d+\s+\d+\s+[\d.]+.*'),
    '',
  );
  // Strip VTOP class-group ID like "CH2026..." or "VL2026..."
  name = name.replaceFirst(
    RegExp(r'\s+(?:CH|VL)\d{4,}.*', caseSensitive: false),
    '',
  );
  // Strip leaked slot tokens (e.g. "A1+TA1...", "L31+L32")
  name = name.replaceFirst(
    RegExp(
      r'\s+(?:[A-G][12]|T[A-Z]{1,3}[12]|L\d{1,3}|V\d)(?:\s*\+|\s*-|$).*',
      caseSensitive: false,
    ),
    '',
  );
  // Strip common VTOP category keywords
  name = name.replaceFirst(
    RegExp(
      r'\s+(?:Professional|University|Regular|Core|Elective|Programme)\b.*',
      caseSensitive: false,
    ),
    '',
  );
  // Strip trailing dashes, whitespace
  name = name.replaceFirst(RegExp(r'[\s\-]+$'), '');
  return name.trim();
}

/// Cleans raw faculty string by removing school abbreviations or trailing dashes.
String cleanFacultyName(String raw) {
  var faculty = raw.trim();
  faculty = faculty.replaceFirst(
    RegExp(
      r'\s*-\s*(?:SCOPE|SITE|SENSE|SELECT|SAS|SSL|SCHEME|SMEC|SCALE|VITSOL|HOTEL|FASHION|LAW|AGRICULTURE|[A-Z]{3,6})\b.*$',
      caseSensitive: false,
    ),
    '',
  );
  faculty = faculty.replaceFirst(RegExp(r'\s*-\s*$'), '');
  return faculty.trim();
}

/// Cleans raw venue string.
String cleanVenue(String raw) {
  var venue = raw.trim().toUpperCase();
  venue = venue.replaceFirst(RegExp(r'\s*-\s*$'), '');
  return venue.isEmpty ? 'NIL' : venue;
}
