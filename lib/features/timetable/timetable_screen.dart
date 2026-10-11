import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import 'slot_pattern.dart';
import 'timetable_entry.dart';
import 'timetable_parser.dart';
import 'timetable_schedule_view.dart';
import 'timetable_store.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final store = TimetableStore();
  ref.onDispose(store.close);
  return store;
});

final _savedTimetableProvider = FutureProvider.autoDispose
    .family<List<TimetableEntry>, String>(
      (ref, ownerId) => ref.watch(timetableRepositoryProvider).load(ownerId),
    );

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  final _paste = TextEditingController();
  bool _saving = false;
  bool _forceImportView = false;
  String? _message;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  Future<void> _handlePreviewAndSave(String ownerId) async {
    final text = _paste.text.trim();
    if (text.isEmpty) {
      setState(() => _message = 'Please paste your VTOP timetable table.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final result = previewVitTable(text);
      if (result.entries.isNotEmpty) {
        await ref
            .read(timetableRepositoryProvider)
            .save(ownerId, result.entries);
        if (!mounted) return;
        ref.invalidate(_savedTimetableProvider(ownerId));
        setState(() {
          _forceImportView = false;
          _paste.clear();
          _message = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.entries.length} weekly classes loaded successfully!'),
              backgroundColor: kAppleBlue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _message = result.errors.isNotEmpty
              ? result.errors.first
              : 'No valid classes found. Paste complete rows from your VTOP table.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Error parsing timetable: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        backgroundColor: kAppleSurface,
        body: Center(
          child: Text(
            'Sign in to view your timetable.',
            style: TextStyle(color: kAppleTextSecondary, fontSize: 16),
          ),
        ),
      );
    }
    final saved = ref.watch(_savedTimetableProvider(user.id));
    return saved.when(
      loading: () => const Scaffold(
        backgroundColor: kAppleSurface,
        body: Center(child: CircularProgressIndicator(color: kAppleBlue)),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: kAppleSurface,
        appBar: AppBar(title: const Text('My Timetable')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load your saved timetable.', style: TextStyle(color: kAppleTextSecondary)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(_savedTimetableProvider(user.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (entries) {
        if (entries.isNotEmpty && !_forceImportView) {
          if (user.isAdmin) {
            return Scaffold(
              backgroundColor: kAppleSurface,
              appBar: AppBar(
                title: const Text('Timetable Master Grid'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.upload_outlined, color: kAppleBlue),
                    tooltip: 'Re-import',
                    onPressed: () => setState(() => _forceImportView = true),
                  ),
                ],
              ),
              body: SafeArea(child: _adminGrid(entries)),
            );
          }
          return TimetableScheduleView(
            entries: entries,
            onReimport: () => setState(() => _forceImportView = true),
          );
        }
        return _buildImportView(user.id, hasExisting: entries.isNotEmpty);
      },
    );
  }

  Widget _buildImportView(String ownerId, {required bool hasExisting}) {
    return Scaffold(
      backgroundColor: kAppleSurface,
      appBar: AppBar(
        title: const Text('Import Timetable'),
        leading: hasExisting
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: kAppleBlue),
                tooltip: 'Back to timetable',
                onPressed: () => setState(() => _forceImportView = false),
              )
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Apple Minimalist Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kAppleBorderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kAppleBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'VTOP COMPATIBLE',
                      style: TextStyle(
                        color: kAppleBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Make room for your semester.',
                    style: TextStyle(
                      color: kAppleTextPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Import your Vellore campus classes to sync weekly schedules, view study squads, and find instant free periods.',
                    style: TextStyle(color: kAppleTextSecondary, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Import Form Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kAppleBorderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'PASTE VTOP TIMETABLE',
                    style: TextStyle(
                      color: kAppleTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Copy the entire course registration table from VTOP and paste the raw text below.',
                    style: TextStyle(color: kAppleTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _paste,
                    enabled: !_saving,
                    minLines: 5,
                    maxLines: 9,
                    onChanged: (_) => setState(() => _message = null),
                    style: const TextStyle(fontSize: 14, color: kAppleTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Course Code | Course Title | Slot | Faculty | Venue...',
                      hintStyle: const TextStyle(color: kAppleTextTertiary, fontSize: 13),
                      filled: true,
                      fillColor: kAppleSurface,
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kAppleBorderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kAppleBlue, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kAppleBlue,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _saving ? null : () => _handlePreviewAndSave(ownerId),
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Process & Save Timetable',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kAppleError.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _message!,
                        style: const TextStyle(
                          color: kAppleError,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminGrid(List<TimetableEntry> entries) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kAppleBorderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MASTER TIMETABLE MATRIX',
              style: TextStyle(
                color: kAppleTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Horizontal view of all Monday–Friday theory & lab slot hours.',
              style: TextStyle(color: kAppleTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(110),
                columnWidths: const {0: FixedColumnWidth(80)},
                border: TableBorder.all(color: kAppleBorderLight),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: kAppleSurface),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'DAY',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kAppleTextSecondary),
                        ),
                      ),
                      for (var column = 0; column < 12; column++)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            theoryStarts[column].isEmpty
                                ? 'Lunch'
                                : '${theoryStarts[column]}–${theoryEnds[column]}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  for (var day = 1; day <= 5; day++) ...[
                    for (final lab in [false, true])
                      TableRow(
                        children: [
                          Container(
                            color: kAppleSurface,
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '${_days[day - 1]}\n${lab ? 'Lab' : 'Theory'}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kAppleTextPrimary),
                            ),
                          ),
                          for (var column = 0; column < 12; column++)
                            _gridCell(entries, day, column, lab),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _gridCell(
    List<TimetableEntry> entries,
    int day,
    int column,
    bool lab,
  ) {
    final code = day > 5
        ? ''
        : lab
            ? labCode(day, column)
            : theoryRows[day - 1][column];
    final matches = entries
        .where((e) => e.day == day && e.slotCode == code)
        .toList();

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      color: matches.isEmpty ? Colors.white : const Color(0xFFE8F7EC),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            code.isEmpty ? '—' : code,
            style: const TextStyle(fontSize: 11, color: kAppleTextSecondary, fontWeight: FontWeight.w600),
          ),
          for (final entry in matches)
            InkWell(
              onTap: () => _details(entry),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${entry.courseCode}\n${entry.venue}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF248A3D),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _details(TimetableEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                entry.course,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kAppleTextPrimary),
              ),
              const SizedBox(height: 4),
              Text('${entry.courseCode} · ${entry.slotCode}', style: const TextStyle(color: kAppleBlue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule, color: kAppleTextSecondary),
                title: Text('${_days[entry.day - 1]} · ${entry.startTime}–${entry.endTime}'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline, color: kAppleTextSecondary),
                title: Text(entry.teacher.isNotEmpty ? entry.teacher : 'Faculty: NIL'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined, color: kAppleTextSecondary),
                title: Text(entry.venue.isNotEmpty ? entry.venue : 'Room: NIL'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
