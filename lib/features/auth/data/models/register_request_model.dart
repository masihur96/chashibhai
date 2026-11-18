class RegisterRequestModel {
  final String name;
  final String phone;
  final String password;
  final String role;

  const RegisterRequestModel({
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'password': password,
      'role': role,
    };
  }
}
