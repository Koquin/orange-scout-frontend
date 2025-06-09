import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../dto/error_response_dto.dart';
import '../dto/login_request_dto.dart';
import '../dto/login_response_dto.dart';
import '../dto/register_request_dto.dart';
import '../dto/validation_request_dto.dart';
import '../dto/auth_result_dto.dart';

class AuthController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];

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
      final response = await http.post(
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
          return AuthResult(success: false, errorMessage: 'Token not found in server response.', userMessage: 'Login failed: missing token.');
        }
        saveToken(loginResponse.token); // Use await for async saveToken
        FirebaseCrashlytics.instance.log('Login successful. Token saved.');
        return AuthResult(success: true, token: loginResponse.token);
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Login failed with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Login failed due to server response',
          information: [
            'Request URL: $url',
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
        fatal: true,
      );
      return AuthResult(success: false, errorMessage: 'Error connecting to the server: $e', userMessage: 'Could not connect to the server. Check your connection.');
    }
  }

  Future<AuthResult> registerUser(String username, String email, String password) async {
    FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email');
    FirebaseCrashlytics.instance.log('Registration attempt started for email: $email');

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/auth/register');
      final registerRequest = RegisterRequest(username: username, email: email, password: password);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerRequest.toJson()),
      );

      if (response.statusCode == 201) {
        FirebaseCrashlytics.instance.log('Registration successful for email: $email.');
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        saveToken(loginResponse.token); // Use await for async saveToken
        return AuthResult(success: true, token: loginResponse.token, userMessage: 'Registration successful! A validation code has been sent to your email.');
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
      return AuthResult(success: false, errorMessage: 'Error connecting to the server: $e', userMessage: 'Could not connect to the server. Check your connection.');
    }
  }

  Future<bool> isTokenExpiredBackendCheck(String? token) async {
    FirebaseAnalytics.instance.logEvent(name: 'check_token_expired_attempt');
    FirebaseCrashlytics.instance.log('Attempting to check if token is expired with backend.');

    if (token == null || token.isEmpty) {
      FirebaseCrashlytics.instance.log('Token is null or empty, client-side considers it expired/invalid.');
      return true;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/auth/isTokenExpired');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        bool isExpired = jsonDecode(response.body) as bool;
        FirebaseCrashlytics.instance.log('Backend token expiration check result: $isExpired');
        return isExpired;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Backend token expiration check failed with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for token expiration check',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return true;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error checking token expiration with backend',
        fatal: false,
      );
      return true;
    }
  }

  Future<AuthResult> checkUserValidationStatus() async {
    FirebaseAnalytics.instance.logEvent(name: 'check_user_validation_status');
    FirebaseCrashlytics.instance.log('Attempting to check user validation status.');

    final String? token = await loadToken();
    if (token == null || token.isEmpty) {
      return AuthResult(success: false, errorMessage: 'No token found for validation status check.', userMessage: 'User not authenticated.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/auth/isValidated');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        bool isValidated = jsonDecode(response.body) as bool;
        FirebaseCrashlytics.instance.log('User validation status: $isValidated');
        return AuthResult(success: true, userMessage: isValidated ? 'Account validated.' : 'Account not validated.', token: isValidated.toString());
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
      return AuthResult(success: false, errorMessage: 'Error connecting to the server: $e', userMessage: 'Could not verify validation status.');
    }
  }

  Future<AuthResult> sendValidationCode() async {
    FirebaseAnalytics.instance.logEvent(name: 'send_validation_code_attempt');
    FirebaseCrashlytics.instance.log('Attempting to send validation code.');

    final String? token = await loadToken();
    if (token == null || token.isEmpty) {
      return AuthResult(success: false, errorMessage: 'No token found for sending validation code.', userMessage: 'User not authenticated to resend code.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/auth/resendValidationCode');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        FirebaseCrashlytics.instance.log('Validation code sent successfully');
        return AuthResult(success: true, userMessage: response.body);
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
      return AuthResult(success: false, errorMessage: 'Error connecting to the server: $e', userMessage: 'Could not send validation code.');
    }
  }

  Future<AuthResult> validateUserAccount(String code) async {
    FirebaseAnalytics.instance.logEvent(name: 'validate_user_account_attempt');
    FirebaseCrashlytics.instance.log('Attempting to validate user account with code: $code');

    final String? token = await loadToken();
    if (token == null || token.isEmpty) {
      return AuthResult(success: false, errorMessage: 'No token found for validating account.', userMessage: 'User not authenticated to validate account.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/auth/validate');
      final validationRequest = ValidationRequest(code: code);

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(validationRequest.toJson()),
      );

      if (response.statusCode == 200) {
        FirebaseCrashlytics.instance.log('User account validated successfully.');
        return AuthResult(success: true, userMessage: response.body);
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
      return AuthResult(success: false, errorMessage: 'Error connecting to the server: $e', userMessage: 'Could not validate your account. Check the code.');
    }
  }
}