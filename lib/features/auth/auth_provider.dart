import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart' as api;
import '../../core/models/user.dart';

class AuthController extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  Future<void> signIn({
    required String username,
    required String password,
    required bool isAdminLogin,
  }) async {
    final user = await api.login(
      username: username,
      password: password,
      isAdminLogin: isAdminLogin,
    );
    state = user;
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String phoneNumber,
    required String username,
    required String password,
  }) async {
    await api.signUp(
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      username: username,
      password: password,
    );
  }

  Future<void> restoreSession() async {
    try {
      state = await api.restoreSession();
    } catch (_) {
      state = null;
    }
  }

  Future<void> signOut() async {
    await api.logout();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authProvider),
);

/// Riverpod provider for fetching pending users in administrator view.
final pendingUsersProvider = FutureProvider.autoDispose<List<PendingUser>>((
  ref,
) async {
  return api.getPendingUsers();
});
