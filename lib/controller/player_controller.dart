import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../dto/error_response_dto.dart';
import '../dto/player_dto.dart';

class PlayerOperationResult {
  final bool success;
  final String? errorMessage; // Internal error message for developers/logs
  final String? userMessage; // User-friendly message for UI

  PlayerOperationResult({required this.success, this.errorMessage, this.userMessage});
}

/// Controller responsible for player-related operations.
class PlayerController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];
  final http.Client _httpClient;

  PlayerController({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  String _getApiBaseUrl() {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured.',
        StackTrace.current,
        reason: 'Player controller configuration error',
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
        reason: 'Error parsing backend error response in PlayerController',
        information: [response.body, response.statusCode.toString()],
        fatal: false,
      );
      return 'An unexpected error occurred while parsing the server response. Status: ${response.statusCode}';
    }
    return 'An unknown error occurred. Status: ${response.statusCode}';
  }

  /// Fetches all players for a specific team by its ID.
  /// Returns a list of PlayerDTOs on success, an empty list on failure or no players.
  Future<List<PlayerDTO>> fetchPlayersByTeamId(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_players_by_team_attempt', parameters: {'team_id': teamId});
    FirebaseCrashlytics.instance.log('Attempting to fetch players for team: $teamId.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for fetching players. User might be logged out.');
      return [];
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/players/team/$teamId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final List<PlayerDTO> players = jsonData.map((json) => PlayerDTO.fromJson(json)).toList();
        FirebaseAnalytics.instance.logEvent(name: 'players_fetched_successfully', parameters: {'team_id': teamId, 'count': players.length});
        FirebaseCrashlytics.instance.log('Players fetched successfully for team $teamId. Count: ${players.length}');
        return players;
      } else if (response.statusCode == 404) {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.log('Team ID: $teamId not found for players. Message: $errorMessage');
        return [];
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to fetch players for team $teamId: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for fetching players',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return [];
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error fetching players',
        fatal: false,
      );
      return [];
    }
  }

  /// Fetches players for substitution (reusing the same logic for now).
  /// This method is a simple proxy to `fetchPlayersByTeamId`.
  Future<List<PlayerDTO>> fetchPlayersForSubstitution(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_players_for_sub_attempt', parameters: {'team_id': teamId});
    FirebaseCrashlytics.instance.log('Attempting to fetch players for substitution for team: $teamId.');

    return fetchPlayersByTeamId(teamId);
  }

  /// Adds a new player to a specific team.
  /// Returns PlayerOperationResult indicating success or failure.
  Future<PlayerOperationResult> addPlayer({
    required String playerName,
    required String jerseyNumber,
    required int teamId,
  }) async {
    FirebaseAnalytics.instance.logEvent(name: 'add_player_attempt', parameters: {'team_id': teamId, 'player_name': playerName});
    FirebaseCrashlytics.instance.log('Attempting to add player $playerName to team $teamId.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for adding player. User might be logged out.');
      return PlayerOperationResult(success: false, errorMessage: 'Error: Token not found.', userMessage: 'User not authenticated.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/players/team/$teamId');
      final playerDTO = PlayerDTO(playerName: playerName, jerseyNumber: jerseyNumber);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(playerDTO.toJson()),
      );

      if (response.statusCode == 201) {
        FirebaseAnalytics.instance.logEvent(name: 'player_added_successfully', parameters: {'team_id': teamId, 'player_name': playerName});
        FirebaseCrashlytics.instance.log('Player $playerName added successfully to team $teamId.');
        return PlayerOperationResult(success: true, userMessage: 'Player added successfully!');
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to add player with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for adding player',
          information: [response.body, response.request?.url.toString() ?? '', json.encode(playerDTO.toJson())],
          fatal: false,
        );
        return PlayerOperationResult(success: false, errorMessage: 'Failed to add player: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error adding player',
        fatal: false,
      );
      return PlayerOperationResult(success: false, errorMessage: 'Connection error: $e', userMessage: 'Could not add player. Check your connection.');
    }
  }

  /// Deletes a player by their ID.
  /// Returns PlayerOperationResult indicating success or failure.
  Future<PlayerOperationResult> deletePlayer(int playerId) async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_player_attempt', parameters: {'player_id': playerId});
    FirebaseCrashlytics.instance.log('Attempting to delete player: $playerId.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for deleting player. User might be logged out.');
      return PlayerOperationResult(success: false, errorMessage: 'Error: Token not found.', userMessage: 'User not authenticated.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/players/$playerId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        FirebaseAnalytics.instance.logEvent(name: 'player_deleted_successfully', parameters: {'player_id': playerId});
        FirebaseCrashlytics.instance.log('Player $playerId deleted successfully.');
        return PlayerOperationResult(success: true, userMessage: 'Player deleted successfully!');
      } else if (response.statusCode == 404) {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.log('Player ID: $playerId not found for deletion. Message: $errorMessage');
        return PlayerOperationResult(success: false, errorMessage: 'Player not found: ${response.statusCode}', userMessage: errorMessage);
      }
      else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to delete player with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for deleting player',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return PlayerOperationResult(success: false, errorMessage: 'Failed to delete player: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error deleting player',
        fatal: false,
      );
      return PlayerOperationResult(success: false, errorMessage: 'Connection error: $e', userMessage: 'Could not delete player. Check your connection.');
    }
  }

  /// Edits an existing player's information.
  /// Returns PlayerOperationResult indicating success or failure.
  Future<PlayerOperationResult> editPlayer({
    required int playerId,
    required String playerName,
    required String jerseyNumber,
  }) async {
    FirebaseAnalytics.instance.logEvent(name: 'edit_player_attempt', parameters: {'player_id': playerId, 'player_name': playerName});
    FirebaseCrashlytics.instance.log('Attempting to edit player $playerName with ID: $playerId.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for editing player. User might be logged out.');
      return PlayerOperationResult(success: false, errorMessage: 'Error: Token not found.', userMessage: 'User not authenticated.');
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/players/$playerId');
      final playerDTO = PlayerDTO(idPlayer: playerId, playerName: playerName, jerseyNumber: jerseyNumber);

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(playerDTO.toJson()),
      );

      if (response.statusCode == 200) {
        FirebaseAnalytics.instance.logEvent(name: 'player_updated_successfully', parameters: {'player_id': playerId, 'player_name': playerName});
        FirebaseCrashlytics.instance.log('Player $playerName updated successfully.');
        return PlayerOperationResult(success: true, userMessage: 'Player updated successfully!');
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to update player with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for updating player',
          information: [response.body, response.request?.url.toString() ?? '', json.encode(playerDTO.toJson())],
          fatal: false,
        );
        return PlayerOperationResult(success: false, errorMessage: 'Failed to update player: ${response.statusCode}', userMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error updating player',
        fatal: false,
      );
      return PlayerOperationResult(success: false, errorMessage: 'Connection error: $e', userMessage: 'Could not update player. Check your connection.');
    }
  }
}