class AppUserDTO {
  final int? id;
  final String email;
  final String username;
  final bool validated;
  final bool premium;
  final String role;

  AppUserDTO({
    this.id,
    required this.email,
    required this.username,
    required this.validated,
    required this.premium,
    required this.role,
  });

  factory AppUserDTO.fromJson(Map<String, dynamic> json) {
    return AppUserDTO(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      validated: json['validated'],
      premium: json['premium'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'validated': validated,
    'premium': premium,
    'role': role,
  };
}