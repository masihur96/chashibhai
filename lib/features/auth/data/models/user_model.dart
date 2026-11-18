import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    super.id,
    required super.name,
    required super.phone,
    required super.role,
    super.email,
    super.token,
    super.refreshToken,
    super.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, [String? fallbackToken, String? fallbackRefreshToken]) {
    // If response is nested inside 'data' or 'user'
    Map<String, dynamic> userMap = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      userMap = json['data'] as Map<String, dynamic>;
    } else if (json.containsKey('user') && json['user'] is Map<String, dynamic>) {
      userMap = json['user'] as Map<String, dynamic>;
    }

    final token = json['token'] as String? ??
        json['accessToken'] as String? ??
        json['access_token'] as String? ??
        userMap['token'] as String? ??
        userMap['accessToken'] as String? ??
        userMap['access_token'] as String? ??
        fallbackToken;

    final refreshToken = json['refreshToken'] as String? ??
        json['refresh_token'] as String? ??
        userMap['refreshToken'] as String? ??
        userMap['refresh_token'] as String? ??
        fallbackRefreshToken;

    return UserModel(
      id: (userMap['id'] ?? userMap['_id'] ?? userMap['sub'])?.toString(),
      name: (userMap['name'] ?? userMap['fullName'] ?? '').toString(),
      phone: (userMap['phone'] ?? userMap['phoneNumber'] ?? '').toString(),
      role: (userMap['role'] ?? 'BUYER').toString(),
      email: userMap['email']?.toString(),
      token: token,
      refreshToken: refreshToken,
      avatarUrl: (userMap['avatarUrl'] ?? userMap['avatar'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      if (email != null) 'email': email,
      if (token != null) 'token': token,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}
