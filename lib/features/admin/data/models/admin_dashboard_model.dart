class AdminDashboardModel {
  final int totalUsers;
  final int totalFarmers;
  final int totalBuyers;
  final int activeProducts;
  final int activeOrders;
  final double totalRevenue;
  final int pendingKyc;
  final double activeEscrow;

  const AdminDashboardModel({
    required this.totalUsers,
    required this.totalFarmers,
    required this.totalBuyers,
    required this.activeProducts,
    required this.activeOrders,
    required this.totalRevenue,
    required this.pendingKyc,
    required this.activeEscrow,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalFarmers: (json['totalFarmers'] as num?)?.toInt() ?? 0,
      totalBuyers: (json['totalBuyers'] as num?)?.toInt() ?? 0,
      activeProducts: (json['activeProducts'] as num?)?.toInt() ?? 0,
      activeOrders: (json['activeOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      pendingKyc: (json['pendingKyc'] as num?)?.toInt() ?? 0,
      activeEscrow: (json['activeEscrow'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalFarmers': totalFarmers,
      'totalBuyers': totalBuyers,
      'activeProducts': activeProducts,
      'activeOrders': activeOrders,
      'totalRevenue': totalRevenue,
      'pendingKyc': pendingKyc,
      'activeEscrow': activeEscrow,
    };
  }

  AdminDashboardModel copyWith({
    int? totalUsers,
    int? totalFarmers,
    int? totalBuyers,
    int? activeProducts,
    int? activeOrders,
    double? totalRevenue,
    int? pendingKyc,
    double? activeEscrow,
  }) {
    return AdminDashboardModel(
      totalUsers: totalUsers ?? this.totalUsers,
      totalFarmers: totalFarmers ?? this.totalFarmers,
      totalBuyers: totalBuyers ?? this.totalBuyers,
      activeProducts: activeProducts ?? this.activeProducts,
      activeOrders: activeOrders ?? this.activeOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      pendingKyc: pendingKyc ?? this.pendingKyc,
      activeEscrow: activeEscrow ?? this.activeEscrow,
    );
  }
}
