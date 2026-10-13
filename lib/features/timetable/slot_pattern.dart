/// Vellore weekday FFCS pattern. Do not use for another campus/slot revision.
/// Source and limitations: README.md in this feature directory.
typedef SlotTime = (int day, String start, String end);

const theoryRows = [
  ['A1', 'F1', 'D1', 'TB1', 'TG1', '', 'A2', 'F2', 'D2', 'TB2', 'TG2', 'V3'],
  ['B1', 'G1', 'E1', 'TC1', 'TAA1', '', 'B2', 'G2', 'E2', 'TC2', 'TAA2', 'V4'],
  ['C1', 'A1', 'F1', 'V1', 'V2', '', 'C2', 'A2', 'F2', 'TD2', 'TBB2', 'V5'],
  ['D1', 'B1', 'G1', 'TE1', 'TCC1', '', 'D2', 'B2', 'G2', 'TE2', 'TCC2', 'V6'],
  ['E1', 'C1', 'TA1', 'TF1', 'TD1', '', 'E2', 'C2', 'TA2', 'TF2', 'TDD2', 'V7'],
];
const theoryStarts = [
  '08:00',
  '09:00',
  '10:00',
  '11:00',
  '12:00',
  '',
  '14:00',
  '15:00',
  '16:00',
  '17:00',
  '18:00',
  '19:00',
];
const theoryEnds = [
  '08:50',
  '09:50',
  '10:50',
  '11:50',
  '12:50',
  '',
  '14:50',
  '15:50',
  '16:50',
  '17:50',
  '18:50',
  '19:50',
];
const labStarts = [
  '08:00',
  '08:46',
  '10:00',
  '10:46',
  '11:31',
  '12:16',
  '14:00',
  '14:46',
  '16:00',
  '16:46',
  '17:31',
  '18:16',
];
const labEnds = [
  '08:45',
  '09:30',
  '10:45',
  '11:30',
  '12:15',
  '13:00',
  '14:45',
  '15:30',
  '16:45',
  '17:30',
  '18:15',
  '19:00',
];

String labCode(int day, int column) =>
    'L${(column < 6 ? 0 : 30) + (day - 1) * 6 + column % 6 + 1}';
final Map<String, List<SlotTime>> timetablePattern = _buildPattern();
Map<String, List<SlotTime>> _buildPattern() {
  final result = <String, List<SlotTime>>{};
  for (var day = 1; day <= 5; day++) {
    for (var column = 0; column < 12; column++) {
      final theory = theoryRows[day - 1][column];
      if (theory.isNotEmpty) {
        result.putIfAbsent(theory, () => []).add((
          day,
          theoryStarts[column],
          theoryEnds[column],
        ));
      }
      result[labCode(day, column)] = [
        (day, labStarts[column], labEnds[column]),
      ];
    }
  }
  // Common aliases in VTOP tables
  result.putIfAbsent('TDD1', () => []).add((5, '12:00', '12:50'));
  result.putIfAbsent('TBB1', () => []).add((3, '12:00', '12:50'));
  return result;
}
