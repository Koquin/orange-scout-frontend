import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class MatchController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];

  Future<Map<String, dynamic>?> checkLastUnfinishedMatch() async {
    FirebaseAnalytics.instance.logEvent(name: 'check_last_match_attempt');
    FirebaseCrashlytics.instance.log('Attempting to check for last unfinished match.');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for match check.',
        StackTrace.current,
        reason: 'Match controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for match check.');
      return null;
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for match check. User might be logged out.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/match/last"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data["finished"] == false) {
          FirebaseAnalytics.instance.logEvent(name: 'last_match_found');
          FirebaseCrashlytics.instance.log('Last unfinished match found.');
          return data;
        } else {
          // Partida encontrada, mas já finalizada. Considerar como 'nenhuma não finalizada'.
          FirebaseAnalytics.instance.logEvent(name: 'no_unfinished_match_found_finished_returned');
          FirebaseCrashlytics.instance.log('Match found, but it was already finished.');
        }
      } else if (response.statusCode == 204) {
        FirebaseAnalytics.instance.logEvent(name: 'no_unfinished_match_found_204');
        FirebaseCrashlytics.instance.log('No unfinished match found (204 No Content).');
      } else {
        FirebaseCrashlytics.instance.recordError(
          'Error checking last match: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for last unfinished match',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        print('Error checking last match: ${response.statusCode}');
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error checking last match',
        fatal: false,
      );
      print('Connection error checking last match: $e');
    }
    return null;
  }

  Future<bool> finishMatch(int matchId) async {
    FirebaseAnalytics.instance.logEvent(name: 'finish_match_attempt', parameters: {'match_id': matchId});
    FirebaseCrashlytics.instance.log('Attempting to finish match: $matchId');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for match finish.',
        StackTrace.current,
        reason: 'Match controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for match finish.');
      return false;
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for match finish. User might be logged out.');
      return false;
    }

    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/match/finish/$matchId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        FirebaseAnalytics.instance.logEvent(name: 'match_finished_successfully', parameters: {'match_id': matchId});
        FirebaseCrashlytics.instance.log('Match $matchId finished successfully.');
        print('Match $matchId finished successfully.');
        return true;
      } else {
        FirebaseCrashlytics.instance.recordError(
          'Failed to finish match $matchId: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for finishing match',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        print('Failed to finish match $matchId: ${response.statusCode}');
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error finishing match',
        fatal: false,
      );
      print('Connection error finishing match: $e');
      return false;
    }
  }

  Future<bool> saveMatchToDB({
    required String gameMode,
    required Map<String, dynamic> team1,
    required Map<String, dynamic> team2,
    required List<dynamic> startersTeam1,
    required List<dynamic> startersTeam2,
    required Map<int, Map<String, int>> playerStats,
  }) async {
    FirebaseAnalytics.instance.logEvent(name: 'save_match_to_db_attempt', parameters: {'game_mode': gameMode});
    FirebaseCrashlytics.instance.log('Attempting to save match for game mode: $gameMode');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for saving match.',
        StackTrace.current,
        reason: 'Match controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for saving match.');
      return false;
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for saving match. User might be logged out.');
      return false;
    }

    final url = Uri.parse("$_baseUrl/match");

    final body = jsonEncode({
      "team1": team1,
      "team2": team2,
      "startersTeam1": startersTeam1,
      "startersTeam2": startersTeam2,
      "gameMode": gameMode,
      "playerStats": playerStats,
      "finished": false,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        FirebaseAnalytics.instance.logEvent(name: 'match_saved_successfully', parameters: {'game_mode': gameMode});
        FirebaseCrashlytics.instance.log('Match saved successfully.');
        print("Match saved successfully.");
        return true;
      } else {
        FirebaseCrashlytics.instance.recordError(
          'Error saving match: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for saving match',
          information: [response.body, response.request?.url.toString() ?? '', body],
          fatal: false,
        );
        print("Error saving match: ${response.body}");
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error saving match',
        fatal: false,
      );
      print("Error saving match: $e");
      return false;
    }
  }
}
