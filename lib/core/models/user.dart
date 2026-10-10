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

class PendingUser {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String username;
  final String role;
  final String status;
  final DateTime? createdAt;

  const PendingUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.username,
    this.role = 'USER',
    this.status = 'PENDING',
    this.createdAt,
  });

  factory PendingUser.fromJson(Map<String, dynamic> json) {
    return PendingUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? 'USER',
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
