import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/timetable_slot.dart';
import 'models/user.dart';

/// HTTP layer for the Cloudflare Workers + D1 backend.
///
/// All functions are stubs returning fake data. The auth/timetable owners
/// replace the bodies with real Worker calls, keeping these signatures.
///
/// Expected Worker endpoints (to be implemented server-side):
///   POST `/api/login`      -> `{ "token": "<jwt>", "role": "user|admin", "userId": "..." }`
///   POST `/api/timetable`  -> saves parsed slots, requires `"Authorization: Bearer <jwt>"`
///   GET  `/api/free-slots` -> `{ "1": ["A1", ...], ... }` keyed by weekday, admin only

// In-memory stand-in for the JWT issued by the Worker. Persist securely
// (e.g. flutter_secure_storage) once real auth is wired up.
String? _authToken;

/// Log in a regular user or an admin.
///
/// Input: [username], [password], [isAdminLogin] (which login form was used).
/// Output: the logged-in [AppUser] with its role. Throws on bad credentials.
/// TODO(auth): POST to /api/login with a JSON body, verify the JWT + role
/// from D1 via the Worker (bcrypt/scrypt check server-side), store the token.
Future<AppUser> login({
  required String username,
  required String password,
  required bool isAdminLogin,
  http.Client? client,
}) async {
  client ??= http.Client();
  // Stub: accept anything non-empty so UI work can proceed offline.
  await Future.delayed(const Duration(milliseconds: 300));
  if (username.isEmpty || password.isEmpty) {
    throw Exception('Enter a username and password.');
  }
  _authToken = 'fake-jwt-for-dev';
  return AppUser(
    id: isAdminLogin ? 'admin-1' : 'user-1',
    username: username,
    role: isAdminLogin ? UserRole.admin : UserRole.user,
  );
}

/// Upload the user's parsed timetable.
///
/// Input: the [slots] produced by the timetable parser.
/// TODO(timetable): POST JSON to /api/timetable with the Bearer token.
Future<void> saveTimetable(
  List<TimetableSlot> slots, {
  http.Client? client,
}) async {
  client ??= http.Client();
  // Stub: pretend the upload succeeded.
  await Future.delayed(const Duration(milliseconds: 300));
  assert(_authToken != null, 'Call login() before saveTimetable().');
}

/// Fetch common free slots for the admin grid.
///
/// Output: map of weekday (1–7) to the slot codes where every user is free,
/// computed server-side by aggregating all users' parsed timetables.
/// TODO(timetable): GET /api/free-slots with the admin Bearer token and
/// decode the JSON into this map.
Future<Map<int, List<String>>> getFreeSlots({http.Client? client}) async {
  client ??= http.Client();
  await Future.delayed(const Duration(milliseconds: 300));
  assert(_authToken != null, 'Call login() before getFreeSlots().');
  // Stub data so the admin view renders before the backend exists.
  return {
    1: ['E1', 'G1'],
    2: ['B1'],
    3: ['C1', 'C2'],
    4: ['D2'],
    5: ['E2'],
  };
}

/// Decode helper the feature owners can reuse once real JSON arrives.
Map<int, List<String>> decodeFreeSlots(String body) {
  final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
  return json.map(
    (k, v) => MapEntry(int.parse(k), List<String>.from(v as List)),
  );
}
