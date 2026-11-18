class TokenModel {
  final String accessToken;
  final String? refreshToken;

  const TokenModel({
    required this.accessToken,
    this.refreshToken,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json, [String? fallbackRefreshToken]) {
    Map<String, dynamic> dataMap = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      dataMap = json['data'] as Map<String, dynamic>;
    }

    final accessToken = json['accessToken'] as String? ??
        json['access_token'] as String? ??
        json['token'] as String? ??
        dataMap['accessToken'] as String? ??
        dataMap['access_token'] as String? ??
        dataMap['token'] as String? ??
        '';

    final refreshToken = json['refreshToken'] as String? ??
        json['refresh_token'] as String? ??
        dataMap['refreshToken'] as String? ??
        dataMap['refresh_token'] as String? ??
        fallbackRefreshToken;

    return TokenModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
    };
  }
}
