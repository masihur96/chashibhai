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
    super.district,
    super.isVerified,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json, [
    String? fallbackToken,
    String? fallbackRefreshToken,
  ]) {
    // Extract tokens from root or nested objects
    String? token = json['token'] as String? ??
        json['accessToken'] as String? ??
        json['access_token'] as String?;

    String? refreshToken = json['refreshToken'] as String? ??
        json['refresh_token'] as String?;

    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      final dataMap = json['data'] as Map<String, dynamic>;
      token ??= dataMap['token'] as String? ??
          dataMap['accessToken'] as String? ??
          dataMap['access_token'] as String?;

      refreshToken ??= dataMap['refreshToken'] as String? ??
          dataMap['refresh_token'] as String?;

      if (dataMap.containsKey('tokens') && dataMap['tokens'] is Map<String, dynamic>) {
        final tokensMap = dataMap['tokens'] as Map<String, dynamic>;
        token ??= tokensMap['accessToken'] as String? ??
            tokensMap['access_token'] as String? ??
            tokensMap['token'] as String?;
        refreshToken ??= tokensMap['refreshToken'] as String? ??
            tokensMap['refresh_token'] as String?;
      }
    }

    // Drill down to the inner user map (handles { data: { user: { role: "farmer", ... } } })
    Map<String, dynamic> userMap = json;
    while (true) {
      if (userMap.containsKey('data') && userMap['data'] is Map<String, dynamic>) {
        userMap = userMap['data'] as Map<String, dynamic>;
      } else if (userMap.containsKey('user') && userMap['user'] is Map<String, dynamic>) {
        userMap = userMap['user'] as Map<String, dynamic>;
      } else {
        break;
      }
    }

    token ??= userMap['token'] as String? ??
        userMap['accessToken'] as String? ??
        userMap['access_token'] as String? ??
        fallbackToken;

    refreshToken ??= userMap['refreshToken'] as String? ??
        userMap['refresh_token'] as String? ??
        fallbackRefreshToken;

    final rawName = userMap['name'] ?? userMap['fullName'] ?? userMap['username'];
    final name = (rawName != null && rawName.toString().isNotEmpty)
        ? rawName.toString()
        : (userMap['phone'] != null && userMap['phone'].toString().isNotEmpty
            ? userMap['phone'].toString()
            : 'User');

    // Extract role accurately from nested userMap (e.g. "farmer", "buyer", "admin")
    final role = (userMap['role'] ?? 'buyer').toString();
    final district = userMap['district']?.toString();

    return UserModel(
      id: (userMap['id'] ?? userMap['_id'] ?? userMap['sub'] ?? userMap['supabaseId'])?.toString(),
      name: name,
      phone: (userMap['phone'] ?? userMap['phoneNumber'] ?? '').toString(),
      role: role,
      email: userMap['email']?.toString(),
      token: token,
      refreshToken: refreshToken,
      avatarUrl: (userMap['avatarUrl'] ?? userMap['avatar_url'] ?? userMap['avatar'])?.toString(),
      district: district,
      isVerified: userMap['isVerified'] == true,
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
      if (district != null) 'district': district,
      'isVerified': isVerified,
    };
  }
}
