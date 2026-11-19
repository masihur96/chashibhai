class AdminUserModel {
  final String id;
  final String name;
  final String phone;
  final String role; // 'farmer', 'buyer', 'admin'
  final String? email;
  final String? avatarUrl;
  final String? district;
  final bool isVerified;
  final bool isBanned;
  final double rating;
  final double walletBalance;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? nid;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
    this.avatarUrl,
    this.district,
    this.isVerified = false,
    this.isBanned = false,
    this.rating = 0.0,
    this.walletBalance = 0.0,
    this.createdAt,
    this.updatedAt,
    this.nid,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: (json['id'] ?? json['_id'] ?? json['uuid'] ?? 'u_${DateTime.now().millisecondsSinceEpoch}').toString(),
      name: (json['name'] ?? json['fullName'] ?? json['full_name'] ?? 'User').toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? json['mobile'] ?? '').toString(),
      role: (json['role'] ?? 'buyer').toString().toLowerCase(),
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString() ?? json['avatar']?.toString(),
      district: json['district']?.toString() ?? json['location']?.toString(),
      isVerified: json['isVerified'] == true || json['is_verified'] == true || json['verified'] == true,
      isBanned: json['isBanned'] == true || json['is_banned'] == true || json['banned'] == true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null),
      nid: json['nid']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'email': email,
      'avatarUrl': avatarUrl,
      'district': district,
      'isVerified': isVerified,
      'isBanned': isBanned,
      'rating': rating,
      'walletBalance': walletBalance,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'nid': nid,
    };
  }

  AdminUserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    String? email,
    String? avatarUrl,
    String? district,
    bool? isVerified,
    bool? isBanned,
    double? rating,
    double? walletBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? nid,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      district: district ?? this.district,
      isVerified: isVerified ?? this.isVerified,
      isBanned: isBanned ?? this.isBanned,
      rating: rating ?? this.rating,
      walletBalance: walletBalance ?? this.walletBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nid: nid ?? this.nid,
    );
  }
}

class AdminUsersResponseModel {
  final List<AdminUserModel> users;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const AdminUsersResponseModel({
    required this.users,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  factory AdminUsersResponseModel.fromJson(dynamic json, {int page = 1, int limit = 20}) {
    List<AdminUserModel> userList = [];
    int totalCount = 0;
    int curPage = page;
    int pageLimit = limit;
    int pages = 1;

    if (json is Map<String, dynamic>) {
      dynamic rawUsers = json['data'] ?? json['users'] ?? json['items'];
      if (rawUsers is Map<String, dynamic>) {
        if (rawUsers['users'] is List) rawUsers = rawUsers['users'];
        else if (rawUsers['data'] is List) rawUsers = rawUsers['data'];
        else if (rawUsers['items'] is List) rawUsers = rawUsers['items'];
      }

      if (rawUsers is List) {
        userList = rawUsers.whereType<Map<String, dynamic>>().map((e) => AdminUserModel.fromJson(e)).toList();
      }

      final meta = json['meta'] ?? json['pagination'] ?? (json['data'] is Map ? json['data']['meta'] : null);
      if (meta is Map<String, dynamic>) {
        totalCount = (meta['total'] as num?)?.toInt() ?? (meta['totalCount'] as num?)?.toInt() ?? userList.length;
        curPage = (meta['page'] as num?)?.toInt() ?? (meta['currentPage'] as num?)?.toInt() ?? page;
        pageLimit = (meta['limit'] as num?)?.toInt() ?? (meta['pageSize'] as num?)?.toInt() ?? limit;
        pages = (meta['totalPages'] as num?)?.toInt() ?? (meta['pageCount'] as num?)?.toInt() ?? 1;
      } else {
        totalCount = (json['total'] as num?)?.toInt() ?? userList.length;
        pages = (totalCount / pageLimit).ceil().clamp(1, 9999);
      }
    } else if (json is List) {
      userList = json.whereType<Map<String, dynamic>>().map((e) => AdminUserModel.fromJson(e)).toList();
      totalCount = userList.length;
      pages = (totalCount / pageLimit).ceil().clamp(1, 9999);
    }

    return AdminUsersResponseModel(
      users: userList,
      total: totalCount,
      page: curPage,
      limit: pageLimit,
      totalPages: pages,
    );
  }
}
