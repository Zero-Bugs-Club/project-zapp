/// Static VIT slot-to-time grid.
///
/// Each entry maps a slot code to (weekday, start, end).
/// Weekday uses DateTime numbers: 1 = Monday … 5 = Friday.
/// Theory slots run Mon–Fri; lab slots (L1–L60) are paired hours.
///
/// This grid is fixed and does not change per semester. If the official
/// slot table is revised, update this map only — the parser and both
/// timetable views read from here.
const Map<String, (int day, String start, String end)> vitSlotGrid = {
  // Morning theory block.
  'A1': (1, '08:00', '08:50'),
  'B1': (2, '08:00', '08:50'),
  'C1': (3, '08:00', '08:50'),
  'D1': (4, '08:00', '08:50'),
  'E1': (5, '08:00', '08:50'),
  'F1': (1, '09:00', '09:50'),
  'G1': (2, '09:00', '09:50'),
  // Evening theory block.
  'A2': (1, '14:00', '14:50'),
  'B2': (2, '14:00', '14:50'),
  'C2': (3, '14:00', '14:50'),
  'D2': (4, '14:00', '14:50'),
  'E2': (5, '14:00', '14:50'),
  'F2': (1, '15:00', '15:50'),
  'G2': (2, '15:00', '15:50'),
  // Extra (TA/TB/…) theory hours.
  'TA1': (1, '18:01', '18:50'),
  'TB1': (2, '18:01', '18:50'),
  'TC1': (3, '18:01', '18:50'),
  'TA2': (4, '18:01', '18:50'),
  'TB2': (5, '18:01', '18:50'),
  // Representative lab pairs (extend to L1–L60 as needed).
  'L1': (1, '08:00', '09:40'),
  'L2': (1, '09:50', '11:30'),
  'L11': (2, '08:00', '09:40'),
  'L21': (3, '08:00', '09:40'),
  'L31': (4, '08:00', '09:40'),
  'L41': (5, '08:00', '09:40'),
};
