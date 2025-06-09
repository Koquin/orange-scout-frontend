import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../dto/error_response_dto.dart';
import '../dto/match_dto.dart';
import '../dto/stats_dto.dart';

class MatchController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];
  final http.Client _httpClient;

  MatchController({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  String _getApiBaseUrl() {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured.',
        StackTrace.current,
        reason: 'Match controller configuration error',
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
        reason: 'Error parsing backend error response in MatchController',
        information: [response.body, response.statusCode.toString()],
        fatal: false,
      );
      return 'An unexpected error occurred parsing server response. Status: ${response.statusCode}';
    }
    return 'An unknown error occurred. Status: ${response.statusCode}';
  }

  /// Checks for the last unfinished match for the authenticated user.
  /// Returns MatchDTO if found, null otherwise.
  Future<MatchDTO?> checkLastUnfinishedMatch() async {
    FirebaseAnalytics.instance.logEvent(name: 'check_last_unfinished_match_attempt');
    FirebaseCrashlytics.instance.log('Attempting to check for last unfinished match.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for checking last unfinished match. User might be logged out.');
      return null;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/matches/last-unfinished');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final matchDTO = MatchDTO.fromJson(jsonDecode(response.body));
        FirebaseAnalytics.instance.logEvent(name: 'last_unfinished_match_found', parameters: {'match_id': matchDTO.idMatch});
        FirebaseCrashlytics.instance.log('Last unfinished match found: ID ${matchDTO.idMatch}.');
        return matchDTO;
      } else if (response.statusCode == 204) {
        FirebaseAnalytics.instance.logEvent(name: 'no_unfinished_match_found_204');
        FirebaseCrashlytics.instance.log('No unfinished match found (204 No Content).');
        return null;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Error checking last unfinished match: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for last unfinished match',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return null;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error checking last unfinished match',
        fatal: false,
      );
      return null;
    }
  }

  /// Finishes a match by setting its 'finished' status to true.
  /// Returns true on success, false on failure.
  Future<bool> finishMatch(int matchId) async {
    FirebaseAnalytics.instance.logEvent(name: 'finish_match_attempt', parameters: {'match_id': matchId});
    FirebaseCrashlytics.instance.log('Attempting to finish match: $matchId');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for finishing match. User might be logged out.');
      return false;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/matches/finish/$matchId');
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        FirebaseAnalytics.instance.logEvent(name: 'match_finished_successfully', parameters: {'match_id': matchId});
        FirebaseCrashlytics.instance.log('Match $matchId finished successfully.');
        return true;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to finish match $matchId: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for finishing match',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error finishing match',
        fatal: false,
      );
      return false;
    }
  }

  /// Saves a new match or updates an existing match's progress.
  /// Returns the match ID on success, null on failure.
  Future<int?> saveOrUpdateMatch(MatchDTO matchDTO) async {
    FirebaseAnalytics.instance.logEvent(name: 'save_or_update_match_attempt', parameters: {'game_mode': matchDTO.gameMode, 'is_finished': matchDTO.finished.toString(), 'match_id': matchDTO.idMatch});
    FirebaseCrashlytics.instance.log('Attempting to save/update match for game mode: ${matchDTO.gameMode}, finished: ${matchDTO.finished}, matchId: ${matchDTO.idMatch}');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for saving match. User might be logged out.');
      return null;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/matches');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(matchDTO.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        final newMatchId = responseBody['matchId'];

        FirebaseAnalytics.instance.logEvent(name: 'match_saved_successfully', parameters: {'game_mode': matchDTO.gameMode, 'is_finished': matchDTO.finished.toString(), 'match_id': newMatchId});
        FirebaseCrashlytics.instance.log('Match saved successfully. ID: $newMatchId');
        return newMatchId;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Error saving match: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for saving match',
          information: [response.body, response.request?.url.toString() ?? '', jsonEncode(matchDTO.toJson())],
          fatal: false,
        );
        return null;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error saving match',
        fatal: false,
      );
      return null;
    }
  }

  /// Fetches all finished matches for the authenticated user.
  /// Returns a list of MatchDTOs on success, an empty list on failure or no matches.
  Future<List<MatchDTO>> fetchUserMatches() async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_user_matches_attempt');
    FirebaseCrashlytics.instance.log('Attempting to fetch user matches from controller.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for fetching user matches. User might be logged out.');
      return [];
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/matches/user-history');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final List<MatchDTO> matches = jsonData.map((json) => MatchDTO.fromJson(json)).toList();
        FirebaseAnalytics.instance.logEvent(name: 'user_matches_fetched_successfully', parameters: {'count': matches.length});
        FirebaseCrashlytics.instance.log('User matches fetched successfully. Count: ${matches.length}');
        return matches;
      } else if (response.statusCode == 204) {
        FirebaseAnalytics.instance.logEvent(name: 'no_user_matches_found_204');
        FirebaseCrashlytics.instance.log('No user matches found (204 No Content).');
        return [];
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to fetch user matches: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for fetching user matches',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return [];
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error fetching user matches',
        fatal: false,
      );
      return [];
    }
  }

  /// Deletes a match by its ID.
  /// Returns true on success, false on failure.
  Future<bool> deleteMatch(int matchId) async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_match_attempt', parameters: {'match_id': matchId});
    FirebaseCrashlytics.instance.log('Attempting to delete match: $matchId');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for deleting match. User might be logged out.');
      return false;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/matches/$matchId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        FirebaseAnalytics.instance.logEvent(name: 'match_deleted_successfully', parameters: {'match_id': matchId});
        FirebaseCrashlytics.instance.log('Match $matchId deleted successfully.');
        return true;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to delete match $matchId: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for deleting match',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error deleting match',
        fatal: false,
      );
      return false;
    }
  }

  /// Fetches all stats for a specific match from the backend.
  /// Returns a list of StatsDTO on success, null on failure.
  Future<List<StatsDTO>?> fetchMatchStats(int matchId) async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_match_stats_attempt', parameters: {'match_id': matchId});
    FirebaseCrashlytics.instance.log('Attempting to fetch stats for match: $matchId from backend.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for fetching match stats. User might be logged out.');
      return null;
    }

    try {
      final statsUrl = Uri.parse('${_getApiBaseUrl()}/stats/match/$matchId');
      final response = await http.get(
        statsUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final List<StatsDTO> stats = jsonData.map((json) => StatsDTO.fromJson(json)).toList();
        FirebaseAnalytics.instance.logEvent(name: 'match_stats_fetched_successfully', parameters: {'match_id': matchId, 'count': stats.length});
        FirebaseCrashlytics.instance.log('Match stats fetched successfully for ID: $matchId. Count: ${stats.length}');
        return stats;
      } else if (response.statusCode == 404) {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.log('Match ID: $matchId not found for stats. Message: $errorMessage');
        return null;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to fetch match stats: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for fetching match stats',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return null;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error fetching match stats',
        fatal: false,
      );
      return null;
    }
  }

  Future<MatchDTO?> getMatchById(int matchId) async {
    FirebaseAnalytics.instance.logEvent(name: 'get_match_by_id_attempt', parameters: {'match_id': matchId});
    FirebaseCrashlytics.instance.log('Attempting to get match for ID: $matchId from backend.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('No token found for getMatchById. User might be logged out.');
      return null;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/matches/$matchId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final matchDTO = MatchDTO.fromJson(jsonDecode(response.body));
        FirebaseCrashlytics.instance.log('Match ID: $matchId retrieved successfully.');
        return matchDTO;
      } else if (response.statusCode == 404) {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.log('Match ID: $matchId not found. Message: $errorMessage');
        return null;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to retrieve match: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for getMatchById',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return null;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error retrieving match by ID',
        fatal: false,
      );
      return null;
    }
  }

  Future<bool> validateStartGame() async {
    FirebaseAnalytics.instance.logEvent(name: 'validate_start_game_attempt');
    FirebaseCrashlytics.instance.log('Attempting to validate if user can start a game.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for validateStartGame. User might be logged out.');
      return false;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/matches/validate-start');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        bool canStart = jsonDecode(response.body) as bool;
        FirebaseAnalytics.instance.logEvent(name: 'validate_start_game_result', parameters: {'can_start': canStart.toString()});
        FirebaseCrashlytics.instance.log('User can start game: $canStart');
        return canStart;
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to validate start game: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for validateStartGame',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error validating start game',
        fatal: false,
      );
      return false;
    }
  }

}