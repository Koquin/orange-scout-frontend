import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:OrangeScoutFE/dto/team_dto.dart';
import 'package:OrangeScoutFE/dto/error_response_dto.dart';

/// A class to encapsulate the result of team operations (save/update/delete).
class TeamOperationResult {
  final bool success;
  final String? errorMessage; // Error message for debugging/devs
  final String? userMessage; // User-friendly message for UI

  TeamOperationResult({required this.success, this.errorMessage, this.userMessage});
}

/// Controller responsible for team-related operations.
class TeamController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];
  final http.Client _httpClient;

  TeamController({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  String _getApiBaseUrl() {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured.',
        StackTrace.current,
        reason: 'Team controller configuration error',
        fatal: false,
      );
      throw Exception('API base URL not configured in the .env file.');
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
        reason: 'Error parsing backend error response in TeamController',
        information: [response.body, response.statusCode.toString()],
        fatal: false,
      );
      return 'An unexpected error occurred while processing the server response. Status: ${response.statusCode}';
    }
    return 'An unknown error occurred. Status: ${response.statusCode}';
  }

  // --- Team Endpoints ---

  /// Fetches all teams for the authenticated user.
  /// Returns a list of TeamDTOs on success, an empty list on failure or no teams.
  Future<List<TeamDTO>> fetchUserTeams() async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_user_teams_attempt');
    FirebaseCrashlytics.instance.log('Attempting to fetch user teams.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for fetching teams. User might be logged out.');
      return [];
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/teams');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final List<TeamDTO> teams = jsonData.map((json) => TeamDTO.fromJson(json)).toList();
        FirebaseAnalytics.instance.logEvent(name: 'teams_fetched_successfully', parameters: {'count': teams.length});
        FirebaseCrashlytics.instance.log('Teams fetched successfully. Count: ${teams.length}');
        return teams;
      } else if (response.statusCode == 204) {
        FirebaseAnalytics.instance.logEvent(name: 'no_teams_found_204');
        FirebaseCrashlytics.instance.log('No teams found (204 No Content).');
        return [];
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to fetch user teams: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for fetching user teams',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return [];
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error fetching teams',
        fatal: false,
      );
      return [];
    }
  }

  /// Saves a new team or updates an existing one.
  /// Returns TeamOperationResult indicating success or failure.
  Future<TeamOperationResult> saveOrUpdateTeam(TeamDTO teamDTO) async {
    final int? teamId = teamDTO.id;
    FirebaseAnalytics.instance.logEvent(name: 'save_or_update_team_attempt', parameters: {'team_id': teamId, 'is_new': teamId == null});
    FirebaseCrashlytics.instance.log('Attempting to save/update team. Team ID: $teamId, Name: ${teamDTO.teamName}');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for saving team. User might be logged out.');
      return TeamOperationResult(success: false, errorMessage: 'Error: Token not found.', userMessage: 'User not authenticated.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/teams');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(teamDTO.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        FirebaseAnalytics.instance.logEvent(name: 'team_saved_successfully', parameters: {'team_id': teamId, 'is_new': teamId == null});
        FirebaseCrashlytics.instance.log('Team saved successfully. ID: $teamId');
        return TeamOperationResult(success: true, userMessage: teamId == null ? 'Team created successfully!' : 'Team updated successfully!');
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to save team with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for saving team',
          information: [response.body, response.request?.url.toString() ?? '', jsonEncode(teamDTO.toJson())],
          fatal: false,
        );
        return TeamOperationResult(success: false, errorMessage: 'Failed to save team: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error saving team',
        fatal: false,
      );
      return TeamOperationResult(success: false, errorMessage: 'Connection error: $e', userMessage: 'Could not save team. Check your connection.');
    }
  }

  /// Fetches details for a specific team by its ID.
  /// Returns TeamDTO on success, null on failure.
  Future<TeamDTO?> fetchTeamDetails(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_team_details_attempt', parameters: {'team_id': teamId});
    FirebaseCrashlytics.instance.log('Attempting to fetch details for team: $teamId.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for fetching team details. User might be logged out.');
      return null;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/teams/$teamId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final teamDTO = TeamDTO.fromJson(jsonDecode(response.body));
        FirebaseAnalytics.instance.logEvent(name: 'team_details_fetched_successfully', parameters: {'team_id': teamId});
        FirebaseCrashlytics.instance.log('Team details fetched successfully. ID: $teamId.');
        return teamDTO;
      } else if (response.statusCode == 404) {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.log('Team ID: $teamId not found. Message: $errorMessage');
        return null;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to fetch team details: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for fetching team details',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return null;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error fetching team details',
        fatal: false,
      );
      return null;
    }
  }

  /// Deletes a team by its ID.
  /// Returns true on success, false on failure.
  Future<TeamOperationResult> deleteTeam(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_team_attempt', parameters: {'team_id': teamId});
    FirebaseCrashlytics.instance.log('Attempting to delete team: $teamId.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for deleting team. User might be logged out.');
      return TeamOperationResult(success: false, errorMessage: 'Error: Token not found.', userMessage: 'User not authenticated.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/teams/$teamId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        FirebaseAnalytics.instance.logEvent(name: 'team_deleted_successfully', parameters: {'team_id': teamId});
        FirebaseCrashlytics.instance.log('Team $teamId deleted successfully.');
        return TeamOperationResult(success: true, userMessage: 'Team deleted successfully!');
      } else if (response.statusCode == 404) {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.log('Team ID: $teamId not found for deletion. Message: $errorMessage');
        return TeamOperationResult(success: false, errorMessage: 'Team not found: ${response.statusCode}', userMessage: errorMessage);
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to delete team $teamId with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for deleting team',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return TeamOperationResult(success: false, errorMessage: 'Failed to delete team: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error deleting team',
        fatal: false,
      );
      return TeamOperationResult(success: false, errorMessage: 'Connection error: $e', userMessage: 'Could not delete team. Check your connection.');
    }
  }
}