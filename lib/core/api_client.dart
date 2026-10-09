import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'models/timetable_slot.dart';
import 'models/user.dart';

const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

String? _authToken;

Uri _endpoint(String path) {
  return Uri.parse('$apiBaseUrl$path');
}

Map<String, String> get _headers => {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

String _readError(http.Response response) {
  try {
    final body = jsonDecode(response.body);

    if (body is Map<String, dynamic> && body['error'] is String) {
      return body['error'] as String;
    }

    if (body is Map<String, dynamic> && body['message'] is String) {
      return body['message'] as String;
    }
  } catch (_) {
    // The server didn't return a JSON error.
  }

  return 'Request failed (${response.statusCode}). Please try again.';
}

Future<AppUser> _parseUserResponse(http.Response response) async {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(_readError(response));
  }

  final body = jsonDecode(response.body);

  if (body is! Map<String, dynamic>) {
    throw Exception('Invalid response from the server.');
  }

  final token = body['token'];
  final user = body['user'];

  if (token is! String || user is! Map<String, dynamic>) {
    throw Exception('The server returned an invalid login response.');
  }

  final role = user['role'] == 'ADMIN'
      ? UserRole.admin
      : user['role'] == 'USER'
          ? UserRole.user
          : null;

  if (role == null) {
    throw Exception('The server returned an invalid user role.');
  }

  final statusValue = user['status'] ?? 'APPROVED';

  final status = switch (statusValue) {
    'PENDING' => AccountStatus.pending,
    'REJECTED' => AccountStatus.rejected,
    'APPROVED' => AccountStatus.approved,
    _ => throw Exception('The server returned an invalid account status.'),
  };

  if (status != AccountStatus.approved) {
    throw Exception(
      status == AccountStatus.pending
          ? 'Your account is awaiting administrator approval.'
          : 'Your account has been rejected.',
    );
  }

  _authToken = token;
  await _secureStorage.write(key: 'auth_token', value: token);

  return AppUser(
    id: user['id'].toString(),
    username: user['username'].toString(),
    role: role,
    status: status,
  );
}

Future<AppUser> login({
  required String username,
  required String password,
  required bool isAdminLogin,
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();

  if (username.trim().isEmpty || password.isEmpty) {
    throw Exception('Enter a username and password.');
  }

  try {
    final response = await httpClient.post(
      _endpoint('/api/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
      }),
    );

    final user = await _parseUserResponse(response);

    if (isAdminLogin && !user.isAdmin) {
      await logout();
      throw Exception('These credentials do not belong to an administrator.');
    }

    if (!isAdminLogin && user.isAdmin) {
      await logout();
      throw Exception('Please select administrator login.');
    }

    return user;
  } finally {
    if (client == null) httpClient.close();
  }
}

Future<void> signUp({
  required String name,
  required String email,
  required String phoneNumber,
  required String username,
  required String password,
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();

  try {
    final response = await httpClient.post(
      _endpoint('/api/signup'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phoneNumber': phoneNumber.trim(),
        'username': username.trim(),
        'password': password,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_readError(response));
    }
  } finally {
    if (client == null) httpClient.close();
  }
}

Future<AppUser> restoreSession() async {
  _authToken = await _secureStorage.read(key: 'auth_token');

  if (_authToken == null || _authToken!.isEmpty) {
    throw Exception('No saved session.');
  }

  final response = await http.get(
    _endpoint('/api/me'),
    headers: _headers,
  );

  return _parseUserResponse(response);
}

Future<void> logout() async {
  _authToken = null;
  await _secureStorage.delete(key: 'auth_token');
}

Future<void> saveTimetable(
  List<TimetableSlot> slots, {
  http.Client? client,
}) async {
  if (_authToken == null) {
    throw Exception('Please log in first.');
  }

  // Timetable API integration is not implemented in this authentication step.
  throw UnimplementedError('Timetable API integration is still pending.');
}

Future<Map<int, List<String>>> getFreeSlots({
  http.Client? client,
}) async {
  if (_authToken == null) {
    throw Exception('Please log in first.');
  }

  // Timetable API integration is not implemented in this authentication step.
  throw UnimplementedError('Timetable API integration is still pending.');
}

Map<int, List<String>> decodeFreeSlots(String body) {
  final decoded = jsonDecode(body) as Map<String, dynamic>;

  return decoded.map(
    (key, value) => MapEntry(
      int.parse(key),
      List<String>.from(value as List),
    ),
  );
}