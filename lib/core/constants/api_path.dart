class ApiPath {
  ApiPath._();

  static const String baseUrl = 'https://api.chashibhai.com/api/v1';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';

  // User & Profile
  static const String userProfile = '$baseUrl/user/profile';
  static const String updateProfile = '$baseUrl/user/update';

  // Products
  static const String products = '$baseUrl/products';
  static const String productCategories = '$baseUrl/products/categories';

  // Demands
  static const String demands = '$baseUrl/demands';

  // Groups
  static const String groups = '$baseUrl/groups';

  // Orders
  static const String orders = '$baseUrl/orders';

  // Wallet
  static const String wallet = '$baseUrl/wallet';
  static const String transactions = '$baseUrl/wallet/transactions';
}
