import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _isAdminLogin = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  // Client-side rate limiting / cooldown protection
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

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .signIn(
            username: _username.text.trim(),
            password: _password.text,
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
          setState(() {
            _error = errText;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(
    String label, {
    Widget? suffixIcon,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: zappMuted)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: zappBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: zappBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: zappOrange, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCooldown = _cooldownSeconds > 0;

    return Scaffold(
      backgroundColor: zappCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: zappBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: zappOrange,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PROJECT ZAPP',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      color: zappOrange,
                                    ),
                                  ),
                                  Text(
                                    'Campus Attendance & Timetable',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: zappMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Text(
                          _isAdminLogin ? 'Admin Portal' : 'Welcome back.',
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: zappCharcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAdminLogin
                              ? 'Sign in with administrator credentials to manage user approvals.'
                              : 'Sign in to access your student timetable and camera.',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: zappMuted,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: zappOrange,
                            selectedForegroundColor: Colors.white,
                            foregroundColor: zappCharcoal,
                            side: const BorderSide(color: zappBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text(
                                'Student',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              icon: Icon(Icons.school_outlined),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(
                                'Admin',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              icon: Icon(Icons.admin_panel_settings_outlined),
                            ),
                          ],
                          selected: {_isAdminLogin},
                          onSelectionChanged: _busy || isCooldown
                              ? null
                              : (selection) {
                                  setState(() {
                                    _isAdminLogin = selection.first;
                                    _error = null;
                                  });
                                },
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _username,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: _decoration(
                            'Username',
                            prefixIcon: Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter your username.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: _decoration(
                            'Password',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: zappMuted,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password.';
                            }
                            return null;
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBE7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFC5BC),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFFB3261E),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Color(0xFFB3261E),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _busy || isCooldown ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: zappOrange,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: zappOrange.withValues(
                                alpha: 0.5,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isCooldown
                                        ? 'Wait $_cooldownSeconds s'
                                        : (_isAdminLogin
                                              ? 'Sign in as Administrator'
                                              : 'Sign in'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        if (!_isAdminLogin) ...[
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'New to Zapp? ',
                                style: TextStyle(color: zappMuted),
                              ),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const SignupScreen(),
                                          ),
                                        );
                                      },
                                child: const Text(
                                  'Create an account',
                                  style: TextStyle(
                                    color: zappOrange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'New registrations require admin approval before login.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: zappMuted),
                            ),
                          ),
                        ],
                      ],
                    ),
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
