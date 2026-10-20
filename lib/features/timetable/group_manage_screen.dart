import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

/// Screen allowing the user to Join an existing squad with an 8-character code
/// or Create a new squad with Name, Description, and generated code.
///
/// Follows Apple Design System (design.md):
/// - Clean white & F5F5F7 surfaces
/// - Apple Blue (#0071E3) interactivity
/// - Pill segmented controls & stadium-border buttons
/// - Zero overflow & fluid layout
class GroupManageScreen extends StatefulWidget {
  final int initialTabIndex;
  final ValueChanged<String>? onGroupJoined;
  final ValueChanged<Map<String, String>>? onGroupCreated;

  const GroupManageScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onGroupJoined,
    this.onGroupCreated,
  });

  @override
  State<GroupManageScreen> createState() => _GroupManageScreenState();
}

class _GroupManageScreenState extends State<GroupManageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Join form controllers
  final _joinCodeController = TextEditingController();
  String? _joinError;
  bool _joinSuccess = false;
  String _joinedGroupName = '';

  // Create form controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _createError;
  bool _createSuccess = false;
  String _generatedCode = '';
  String _createdGroupName = '';
  String _createdGroupDesc = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _joinCodeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _generateRandomSquadCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final buffer = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    final raw = buffer.toString();
    return '${raw.substring(0, 4)}-${raw.substring(4)}';
  }

  void _handleJoin() {
    final raw = _joinCodeController.text.replaceAll('-', '').trim().toUpperCase();
    if (raw.length != 8) {
      setState(() {
        _joinError = 'Please enter a valid 8-digit alphanumeric squad code.';
      });
      return;
    }

    setState(() {
      _joinError = null;
      _joinSuccess = true;
      _joinedGroupName = 'Study Squad ($raw)';
    });

    widget.onGroupJoined?.call(raw);
  }

  void _handleCreate() {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _createError = 'Please enter a group name.';
      });
      return;
    }

    final code = _generateRandomSquadCode();
    setState(() {
      _createError = null;
      _createSuccess = true;
      _generatedCode = code;
      _createdGroupName = name;
      _createdGroupDesc = desc.isNotEmpty ? desc : 'Active campus study squad';
    });

    widget.onGroupCreated?.call({
      'name': name,
      'description': _createdGroupDesc,
      'code': code,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppleSurface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopNav(),
            const SizedBox(height: 12),
            _buildSegmentedSwitch(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJoinGroupTab(),
                  _buildCreateGroupTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Navigation Bar ─────────────────────────────────────────────────────

  Widget _buildTopNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      color: kAppleSurface,
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: kAppleBlue,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: kAppleBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Study Squad',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kAppleTextPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 60), // Visual balance for back button
        ],
      ),
    );
  }

  // ── Segmented Switcher (Join / Create) ─────────────────────────────────────

  Widget _buildSegmentedSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E9EC),
          borderRadius: BorderRadius.circular(999),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerHeight: 0,
          tabAlignment: TabAlignment.fill,
          labelColor: kAppleTextPrimary,
          unselectedLabelColor: kAppleTextSecondary,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Join Group'),
            Tab(text: 'Create Group'),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Join Group ──────────────────────────────────────────────────────

  Widget _buildJoinGroupTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (_joinSuccess) ...[
          _buildJoinSuccessCard(),
        ] else ...[
          // Hero text
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kAppleBorderLight),
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
                    'JOIN SQUAD',
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
                  'Sync schedules with your squad.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kAppleTextPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the 8-digit squad code shared by your friend to sync classes and immediately spot mutual free hours.',
                  style: TextStyle(
                    color: kAppleTextSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Code Entry Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kAppleBorderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ENTER 8-DIGIT SQUAD CODE',
                  style: TextStyle(
                    color: kAppleTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                    LengthLimitingTextInputFormatter(9), // allows 8 digits + dash
                  ],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.0,
                    color: kAppleTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'K8M2-9PL4',
                    hintStyle: const TextStyle(
                      color: kAppleTextTertiary,
                      letterSpacing: 3.0,
                      fontSize: 18,
                    ),
                    filled: true,
                    fillColor: kAppleSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: const Icon(Icons.key_rounded, color: kAppleBlue),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kAppleBorderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kAppleBlue, width: 1.5),
                    ),
                  ),
                  onChanged: (_) {
                    if (_joinError != null) setState(() => _joinError = null);
                  },
                ),
                if (_joinError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _joinError!,
                    style: const TextStyle(
                      color: kAppleError,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: kAppleBlue,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _handleJoin,
                    child: const Text(
                      'Join Squad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildJoinSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kAppleBorderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kAppleSuccess.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: kAppleSuccess,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Joined Successfully!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kAppleTextPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are now part of $_joinedGroupName. All schedules and free period matrices are synced.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kAppleTextSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kAppleBlue,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'View Squad Timetable',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Create Group ────────────────────────────────────────────────────

  Widget _buildCreateGroupTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (_createSuccess) ...[
          _buildCreateSuccessCard(),
        ] else ...[
          // Hero Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kAppleBorderLight),
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
                    'NEW SQUAD',
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
                  'Form your study circle.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kAppleTextPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Give your group a name and description. We will automatically generate a unique 8-character invite code.',
                  style: TextStyle(
                    color: kAppleTextSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Form Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kAppleBorderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'GROUP NAME',
                  style: TextStyle(
                    color: kAppleTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 15, color: kAppleTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. CSE Core Study Squad',
                    hintStyle: const TextStyle(color: kAppleTextTertiary, fontSize: 14),
                    filled: true,
                    fillColor: kAppleSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kAppleBorderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kAppleBlue, width: 1.5),
                    ),
                  ),
                  onChanged: (_) {
                    if (_createError != null) setState(() => _createError = null);
                  },
                ),
                const SizedBox(height: 18),

                const Text(
                  'GROUP DESCRIPTION',
                  style: TextStyle(
                    color: kAppleTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  minLines: 2,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 15, color: kAppleTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Semester 4 revision, lab prep, and project collaboration.',
                    hintStyle: const TextStyle(color: kAppleTextTertiary, fontSize: 14),
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
                if (_createError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _createError!,
                    style: const TextStyle(
                      color: kAppleError,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 22),

                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: kAppleBlue,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _handleCreate,
                    child: const Text(
                      'Create Squad & Generate Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCreateSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kAppleBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kAppleBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: kAppleBlue,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _createdGroupName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kAppleTextPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _createdGroupDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kAppleTextSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),

          // Code Display Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kAppleSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kAppleBorderLight),
            ),
            child: Column(
              children: [
                const Text(
                  'SHARE THIS SQUAD CODE',
                  style: TextStyle(
                    color: kAppleTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _generatedCode,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                    color: kAppleBlue,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _generatedCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Squad Code $_generatedCode copied to clipboard!'),
                        backgroundColor: kAppleBlue,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy Invite Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kAppleBlue,
                    side: const BorderSide(color: kAppleBorderLight),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kAppleBlue,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Open Squad Timetable',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
