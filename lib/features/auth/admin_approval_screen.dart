import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart' as api;
import '../../core/models/user.dart';
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
        title: Text('$actionLabel @${user.username}?'),
        content: Text(
          isApprove
              ? 'Approve ${user.name}\'s account? They will be able to log in immediately.'
              : 'Reject ${user.name}\'s account? They will be denied access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
        ),
      );

      ref.invalidate(pendingUsersProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(user.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Approvals'),
        actions: [
          IconButton(
            tooltip: 'Refresh list',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingUsersProvider),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingUsersProvider);
          await ref.read(pendingUsersProvider.future);
        },
        child: pendingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    err.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(pendingUsersProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (users) {
            if (users.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No pending requests.')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = users[index];
                final isProcessing = _processingIds.contains(user.id);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user.username} • ${user.email} • ${user.phoneNumber}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isProcessing)
                              const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else ...[
                              OutlinedButton(
                                onPressed: () =>
                                    _handleReview(user, 'REJECTED'),
                                child: const Text('Reject'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () =>
                                    _handleReview(user, 'APPROVED'),
                                child: const Text('Approve'),
                              ),
                            ],
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
    );
  }
}
