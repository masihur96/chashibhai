class UserEntity {
  final String? id;
  final String name;
  final String phone;
  final String role;
  final String? email;
  final String? token;
  final String? refreshToken;
  final String? avatarUrl;
  final String? district;
  final bool isVerified;

  const UserEntity({
    this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
    this.token,
    this.refreshToken,
    this.avatarUrl,
    this.district,
    this.isVerified = false,
  });
}
