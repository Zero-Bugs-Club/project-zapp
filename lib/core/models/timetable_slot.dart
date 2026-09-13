/// Shared timetable entry used by both the user view and the admin view.
///
/// [day] uses DateTime weekday numbers: 1 = Monday … 7 = Sunday.
/// [slotCode] is the VIT slot code, e.g. "A1", "TA1", "L11".
/// [startTime]/[endTime] are "HH:mm" strings taken from [vitSlotGrid].
class TimetableSlot {
  final int day;
  final String slotCode;
  final String course;
  final String startTime;
  final String endTime;

  const TimetableSlot({
    required this.day,
    required this.slotCode,
    required this.course,
    required this.startTime,
    required this.endTime,
  });
}
