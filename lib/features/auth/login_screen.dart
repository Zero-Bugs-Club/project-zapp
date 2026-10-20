import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'signup_screen.dart';

/// Login screen shown before the bottom navigation.
/// Owned by the auth feature developer.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _isAdminLogin = false;
  bool _busy = false;
  String? _error;

  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 30]) {
    setState(() {
      _cooldownSeconds = seconds;
      _error =
          'Too many failed login attempts. Please wait $_cooldownSeconds seconds.';
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSeconds > 1) {
          _cooldownSeconds--;
          _error =
              'Too many failed login attempts. Please wait $_cooldownSeconds seconds.';
        } else {
          _cooldownSeconds = 0;
          _failedAttempts = 0;
          _error = null;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _submit() async {
    if (_cooldownSeconds > 0) return;

    final userText = _username.text.trim();
    final passText = _password.text;

    if (userText.isEmpty || passText.isEmpty) {
      setState(() => _error = 'Please enter both username and password.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .signIn(
            username: userText,
            password: passText,
            isAdminLogin: _isAdminLogin,
          );
      _failedAttempts = 0;
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceFirst('Exception: ', '');
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          _startCooldown(30);
        } else {
          setState(() => _error = errText);
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCooldown = _cooldownSeconds > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role switch: same screen serves users and admins.
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('User')),
                ButtonSegment(value: true, label: Text('Admin')),
              ],
              selected: {_isAdminLogin},
              onSelectionChanged: _busy || isCooldown
                  ? null
                  : (s) => setState(() {
                      _isAdminLogin = s.first;
                      _error = null;
                    }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy || isCooldown ? null : _submit,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isCooldown ? 'Wait ${_cooldownSeconds}s' : 'Sign in'),
            ),
            if (!_isAdminLogin) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy || isCooldown
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                child: const Text('Create an account'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
