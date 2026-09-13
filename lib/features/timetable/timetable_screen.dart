import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart' as api;
import '../../core/models/timetable_slot.dart';
import '../auth/auth_provider.dart';
import 'timetable_parser.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Timetable tab. Owned by the timetable feature developer.
///
/// Same tab renders different content by role:
///   - regular user: their own parsed 7-day timetable.
///   - admin: 7-day grid of common free slots from [api.getFreeSlots].
class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  final _paste = TextEditingController();
  List<TimetableSlot> _mySlots = [];
  Map<int, List<String>>? _freeSlots;
  bool _loadingFree = false;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  void _parseAndSave() {
    final slots = parseVitTable(_paste.text);
    setState(() => _mySlots = slots);
    // Fire-and-forget upload; errors surface on the save button in future.
    api.saveTimetable(slots);
  }

  Future<void> _loadFreeSlots() async {
    setState(() => _loadingFree = true);
    try {
      _freeSlots = await api.getFreeSlots();
    } finally {
      if (mounted) setState(() => _loadingFree = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user != null && user.isAdmin) return _buildAdminView();
    return _buildUserView();
  }

  Widget _buildUserView() {
    return Scaffold(
      appBar: AppBar(title: const Text('My Timetable')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _paste,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Paste your VIT registration table here',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _parseAndSave, child: const Text('Parse')),
          const SizedBox(height: 16),
          for (var day = 1; day <= 7; day++) ...[
            Text(
              _weekdays[day - 1],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final s in _mySlots.where((e) => e.day == day))
              ListTile(
                dense: true,
                title: Text('${s.slotCode}  ${s.course}'),
                subtitle: Text('${s.startTime}–${s.endTime}'),
              ),
            const Divider(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Common Free Slots')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton(
            onPressed: _loadingFree ? null : _loadFreeSlots,
            child: const Text('Load free slots'),
          ),
          const SizedBox(height: 16),
          if (_loadingFree)
            const Center(child: CircularProgressIndicator())
          else if (_freeSlots != null)
            for (var day = 1; day <= 7; day++) ...[
              Text(
                _weekdays[day - 1],
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text((_freeSlots![day] ?? const []).join(', ')),
              const Divider(),
            ],
        ],
      ),
    );
  }
}
