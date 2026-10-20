import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 36,
            child: Text(
              (user?.username.isNotEmpty == true)
                  ? user!.username.substring(0, 1).toUpperCase()
                  : 'U',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '@${user?.username ?? 'user'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              user?.isAdmin == true ? 'Administrator' : 'Student Account',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.check_circle_outline, color: Colors.green),
            title: Text('Account Status'),
            trailing: Text(
              'Approved',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text(
                    'You will need to sign in again to access Project Zapp.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authProvider.notifier).signOut();
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
