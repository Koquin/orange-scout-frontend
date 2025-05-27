import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:OrangeScoutFE/util/token_utils.dart';

String? baseUrl = dotenv.env['API_BASE_URL'];

Future<bool> checkUserValidation() async {
  String? token = await loadToken();

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/isValidated'),
      headers: {
        'Authorization' : 'Bearer $token',
        'Content-Type': 'application/json',
      }
    );

    if (response.statusCode == 200) {
      if (response.body.trim().toLowerCase() == 'true'){
        return true;
      }
      else {
        return false;
      }
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

Future<bool> checkUserTeams() async {
  String? token = await loadToken();

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/match/validate-start'),
      headers : {
        'Authorization' : 'Bearer $token',
        'Content-Type': 'application/json',
        }
    );

    if (response.statusCode == 200) {
      if (response.body.trim().toLowerCase() == 'true'){
        return true;
      }
      else {
        return false;
      }
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

Future<bool> isTokenExpired(String? token) async {
  if (token == null || token.isEmpty) return false;

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/isTokenValid'),
        headers : {
          'Content-Type': 'application/json',
        },
      body: jsonEncode({'token': token}),
    );
    if (response.statusCode == 200) {
      if (response.body.trim().toLowerCase() == 'false'){
        return false;
      }
      else {
        return true;
      }
    } else if (response.statusCode == 403) {
      return true;
    } else {
      return true;
    }
  } catch (e) {
    return false;
  }
}
