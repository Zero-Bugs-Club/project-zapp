import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: zappCream,
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: zappBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: zappOrangeLight,
                        child: Text(
                          (user?.username.isNotEmpty == true)
                              ? user!.username.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: zappOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '@${user?.username ?? 'user'}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: zappCharcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: zappOrangeLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: zappBorder),
                        ),
                        child: Text(
                          user?.isAdmin == true
                              ? 'Administrator'
                              : 'Student Account',
                          style: const TextStyle(
                            color: zappOrange,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: zappBorder),
                      const SizedBox(height: 16),
                      ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF2E7D32),
                        ),
                        title: const Text(
                          'Account Status',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Text(
                          'Approved',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.security_outlined,
                          color: zappMuted,
                        ),
                        title: const Text(
                          'Authentication',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Text(
                          'Cloudflare D1 & JWT',
                          style: TextStyle(color: zappMuted),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB3261E),
                            side: const BorderSide(color: Color(0xFFE0C4BF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                title: const Text('Sign out?'),
                                content: const Text(
                                  'You will need to sign in again to access Project Zapp.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: zappMuted),
                                    ),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFB3261E),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Sign out'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref.read(authProvider.notifier).signOut();
                            }
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'Sign out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
