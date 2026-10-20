import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart' as api;
import '../../core/models/user.dart';

/// Auth state owned by the auth feature developer.
///
/// `null` means logged out. [AuthController] is the only place that may
/// change it; the Timetable tab only reads `currentUserProvider` to decide
/// which view to render.
class AuthController extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  Future<void> signIn({
    required String username,
    required String password,
    required bool isAdminLogin,
  }) async {
    state = await api.login(
      username: username,
      password: password,
      isAdminLogin: isAdminLogin,
    );
  }

  void signOut() => state = null;
}

final authProvider = NotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

// Convenience selector for role checks in the Timetable tab.
final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authProvider),
);
