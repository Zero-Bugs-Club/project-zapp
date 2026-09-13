/// App user. [role] decides what the Timetable tab renders:
/// [UserRole.user] sees their own timetable,
/// [UserRole.admin] sees the common free-slot grid.
enum UserRole { user, admin }

class AppUser {
  final String id;
  final String username;
  final UserRole role;

  const AppUser({required this.id, required this.username, required this.role});

  bool get isAdmin => role == UserRole.admin;
}
