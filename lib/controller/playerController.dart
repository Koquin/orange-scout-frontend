// lib/controller/player_controller.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Uma classe para encapsular o resultado da operação de salvar/atualizar jogador.
class PlayerOperationResult {
  final bool success;
  final String? errorMessage;

  PlayerOperationResult({required this.success, this.errorMessage});
}

/// Controlador responsável por operações relacionadas a jogadores.
class PlayerController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];

  Future<List<dynamic>> fetchPlayersByTeamId(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_players_by_team_attempt', parameters: {'team_id': teamId});
    FirebaseCrashlytics.instance.log('Attempting to fetch players for team: $teamId');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for fetching players.',
        StackTrace.current,
        reason: 'Player controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for fetching players.');
      return [];
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for fetching players. User might be logged out.');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/player/team-players/$teamId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        FirebaseAnalytics.instance.logEvent(name: 'players_fetched_successfully', parameters: {'team_id': teamId, 'count': data.length});
        FirebaseCrashlytics.instance.log('Players fetched successfully for team $teamId. Count: ${data.length}');
        return data;
      } else {
        FirebaseCrashlytics.instance.recordError(
          'Failed to fetch players for team $teamId: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for fetching players',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        print('Error fetching players for team $teamId: ${response.statusCode}');
        FirebaseAnalytics.instance.logEvent(
          name: 'fetch_players_failed',
          parameters: {'team_id': teamId, 'http_status': response.statusCode},
        );
        return [];
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error fetching players',
        fatal: false,
      );
      print('Requisition error fetching players: $e');
      FirebaseAnalytics.instance.logEvent(name: 'fetch_players_failed', parameters: {'team_id': teamId, 'reason': 'connection_error'});
      return [];
    }
  }

  Future<List<dynamic>> fetchPlayersForSubstitution(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_players_for_sub_attempt', parameters: {'team_id': teamId});
    FirebaseCrashlytics.instance.log('Attempting to fetch players for substitution for team: $teamId');

    return fetchPlayersByTeamId(teamId);
  }

  /// Adiciona um novo jogador a um time.
  /// Retorna PlayerOperationResult indicando sucesso ou falha.
  Future<PlayerOperationResult> addPlayer({
    required String playerName,
    required String jerseyNumber,
    required int teamId,
  }) async {
    FirebaseAnalytics.instance.logEvent(name: 'add_player_attempt', parameters: {'team_id': teamId, 'player_name': playerName});
    FirebaseCrashlytics.instance.log('Attempting to add player $playerName to team $teamId.');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for adding player.',
        StackTrace.current,
        reason: 'Player controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for adding player.');
      return PlayerOperationResult(success: false, errorMessage: 'API base URL not configured.');
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for adding player. User might be logged out.');
      return PlayerOperationResult(success: false, errorMessage: 'Error: Token not found.');
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/player"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({
          'playerName': playerName,
          'jerseyNumber': jerseyNumber,
          'team': {'id': teamId},
        }),
      );

      if (response.statusCode == 201) {
        FirebaseAnalytics.instance.logEvent(name: 'player_added_successfully', parameters: {'team_id': teamId, 'player_name': playerName});
        FirebaseCrashlytics.instance.log('Player $playerName added successfully to team $teamId.');
        return PlayerOperationResult(success: true);
      } else {
        String errorMessage = "Error adding player: ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }
        } catch (e, s) {
          FirebaseCrashlytics.instance.recordError(
            e, s,
            reason: 'Error parsing backend error response for adding player',
            information: [response.body],
            fatal: false,
          );
          print('Error parsing backend error response: $e');
        }
        FirebaseCrashlytics.instance.recordError(
          'Failed to add player with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for adding player',
          information: [response.body, response.request?.url.toString() ?? '', json.encode({'playerName': playerName, 'jerseyNumber': jerseyNumber})],
          fatal: false,
        );
        print("Error adding player: ${response.body}");
        FirebaseAnalytics.instance.logEvent(name: 'add_player_failed', parameters: {'http_status': response.statusCode, 'response_body': response.body});
        return PlayerOperationResult(success: false, errorMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error adding player',
        fatal: false,
      );
      print("Error adding player: $e");
      FirebaseAnalytics.instance.logEvent(name: 'add_player_failed', parameters: {'reason': 'connection_error', 'error_details': e.toString()});
      return PlayerOperationResult(success: false, errorMessage: 'Unknown error: ${e.toString()}');
    }
  }

  /// Deleta um jogador.
  /// Retorna PlayerOperationResult indicando sucesso ou falha.
  Future<PlayerOperationResult> deletePlayer(int playerId) async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_player_attempt', parameters: {'player_id': playerId});
    FirebaseCrashlytics.instance.log('Attempting to delete player: $playerId');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for deleting player.',
        StackTrace.current,
        reason: 'Player controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for deleting player.');
      return PlayerOperationResult(success: false, errorMessage: 'API base URL not configured.');
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for deleting player. User might be logged out.');
      return PlayerOperationResult(success: false, errorMessage: 'Error: Token not found.');
    }

    try {
      final response = await http.delete(
        Uri.parse("$_baseUrl/player/$playerId"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        FirebaseAnalytics.instance.logEvent(name: 'player_deleted_successfully', parameters: {'player_id': playerId});
        FirebaseCrashlytics.instance.log('Player $playerId deleted successfully.');
        return PlayerOperationResult(success: true);
      } else {
        String errorMessage = "Error deleting player: ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }
        } catch (e, s) {
          FirebaseCrashlytics.instance.recordError(
            e, s,
            reason: 'Error parsing backend error response for deleting player',
            information: [response.body],
            fatal: false,
          );
          print('Error parsing backend error response: $e');
        }
        FirebaseCrashlytics.instance.recordError(
          'Failed to delete player with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for deleting player',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        print("Error deleting player: ${response.body}");
        FirebaseAnalytics.instance.logEvent(name: 'delete_player_failed', parameters: {'http_status': response.statusCode, 'response_body': response.body});
        return PlayerOperationResult(success: false, errorMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error deleting player',
        fatal: false,
      );
      print("Error deleting player: $e");
      FirebaseAnalytics.instance.logEvent(name: 'delete_player_failed', parameters: {'reason': 'connection_error', 'error_details': e.toString()});
      return PlayerOperationResult(success: false, errorMessage: 'Unknown error: ${e.toString()}');
    }
  }

  /// Edita um jogador existente.
  /// Retorna PlayerOperationResult indicando sucesso ou falha.
  Future<PlayerOperationResult> editPlayer({
    required int playerId,
    required String playerName,
    required String jerseyNumber,
  }) async {
    FirebaseAnalytics.instance.logEvent(name: 'edit_player_attempt', parameters: {'player_id': playerId, 'player_name': playerName});
    FirebaseCrashlytics.instance.log('Attempting to edit player $playerName with ID: $playerId.');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for editing player.',
        StackTrace.current,
        reason: 'Player controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for editing player.');
      return PlayerOperationResult(success: false, errorMessage: 'API base URL not configured.');
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for editing player. User might be logged out.');
      return PlayerOperationResult(success: false, errorMessage: 'Error: Token not found.');
    }

    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/player/$playerId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({
          'playerName': playerName,
          'jerseyNumber': jerseyNumber,
        }),
      );

      if (response.statusCode == 200) {
        FirebaseAnalytics.instance.logEvent(name: 'player_updated_successfully', parameters: {'player_id': playerId, 'player_name': playerName});
        FirebaseCrashlytics.instance.log('Player $playerName updated successfully.');
        return PlayerOperationResult(success: true);
      } else {
        String errorMessage = "Error updating player: ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }
        } catch (e, s) {
          FirebaseCrashlytics.instance.recordError(
            e, s,
            reason: 'Error parsing backend error response for updating player',
            information: [response.body],
            fatal: false,
          );
          print('Error parsing backend error response: $e');
        }
        FirebaseCrashlytics.instance.recordError(
          'Failed to update player with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for updating player',
          information: [response.body, response.request?.url.toString() ?? '', json.encode({'playerName': playerName, 'jerseyNumber': jerseyNumber})],
          fatal: false,
        );
        print("Error updating player: ${response.body}");
        FirebaseAnalytics.instance.logEvent(name: 'edit_player_failed', parameters: {'http_status': response.statusCode, 'response_body': response.body});
        return PlayerOperationResult(success: false, errorMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error updating player',
        fatal: false,
      );
      print("Error updating player: $e");
      FirebaseAnalytics.instance.logEvent(name: 'edit_player_failed', parameters: {'reason': 'connection_error', 'error_details': e.toString()});
      return PlayerOperationResult(success: false, errorMessage: 'Unknown error: ${e.toString()}');
    }
  }
}
