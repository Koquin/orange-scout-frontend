import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../dto/app_user_dto.dart';
import '../dto/error_response_dto.dart';

class UserController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];
  final http.Client _httpClient;

  UserController({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  String _getApiBaseUrl() {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured.',
        StackTrace.current,
        reason: 'User controller configuration error',
        fatal: false,
      );
      throw Exception('API base URL not configured in .env file.');
    }
    return _baseUrl!;
  }

  // Helper to parse backend error responses (same as in AuthController)
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
      if (errorResponse.details != null && errorResponse.details!.isNotEmpty) {
        return errorResponse.details!.values.join('\n');
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Error parsing backend error response in UserController',
        information: [response.body, response.statusCode.toString()],
        fatal: false,
      );
      return 'An unexpected error occurred parsing server response. Status: ${response.statusCode}';
    }
    return 'An unknown error occurred. Status: ${response.statusCode}';
  }

  // --- Consolidated/Updated User Endpoints ---

  // REMOVED: checkUserValidation() as it's now in AuthController.
  // The backend's /auth/isValidated is handled by AuthController.

  // REMOVED: checkUserTeams() as it's now in MatchController.
  // The backend's /matches/validate-start is handled by MatchController.

  /// Fetches the premium status of the authenticated user.
  /// Returns true if the user is premium, false otherwise (or on error).
  Future<bool> isUserPremium() async {
    FirebaseAnalytics.instance.logEvent(name: 'check_user_premium_status_attempt');
    FirebaseCrashlytics.instance.log('Attempting to check user premium status.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for checking premium status. User might be logged out.');
      return false;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/app-users/premium'); // PADRONIZAÇÃO: /app-users/premium
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        bool isPremium = jsonDecode(response.body); // Backend returns boolean directly
        FirebaseAnalytics.instance.logEvent(
          name: 'user_premium_status',
          parameters: {'is_premium': isPremium},
        );
        FirebaseCrashlytics.instance.log('User premium status: $isPremium');
        return isPremium;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to check user premium status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for user premium status',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error checking user premium status',
        fatal: false,
      );
      return false;
    }
  }

  // --- Admin/User Profile Endpoints (if needed for user's own profile management) ---

  /// Fetches details of the authenticated user's own profile.
  /// Returns AppUserDTO on success, null on failure.
  Future<AppUserDTO?> fetchMyProfile() async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_my_profile_attempt');
    FirebaseCrashlytics.instance.log('Attempting to fetch authenticated user\'s profile.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('No token found for fetching profile. User might be logged out.');
      return null;
    }

    try {
      FirebaseCrashlytics.instance.log('Fetching user profile requires a dedicated backend /app-users/me endpoint or handling via login response data.');
      return null;
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error fetching user profile',
        fatal: false,
      );
      return null;
    }
  }

  // --- Admin-level operations on users, if exposed to specific frontend roles ---
  // These would typically be used by an admin dashboard, not a regular user app.
  // Ensure your frontend's role-based access control (RBAC) handles this correctly.

  /// Fetches a list of all AppUserDTOs (admin only on backend).
  Future<List<AppUserDTO>> fetchAllUsersAdmin() async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_all_users_admin_attempt');
    FirebaseCrashlytics.instance.log('Attempting to fetch all users (Admin).');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('No token for fetchAllUsersAdmin. User might be logged out.');
      return [];
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/app-users');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final List<AppUserDTO> users = jsonData.map((json) => AppUserDTO.fromJson(json)).toList();
        FirebaseCrashlytics.instance.log('All users fetched successfully (Admin). Count: ${users.length}');
        return users;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to fetch all users (Admin): ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for fetchAllUsersAdmin',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return [];
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Connection error fetching all users (Admin)', fatal: false);
      return [];
    }
  }

  /// Updates an AppUser (Admin only on backend).
  Future<bool> updateAppUserAdmin(int userId, AppUserDTO userDTO) async {
    FirebaseAnalytics.instance.logEvent(name: 'update_app_user_admin_attempt', parameters: {'user_id': userId});
    FirebaseCrashlytics.instance.log('Attempting to update user ID: $userId (Admin).');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('No token for updateAppUserAdmin. User might be logged out.');
      return false;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/app-users/$userId');
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userDTO.toJson()),
      );

      if (response.statusCode == 200) {
        FirebaseCrashlytics.instance.log('User ID: $userId updated successfully (Admin).');
        return true;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to update user ID: $userId (Admin): ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for updateAppUserAdmin',
          information: [response.body, response.request?.url.toString() ?? '', jsonEncode(userDTO.toJson())],
          fatal: false,
        );
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Connection error updating user (Admin)', fatal: false);
      return false;
    }
  }

  /// Deletes an AppUser (Admin only on backend).
  Future<bool> deleteAppUserAdmin(int userId) async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_app_user_admin_attempt', parameters: {'user_id': userId});
    FirebaseCrashlytics.instance.log('Attempting to delete user ID: $userId (Admin).');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('No token for deleteAppUserAdmin. User might be logged out.');
      return false;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/app-users/$userId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        FirebaseCrashlytics.instance.log('User ID: $userId deleted successfully (Admin).');
        return true;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to delete user ID: $userId (Admin): ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for deleteAppUserAdmin',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Connection error deleting user (Admin)', fatal: false);
      return false;
    }
  }
}
