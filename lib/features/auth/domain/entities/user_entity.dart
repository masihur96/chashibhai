class UserEntity {
  final String? id;
  final String name;
  final String phone;
  final String role;
  final String? email;
  final String? token;
  final String? avatarUrl;

  const UserEntity({
    this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
    this.token,
    this.avatarUrl,
  });
}
