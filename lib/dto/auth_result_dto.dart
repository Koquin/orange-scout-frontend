// lib/dto/auth_result.dart
class AuthResult {
  final bool success;
  final String? token; // Only for login/registration that returns a token
  final String? errorMessage; // Internal error message for developers/logs
  final String? userMessage; // User-friendly message for UI

  AuthResult({required this.success, this.token, this.errorMessage, this.userMessage});
}