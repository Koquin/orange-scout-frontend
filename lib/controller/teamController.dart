import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Uma classe para encapsular o resultado da operação de salvar/atualizar time.
class TeamSaveResult {
  final bool success;
  final String? errorMessage;

  TeamSaveResult({required this.success, this.errorMessage});
}

/// Controlador responsável por operações relacionadas a times.
class TeamController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];

  Future<List<dynamic>> fetchTeams() async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_teams_attempt_controller');
    FirebaseCrashlytics.instance.log('Attempting to fetch user teams from controller.');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for fetching teams.',
        StackTrace.current,
        reason: 'Team controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for fetching teams.');
      return [];
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for fetching teams. User might be logged out.');
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/team"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        FirebaseAnalytics.instance.logEvent(name: 'teams_fetched_successfully', parameters: {'count': data.length});
        FirebaseCrashlytics.instance.log('Teams fetched successfully. Count: ${data.length}');
        return data;
      } else {
        FirebaseCrashlytics.instance.recordError(
          'Failed to fetch teams: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for fetching teams',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        print('Error fetching teams: ${response.statusCode}');
        FirebaseAnalytics.instance.logEvent(
          name: 'fetch_teams_failed',
          parameters: {'http_status': response.statusCode},
        );
        return [];
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error fetching teams',
        fatal: false,
      );
      print('Requisition error fetching teams: $e');
      FirebaseAnalytics.instance.logEvent(name: 'fetch_teams_failed', parameters: {'reason': 'connection_error'});
      return [];
    }
  }

  /// Salva ou atualiza um time no backend.
  /// Retorna um objeto TeamSaveResult que indica o sucesso/falha e uma mensagem de erro.
  Future<TeamSaveResult> saveTeam(Map<String, dynamic> teamData) async {
    final int? teamId = teamData['id'];
    FirebaseAnalytics.instance.logEvent(name: 'save_team_attempt', parameters: {'team_id': teamId, 'is_new': teamId == null});
    FirebaseCrashlytics.instance.log('Attempting to save team. Team ID: $teamId');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for saving team.',
        StackTrace.current,
        reason: 'Team controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for saving team.');
      return TeamSaveResult(success: false, errorMessage: 'API base URL not configured.');
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for saving team. User might be logged out.');
      return TeamSaveResult(success: false, errorMessage: 'Error: Token not found.');
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/team"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(teamData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        FirebaseAnalytics.instance.logEvent(name: 'team_saved_successfully', parameters: {'team_id': teamId, 'is_new': teamId == null});
        FirebaseCrashlytics.instance.log('Team saved successfully. ID: $teamId');
        return TeamSaveResult(success: true);
      } else {
        String errorMessage = "Error saving team: ${response.statusCode}";
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'];
          }
        } catch (e, s) {
          FirebaseCrashlytics.instance.recordError(
            e, s,
            reason: 'Error parsing backend error response for saving team',
            information: [response.body],
            fatal: false,
          );
          print('Error parsing backend error response: $e');
        }
        FirebaseCrashlytics.instance.recordError(
          'Failed to save team with HTTP status: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for saving team',
          information: [response.body, response.request?.url.toString() ?? '', jsonEncode(teamData)],
          fatal: false,
        );
        print("Error saving team: ${response.body}");
        FirebaseAnalytics.instance.logEvent(name: 'save_team_failed', parameters: {'http_status': response.statusCode, 'response_body': response.body});
        return TeamSaveResult(success: false, errorMessage: errorMessage);
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error saving team',
        fatal: false,
      );
      print("Unknown error saving team: $e");
      FirebaseAnalytics.instance.logEvent(name: 'save_team_failed', parameters: {'reason': 'connection_error', 'error_details': e.toString()});
      return TeamSaveResult(success: false, errorMessage: 'Unknown error: ${e.toString()}');
    }
  }

  /// Busca os detalhes de um time específico.
  /// Retorna os dados do time (Map<String, dynamic>) ou null em caso de erro.
  Future<Map<String, dynamic>?> fetchTeamDetails(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_team_details_attempt', parameters: {'team_id': teamId});
    FirebaseCrashlytics.instance.log('Attempting to fetch details for team: $teamId');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for fetching team details.',
        StackTrace.current,
        reason: 'Team controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for fetching team details.');
      return null;
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for fetching team details. User might be logged out.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/team/$teamId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        FirebaseAnalytics.instance.logEvent(name: 'team_details_fetched_successfully', parameters: {'team_id': teamId});
        FirebaseCrashlytics.instance.log('Team details fetched successfully for ID: $teamId.');
        return data;
      } else {
        FirebaseCrashlytics.instance.recordError(
          'Failed to fetch team details: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for fetching team details',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        print('Failed to fetch team details: ${response.statusCode}');
        FirebaseAnalytics.instance.logEvent(name: 'fetch_team_details_failed', parameters: {'team_id': teamId, 'http_status': response.statusCode});
        return null;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error fetching team details',
        fatal: false,
      );
      print('Connection error fetching team details: $e');
      FirebaseAnalytics.instance.logEvent(name: 'fetch_team_details_failed', parameters: {'team_id': teamId, 'error': e.toString()});
      return null;
    }
  }

  /// Deleta um time do backend.
  /// Retorna true se deletado com sucesso, false caso contrário.
  Future<bool> deleteTeam(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_team_attempt', parameters: {'team_id': teamId});
    FirebaseCrashlytics.instance.log('Attempting to delete team: $teamId');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for deleting team.',
        StackTrace.current,
        reason: 'Team controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for deleting team.');
      return false;
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for deleting team. User might be logged out.');
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse("$_baseUrl/team/$teamId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 204) { // 204 No Content é o status comum para DELETE bem-sucedido
        FirebaseAnalytics.instance.logEvent(name: 'team_deleted_successfully', parameters: {'team_id': teamId});
        FirebaseCrashlytics.instance.log('Team $teamId deleted successfully.');
        print('Team $teamId deleted successfully.');
        return true;
      } else {
        FirebaseCrashlytics.instance.recordError(
          'Failed to delete team $teamId: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for deleting team',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        print('Failed to delete team $teamId: ${response.statusCode}');
        FirebaseAnalytics.instance.logEvent(
          name: 'delete_team_failed',
          parameters: {'team_id': teamId, 'http_status': response.statusCode},
        );
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error deleting team',
        fatal: false,
      );
      print('Connection error deleting team: $e');
      FirebaseAnalytics.instance.logEvent(name: 'delete_team_failed', parameters: {'team_id': teamId, 'reason': 'connection_error'});
      return false;
    }
  }
}
