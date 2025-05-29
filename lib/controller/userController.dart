import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class UserController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];

  Future<bool> checkUserValidation() async {
    FirebaseAnalytics.instance.logEvent(name: 'check_user_validation_attempt');
    FirebaseCrashlytics.instance.log('Attempting to check user validation status.');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for user validation check.',
        StackTrace.current,
        reason: 'User controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for user validation check.');
      return false;
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for user validation check. User might be logged out.');
      return false;
    }

    try {
      final response = await http.get(
          Uri.parse('$_baseUrl/auth/isValidated'),
          headers: {
            'Authorization' : 'Bearer $token',
            'Content-Type': 'application/json',
          }
      );

      if (response.statusCode == 200) {
        bool isValidated = response.body.trim().toLowerCase() == 'true';
        FirebaseAnalytics.instance.logEvent(
          name: 'user_validation_status',
          parameters: {'is_validated': isValidated},
        );
        FirebaseCrashlytics.instance.log('User validation status: $isValidated');
        return isValidated;
      } else {
        FirebaseCrashlytics.instance.recordError(
          'Failed to check user validation: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for user validation',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        print('Failed to check user validation: ${response.statusCode}');
        FirebaseAnalytics.instance.logEvent(
          name: 'check_user_validation_failed',
          parameters: {'http_status': response.statusCode},
        );
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error checking user validation',
        fatal: false,
      );
      print('Connection error checking user validation: $e');
      FirebaseAnalytics.instance.logEvent(name: 'check_user_validation_failed', parameters: {'reason': 'connection_error'});
      return false;
    }
  }

  Future<bool> checkUserTeams() async {
    FirebaseAnalytics.instance.logEvent(name: 'check_user_teams_attempt');
    FirebaseCrashlytics.instance.log('Attempting to check user teams for match start.');

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured for user teams check.',
        StackTrace.current,
        reason: 'User controller configuration error',
        fatal: false,
      );
      print('API base URL not configured for user teams check.');
      return false;
    }
    String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for user teams check. User might be logged out.');
      return false;
    }

    try {
      final response = await http.get(
          Uri.parse('$_baseUrl/match/validate-start'),
          headers : {
            'Authorization' : 'Bearer $token',
            'Content-Type': 'application/json',
          }
      );

      if (response.statusCode == 200) {
        bool hasTeams = response.body.trim().toLowerCase() == 'true';
        FirebaseAnalytics.instance.logEvent(
          name: 'user_teams_status',
          parameters: {'has_teams': hasTeams},
        );
        FirebaseCrashlytics.instance.log('User has teams for match start: $hasTeams');
        return hasTeams;
      } else {
        FirebaseCrashlytics.instance.recordError(
          'Failed to check user teams: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for user teams check',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        print('Failed to check user teams: ${response.statusCode}');
        FirebaseAnalytics.instance.logEvent(
          name: 'check_user_teams_failed',
          parameters: {'http_status': response.statusCode},
        );
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error checking user teams',
        fatal: false,
      );
      print('Connection error checking user teams: $e');
      FirebaseAnalytics.instance.logEvent(name: 'check_user_teams_failed', parameters: {'reason': 'connection_error'});
      return false;
    }
  }

}
