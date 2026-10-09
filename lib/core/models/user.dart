
enum UserRole { user, admin }

enum AccountStatus { pending, approved, rejected }

class AppUser {
  final String id;
  final String username;
  final UserRole role;
  final AccountStatus status;

  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    this.status = AccountStatus.approved,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isApproved => status == AccountStatus.approved;
}
