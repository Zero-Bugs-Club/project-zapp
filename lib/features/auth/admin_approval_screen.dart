import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart' as api;
import '../../core/models/user.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';

class AdminApprovalScreen extends ConsumerStatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  ConsumerState<AdminApprovalScreen> createState() =>
      _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends ConsumerState<AdminApprovalScreen> {
  final Set<String> _processingIds = {};

  Future<void> _handleReview(PendingUser user, String newStatus) async {
    final isApprove = newStatus == 'APPROVED';
    final actionLabel = isApprove ? 'Approve' : 'Reject';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$actionLabel @${user.username}?',
          style: const TextStyle(
            color: zappCharcoal,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          isApprove
              ? 'This will approve ${user.name}\'s account. They will be able to log in to Project Zapp immediately.'
              : 'This will reject ${user.name}\'s account. They will be denied login access.',
          style: const TextStyle(color: zappMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: zappMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isApprove ? zappOrange : const Color(0xFFB3261E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingIds.add(user.id));

    try {
      await api.reviewUser(userId: user.id, status: newStatus);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApprove
                ? 'Account for @${user.username} approved.'
                : 'Account for @${user.username} rejected.',
          ),
          backgroundColor: isApprove
              ? const Color(0xFF2E7D32)
              : const Color(0xFFB3261E),
        ),
      );

      ref.invalidate(pendingUsersProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFB3261E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(user.id));
      }
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recently';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      backgroundColor: zappCream,
      appBar: AppBar(
        title: const Text('Admin Approvals'),
        actions: [
          IconButton(
            tooltip: 'Refresh list',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(pendingUsersProvider),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: RefreshIndicator(
              color: zappOrange,
              onRefresh: () async {
                ref.invalidate(pendingUsersProvider);
                await ref.read(pendingUsersProvider.future);
              },
              child: pendingAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: zappOrange),
                ),
                error: (err, _) => ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: zappBorder),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFB3261E),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unable to load pending requests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: zappCharcoal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            err.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: zappMuted),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () =>
                                ref.invalidate(pendingUsersProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                data: (users) {
                  if (users.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 48,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: zappBorder),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 72,
                                width: 72,
                                decoration: BoxDecoration(
                                  color: zappOrangeLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: zappOrange,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No Pending Requests',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: zappCharcoal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'All registered student accounts have been reviewed.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: zappMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: users.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${users.length} Pending ${users.length == 1 ? 'Request' : 'Requests'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: zappCharcoal,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: zappOrangeLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Awaiting Review',
                                  style: const TextStyle(
                                    color: zappOrange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final user = users[index - 1];
                      final isBusy = _processingIds.contains(user.id);

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: zappBorder),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: zappOrangeLight,
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: zappOrange,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: zappCharcoal,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '@${user.username}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: zappOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatDate(user.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: zappMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(color: zappBorder, height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: zappMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user.email,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: zappCharcoal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: zappMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    user.phoneNumber,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: zappCharcoal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFB3261E),
                                      side: const BorderSide(
                                        color: Color(0xFFE0C4BF),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: isBusy
                                        ? null
                                        : () => _handleReview(user, 'REJECTED'),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 10),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: zappOrange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: isBusy
                                        ? null
                                        : () => _handleReview(user, 'APPROVED'),
                                    child: isBusy
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Approve'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
