import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class LoginResult {
  final bool success;
  final String? token;
  final String? errorMessage;

  LoginResult({required this.success, this.token, this.errorMessage});
}

class RegisterResult {
  final bool success;
  final String? errorMessage;

  RegisterResult({required this.success, this.errorMessage});
}

class AuthController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];

  Future<LoginResult> loginUser(String email, String password) async {
    FirebaseCrashlytics.instance.log('Login attempt started for email: $email');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured.',
        StackTrace.current,
        reason: 'Auth service configuration error',
        fatal: false,
      );
      print('API base URL not configured.');
      return LoginResult(
          success: false, errorMessage: 'API base URL not configured.');
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String? token = responseData['token'];
        print("Success logging in! token: ${token}");
        if (token == null || token.isEmpty) {
          FirebaseCrashlytics.instance.recordError(
            'Token not found in server response.',
            StackTrace.current,
            reason: 'Login successful, but token is missing or empty',
            information: [response.body],
            fatal: false,
          );
          print("Token not found in server response.");
          return LoginResult(success: false,
              errorMessage: "Token not found in server response.");
        }
        print("Token being saved...");
        saveToken(token);
        FirebaseCrashlytics.instance.log('Login successful. Token saved.');
        return LoginResult(success: true, token: token);
      } else {
        String errorMsg = 'Invalid credentials';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData != null && errorData is Map &&
              errorData.containsKey('message')) {
            errorMsg = errorData['message'];
          } else if (errorData != null && errorData is String &&
              errorData.isNotEmpty) {
            errorMsg = errorData;
          }
        } catch (e, s) {
          FirebaseCrashlytics.instance.recordError(
            e, s,
            reason: 'Error parsing backend error response during login',
            information: [response.body],
            fatal: false,
          );
          print('Error parsing backend error response: $e');
        }

        FirebaseCrashlytics.instance.recordError(
          'Login failed with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Login failed due to server response',
          information: [
            'Request URL: ${response.request?.url.toString() ?? 'unknown'}',
            'Response body: ${response.body}',
            'Email attempted: $email'
          ],
          fatal: false,
        );
        print(errorMsg);
        return LoginResult(success: false, errorMessage: errorMsg);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Login failed due to network or unexpected error',
        fatal: false,
      );
      print('Error connecting to the server: ${e.toString()}');
      return LoginResult(success: false,
          errorMessage: 'Error connecting to the server: ${e.toString()}');
    }
  }

  Future<RegisterResult> registerUser(String username, String email,
      String password) async {
    FirebaseCrashlytics.instance.log(
        'Registration attempt started for email: $email');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for registration.',
        StackTrace.current,
        reason: 'Auth service configuration error',
        fatal: false,
      );
      print('API base URL not configured for registration.');
      return RegisterResult(
          success: false, errorMessage: 'API base URL not configured.');
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/register"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) { // Sucesso no registro
        FirebaseCrashlytics.instance.log(
            'Registration successful for email: $email.');
        return RegisterResult(success: true);
      } else {
        // Erro do servidor durante o registro (ex: usuário já existe)
        String errorMsg = 'Registration failed. Please try again.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData != null && errorData is Map &&
              errorData.containsKey('message')) {
            errorMsg = errorData['message'];
          } else if (errorData != null && errorData is String &&
              errorData.isNotEmpty) {
            errorMsg = errorData;
          }
        } catch (e, s) { // Erro ao parsear resposta de erro
          FirebaseCrashlytics.instance.recordError(
            e, s,
            reason: 'Error parsing backend error response during registration',
            information: [response.body],
            fatal: false,
          );
          print('Error parsing backend error response during registration: $e');
        }

        // Registra o erro não fatal no Crashlytics para falha de registro HTTP
        FirebaseCrashlytics.instance.recordError(
          'Registration failed with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Registration failed due to server response',
          information: [
            'Request URL: ${response.request?.url.toString() ?? 'unknown'}',
            'Response body: ${response.body}',
            'Email attempted: $email'
          ],
          fatal: false,
        );
        print(errorMsg);
        return RegisterResult(success: false, errorMessage: errorMsg);
      }
    } catch (e, s) { // Erro de conexão ou outras exceções inesperadas
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Registration failed due to network or unexpected error',
        fatal: false,
      );
      print('Error connecting to the server: ${e.toString()}');
      return RegisterResult(success: false,
          errorMessage: 'Error connecting to the server: ${e.toString()}');
    }
  }

  Future<bool> isTokenExpired(String? token) async {
    FirebaseAnalytics.instance.logEvent(name: 'check_token_expired_attempt');
    FirebaseCrashlytics.instance.log(
        'Attempting to check if token is expired.');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for token validation check.',
        StackTrace.current,
        reason: 'Auth service configuration error',
        fatal: false,
      );
      print('API base URL not configured for token validation check.');
      return false; // Ou true, dependendo de como você quer tratar config inválida aqui
    }
    if (token == null || token.isEmpty) {
      FirebaseCrashlytics.instance.log(
          'Token is null or empty, considered expired/invalid.');
      return true; // Token nulo ou vazio é considerado expirado para esta verificação
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/isTokenInvalid'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        bool isInvalid = response.body.trim().toLowerCase() == 'true';
        FirebaseAnalytics.instance.logEvent(
          name: 'token_invalidity_status',
          parameters: {'is_Invalid': isInvalid},
        );
        FirebaseCrashlytics.instance.log('Token invalidity status: $isInvalid');
        // Se a resposta é "true", o token é inválido. Se "false", é valido.
        return isInvalid; // Retorna true se !isInvalid (ou seja, se for true do backend)
      } else if (response.statusCode == 403) {
        FirebaseAnalytics.instance.logEvent(
            name: 'token_validation_failed', parameters: {'http_status': 403});
        FirebaseCrashlytics.instance.log(
            'Token validation failed with 403 (Forbidden).');
        return true;
      } else {
        FirebaseCrashlytics.instance.recordError(
          'Failed to validate token: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for token validation',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        print('Failed to validate token: ${response.statusCode}');
        FirebaseAnalytics.instance.logEvent(name: 'token_validation_failed',
            parameters: {'http_status': response.statusCode});
        return true;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error checking token validity',
        fatal: false,
      );
      print('Connection error checking token validity: $e');
      FirebaseAnalytics.instance.logEvent(name: 'token_validation_failed',
          parameters: {'reason': 'connection_error'});
      return false;
    }
  }

  Future<bool> checkUserValidation() async {
    String? token = await loadToken();

    try {
      final response = await http.get(
          Uri.parse('$_baseUrl/auth/isValidated'),
          headers: {
            'Authorization' : 'Bearer $token',
            'Content-Type': 'application/json',
          }
      );

      if (response.statusCode == 200) {
        if (response.body.trim().toLowerCase() == 'true'){
          return true;
        }
        else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

}