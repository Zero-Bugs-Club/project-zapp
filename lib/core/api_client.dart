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

  if (response.statusCode == 429) {
    return 'Too many requests. Please wait a moment before trying again.';
  }

  return 'Request failed (${response.statusCode}). Please try again.';
}

Future<AppUser> _parseUserResponse(
  http.Response response, {
  bool isRestore = false,
}) async {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(_readError(response));
  }

  final body = jsonDecode(response.body);

  if (body is! Map<String, dynamic>) {
    throw Exception('Invalid response from the server.');
  }

  final user = body['user'];
  if (user is! Map<String, dynamic>) {
    throw Exception('The server returned an invalid user response.');
  }

  final token = body['token'];
  if (token is String) {
    _authToken = token;
    await _secureStorage.write(key: 'auth_token', value: token);
  } else if (!isRestore && _authToken == null) {
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
      body: jsonEncode({'username': username.trim(), 'password': password}),
    );

    final user = await _parseUserResponse(response);

    if (isAdminLogin && !user.isAdmin) {
      await logout();
      throw Exception('These credentials do not belong to an administrator.');
    }

    if (!isAdminLogin && user.isAdmin) {
      await logout();
      throw Exception('Please select administrator login mode.');
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
  try {
    _authToken = await _secureStorage
        .read(key: 'auth_token')
        .timeout(const Duration(seconds: 2), onTimeout: () => null);
  } catch (_) {
    _authToken = null;
  }

  if (_authToken == null || _authToken!.isEmpty) {
    throw Exception('No saved session.');
  }

  try {
    final response = await http.get(_endpoint('/api/me'), headers: _headers);

    if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }

    return await _parseUserResponse(response, isRestore: true);
  } catch (e) {
    await logout();
    rethrow;
  }
}

Future<void> logout() async {
  _authToken = null;
  await _secureStorage.delete(key: 'auth_token');
}

Future<List<PendingUser>> getPendingUsers({http.Client? client}) async {
  if (_authToken == null) {
    throw Exception('Administrator login required.');
  }

  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient.get(
      _endpoint('/api/admin/pending'),
      headers: _headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_readError(response));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['users'] is! List) {
      throw Exception('Invalid pending users response.');
    }

    final list = body['users'] as List;
    return list
        .map((item) => PendingUser.fromJson(item as Map<String, dynamic>))
        .toList();
  } finally {
    if (client == null) httpClient.close();
  }
}

Future<void> reviewUser({
  required String userId,
  required String status,
  http.Client? client,
}) async {
  if (_authToken == null) {
    throw Exception('Administrator login required.');
  }

  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient.post(
      _endpoint('/api/admin/review'),
      headers: _headers,
      body: jsonEncode({'userId': userId, 'status': status}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_readError(response));
    }
  } finally {
    if (client == null) httpClient.close();
  }
}

Future<void> saveTimetable(
  List<TimetableSlot> slots, {
  http.Client? client,
}) async {
  if (_authToken == null) {
    throw Exception('Please log in first.');
  }
  await Future.delayed(const Duration(milliseconds: 300));
}

Future<Map<int, List<String>>> getFreeSlots({http.Client? client}) async {
  if (_authToken == null) {
    throw Exception('Please log in first.');
  }
  await Future.delayed(const Duration(milliseconds: 300));
  return {
    1: ['E1', 'G1'],
    2: ['B1'],
    3: ['C1', 'C2'],
    4: ['D2'],
    5: ['E2'],
  };
}

Map<int, List<String>> decodeFreeSlots(String body) {
  final decoded = jsonDecode(body) as Map<String, dynamic>;

  return decoded.map(
    (key, value) => MapEntry(int.parse(key), List<String>.from(value as List)),
  );
}
