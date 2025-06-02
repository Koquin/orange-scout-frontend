import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../dto/error_response_dto.dart';
import '../dto/login_request_dto.dart';
import '../dto/login_response_dto.dart';
import '../dto/register_request_dto.dart';
import '../dto/validation_request_dto.dart';
import '../dto/auth_result_dto.dart';

class AuthController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];
  final http.Client _httpClient; // Use an injected http client for testing

  AuthController({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  String _getApiBaseUrl() {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured.',
        StackTrace.current,
        reason: 'Auth service configuration error',
        fatal: false,
      );
      throw Exception('API base URL not configured in .env file.');
    }
    return _baseUrl!;
  }

  // Helper to parse backend error responses
  String _parseBackendErrorMessage(http.Response response) {
    try {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      final errorResponse = ErrorResponse.fromJson(errorData);

      if (errorResponse.message != null && errorResponse.message!.isNotEmpty) {
        return errorResponse.message!;
      }
      if (errorResponse.error != null && errorResponse.error!.isNotEmpty) {
        return errorResponse.error!;
      }
      // For validation errors, concatenate details
      if (errorResponse.details != null && errorResponse.details!.isNotEmpty) {
        return errorResponse.details!.values.join('\n');
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Error parsing backend error response',
        information: [response.body, response.statusCode.toString()],
        fatal: false,
      );
      return 'An unexpected error occurred. Status: ${response.statusCode}';
    }
    return 'An unknown error occurred. Status: ${response.statusCode}';
  }

  // --- Auth Endpoints ---

  Future<AuthResult> loginUser(String email, String password) async {
    FirebaseAnalytics.instance.logLogin(loginMethod: 'email');
    FirebaseCrashlytics.instance.log('Login attempt started for email: $email');

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/auth/login');
      final loginRequest = LoginRequest(email: email, password: password);

      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginRequest.toJson()),
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        if (loginResponse.token.isEmpty) {
          FirebaseCrashlytics.instance.recordError(
            'Token not found in server response.',
            StackTrace.current,
            reason: 'Login successful, but token is missing or empty',
            information: [response.body],
            fatal: false,
          );
          return AuthResult(success: false, errorMessage: 'Token not found in server response.', userMessage: 'Falha no login: token ausente.');
        }
        saveToken(loginResponse.token);
        FirebaseCrashlytics.instance.log('Login successful. Token saved.');
        return AuthResult(success: true, token: loginResponse.token);
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Login failed with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Login failed due to server response',
          information: [
            'Request URL: ${url}',
            'Response body: ${response.body}',
            'Email attempted: $email'
          ],
          fatal: false,
        );
        return AuthResult(success: false, errorMessage: 'Login failed: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Login failed due to network or unexpected error',
        fatal: true, // Fatal error if it's a network/unexpected crash
      );
      return AuthResult(success: false, errorMessage: 'Error connecting to the server: $e', userMessage: 'Não foi possível conectar ao servidor. Verifique sua conexão.');
    }
  }

  Future<AuthResult> registerUser(String username, String email, String password) async {
    FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email');
    FirebaseCrashlytics.instance.log('Registration attempt started for email: $email');

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/auth/register');
      final registerRequest = RegisterRequest(username: username, email: email, password: password);

      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerRequest.toJson()),
      );

      if (response.statusCode == 201) { // Backend returns 201 CREATED for successful registration
        FirebaseCrashlytics.instance.log('Registration successful for email: $email.');
        // Backend returns LoginResponse on successful registration, so we parse it and save the token
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        saveToken(loginResponse.token);
        return AuthResult(success: true, token: loginResponse.token, userMessage: 'Registro realizado com sucesso! Um código de validação foi enviado para seu e-mail.');
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Registration failed with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Registration failed due to server response',
          information: [
            'Request URL: $url',
            'Response body: ${response.body}',
            'Email attempted: $email'
          ],
          fatal: false,
        );
        return AuthResult(success: false, errorMessage: 'Registration failed: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Registration failed due to network or unexpected error',
        fatal: true,
      );
      return AuthResult(success: false, errorMessage: 'Error connecting to the server: $e', userMessage: 'Não foi possível conectar ao servidor. Verifique sua conexão.');
    }
  }

  Future<bool> isTokenExpiredBackendCheck(String? token) async {
    FirebaseAnalytics.instance.logEvent(name: 'check_token_expired_attempt');
    FirebaseCrashlytics.instance.log('Attempting to check if token is expired with backend.');

    if (token == null || token.isEmpty) {
      FirebaseCrashlytics.instance.log('Token is null or empty, client-side considers it expired/invalid.');
      return true; // Token null/empty is considered expired/invalid client-side
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/auth/isTokenExpired'); // Updated endpoint name
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        bool isExpired = response.body.trim().toLowerCase() == 'true'; // Backend returns true if expired
        FirebaseCrashlytics.instance.log('Backend token expiration check result: $isExpired');
        return isExpired;
      } else {
        // Any non-200 status indicates a problem, so we treat it as expired/invalid from client perspective
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Backend token expiration check failed with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for token expiration check',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return true; // Treat as expired/invalid if backend call fails
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error checking token expiration with backend',
        fatal: false, // Not necessarily fatal if it's just connectivity for this check
      );
      return true; // Assume expired/invalid on network error to prompt re-login
    }
  }

  Future<AuthResult> checkUserValidationStatus() async {
    FirebaseAnalytics.instance.logEvent(name: 'check_user_validation_status');
    FirebaseCrashlytics.instance.log('Attempting to check user validation status.');

    final String? token = await loadToken();
    if (token == null || token.isEmpty) {
      return AuthResult(success: false, errorMessage: 'No token found for validation status check.', userMessage: 'Usuário não autenticado.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/auth/isValidated');
      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        bool isValidated = response.body.trim().toLowerCase() == 'true';
        FirebaseCrashlytics.instance.log('User validation status: $isValidated');
        return AuthResult(success: true, userMessage: isValidated ? 'Conta validada.' : 'Conta não validada.', token: isValidated.toString()); // Token field misused for isValidated status
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'User validation status check failed with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for validation status',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return AuthResult(success: false, errorMessage: 'Validation status check failed: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error checking user validation status',
        fatal: false,
      );
      return AuthResult(success: false, errorMessage: 'Error connecting to the server: $e', userMessage: 'Não foi possível verificar status de validação.');
    }
  }

  Future<AuthResult> sendValidationCode() async {
    FirebaseAnalytics.instance.logEvent(name: 'send_validation_code_attempt');
    FirebaseCrashlytics.instance.log('Attempting to send validation code.');

    final String? token = await loadToken();
    if (token == null || token.isEmpty) {
      return AuthResult(success: false, errorMessage: 'No token found for sending validation code.', userMessage: 'Usuário não autenticado para reenviar código.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/auth/resendValidationCode');
      final response = await _httpClient.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        FirebaseCrashlytics.instance.log('Validation code sent successfully');
        return AuthResult(success: true, userMessage: response.body); // Backend returns a string message directly
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Sending validation code failed with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for sending validation code',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return AuthResult(success: false, errorMessage: 'Failed to send code: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error sending validation code',
        fatal: false,
      );
      return AuthResult(success: false, errorMessage: 'Error connecting to the server: $e', userMessage: 'Não foi possível enviar o código de validação.');
    }
  }

  Future<AuthResult> validateUserAccount(String code) async {
    FirebaseAnalytics.instance.logEvent(name: 'validate_user_account_attempt');
    FirebaseCrashlytics.instance.log('Attempting to validate user account with code: $code');

    final String? token = await loadToken();
    if (token == null || token.isEmpty) {
      return AuthResult(success: false, errorMessage: 'No token found for validating account.', userMessage: 'Usuário não autenticado para validar conta.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/auth/validate');
      final validationRequest = ValidationRequest(code: code);

      final response = await _httpClient.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(validationRequest.toJson()),
      );

      if (response.statusCode == 200) {
        FirebaseCrashlytics.instance.log('User account validated successfully.');
        return AuthResult(success: true, userMessage: response.body); // Backend returns a string message directly
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Account validation failed with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for account validation',
          information: [response.body, response.request?.url.toString() ?? '', 'Code submitted: $code'],
          fatal: false,
        );
        return AuthResult(success: false, errorMessage: 'Account validation failed: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error validating user account',
        fatal: false,
      );
      return AuthResult(success: false, errorMessage: 'Error connecting to the server: $e', userMessage: 'Não foi possível validar sua conta. Verifique o código.');
    }
  }
}