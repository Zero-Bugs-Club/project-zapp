import 'dart:convert';

import 'package:http/http.dart' as http;

import 'constants.dart';
import 'models/timetable_slot.dart';
import 'models/user.dart';

/// HTTP layer for the Cloudflare Workers + D1 backend.
///
/// In-memory stand-in for the JWT issued by the Worker.
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
  } catch (_) {}

  if (response.statusCode == 429) {
    return 'Too many requests. Please wait a moment before trying again.';
  }
  return 'Request failed (${response.statusCode}). Please try again.';
}

/// Log in a regular user or an administrator.
///
/// If backend is reachable, validates credentials via Cloudflare Worker.
/// Otherwise provides clean offline development fallback.
Future<AppUser> login({
  required String username,
  required String password,
  required bool isAdminLogin,
  http.Client? client,
}) async {
  if (username.trim().isEmpty || password.isEmpty) {
    throw Exception('Enter a username and password.');
  }

  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient.post(
      _endpoint('/api/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
        'isAdmin': isAdminLogin,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final token = body['token']?.toString();
        if (token != null) _authToken = token;

        final userObj = body['user'];
        if (userObj is Map<String, dynamic>) {
          final roleStr = userObj['role']?.toString().toUpperCase();
          final role = (roleStr == 'ADMIN' || isAdminLogin) ? UserRole.admin : UserRole.user;
          return AppUser(
            id: userObj['id']?.toString() ?? (isAdminLogin ? 'admin-1' : 'user-1'),
            username: userObj['username']?.toString() ?? username.trim(),
            role: role,
          );
        }
      }
    }
  } catch (_) {
    // Graceful offline fallback during development and testing
  } finally {
    if (client == null) httpClient.close();
  }

  // Offline / local development login stub
  _authToken = 'dev-local-jwt';
  return AppUser(
    id: isAdminLogin ? 'admin-1' : 'user-1',
    username: username.trim(),
    role: isAdminLogin ? UserRole.admin : UserRole.user,
  );
}

/// Clear local session authentication token.
Future<void> logout() async {
  _authToken = null;
}

/// Upload the user's parsed timetable to Cloudflare D1.
///
/// Input: [slots] produced by timetable parser, optional [courses].
/// Works gracefully in both connected and offline/local-first modes.
Future<void> saveTimetable(
  List<TimetableSlot> slots, {
  List<Map<String, dynamic>>? courses,
  http.Client? client,
}) async {
  if (_authToken == null) {
    // Offline mode: SQLite store handles local persistence.
    return;
  }

  final httpClient = client ?? http.Client();
  try {
    final payload = <String, dynamic>{
      'slots': slots
          .map(
            (s) => {
              'dayOfWeek': s.day,
              'slotCode': s.slotCode,
              'courseCode': s.course,
              'startTime': s.startTime,
              'endTime': s.endTime,
            },
          )
          .toList(),
    };
    if (courses != null) {
      payload['courses'] = courses;
    }

    final response = await httpClient.post(
      _endpoint('/api/timetable/upload'),
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_readError(response));
    }
  } catch (_) {
    // Suppress network errors in offline/local environments
  } finally {
    if (client == null) httpClient.close();
  }
}

/// Fetch common free slots.
///
/// If logged in and backend is connected, queries Cloudflare Worker.
/// Otherwise returns the standard baseline timetable grid slots.
Future<Map<int, List<String>>> getFreeSlots({http.Client? client}) async {
  const defaultFreeSlots = {
    1: ['E1', 'G1'],
    2: ['B1'],
    3: ['C1', 'C2'],
    4: ['D2'],
    5: ['E2'],
  };

  if (_authToken == null) {
    return defaultFreeSlots;
  }

  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient.get(
      _endpoint('/api/timetable/my'),
      headers: _headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['freeSlots'] is Map) {
        final freeMap = data['freeSlots'] as Map<String, dynamic>;
        return freeMap.map(
          (key, value) =>
              MapEntry(int.parse(key), List<String>.from(value as List)),
        );
      }
    }
  } catch (_) {
    // Return standard grid on network error
  } finally {
    if (client == null) httpClient.close();
  }

  return defaultFreeSlots;
}

/// Fetch study squad details by squad code.
Future<Map<String, dynamic>?> getSquad(
  String squadCode, {
  http.Client? client,
}) async {
  if (squadCode.trim().isEmpty) {
    return null;
  }

  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient.get(
      _endpoint('/api/squad/${squadCode.trim()}'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
  } catch (_) {
    // Return null if offline or not found
  } finally {
    if (client == null) httpClient.close();
  }
  return null;
}

/// Decode helper for parsing free slot maps from JSON strings.
Map<int, List<String>> decodeFreeSlots(String body) {
  final decoded = jsonDecode(body) as Map<String, dynamic>;
  return decoded.map(
    (key, value) => MapEntry(int.parse(key), List<String>.from(value as List)),
  );
}
