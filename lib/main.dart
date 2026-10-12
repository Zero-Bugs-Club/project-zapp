import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/gps_camera/camera_screen.dart';
import 'features/timetable/timetable_screen.dart';

void main() {
  // ProviderScope enables Riverpod state (auth/role) app-wide.
  runApp(const ProviderScope(child: ZappApp()));
}

class ZappApp extends StatelessWidget {
  const ZappApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Zapp',
      theme: appTheme,
      home: const AuthGate(),
    );
  }
}

/// Shows the login screen when logged out, else the 2-tab navigation.
/// Auth is a gate, not a tab: Camera and Timetable are the only tabs.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const LoginScreen();
    return const HomeShell();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [CameraScreen(), TimetableScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Camera'),
          NavigationDestination(icon: Icon(Icons.schedule), label: 'Timetable'),
        ],
      ),
    );
  }
}
