import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<String?> _loadToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

Future<bool> checkUserValidation() async {
  try {
    final response = await http.get(
      Uri.parse('http://localhost:8080/auth/isValidated'),
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
    print("Requisition error: $e");
    return false;
  }
}




Future<bool> checkUserTeams() async {
  try {
    final response = await http.get(
      Uri.parse('http://localhost:8080/match/validate-start'),
    );

    if (response.statusCode == 200) {
      return response.body.trim().toLowerCase() == 'true';
    } else {
      return false;
    }
  } catch (e) {
    print("Requisition error: $e");
    return false;
  }
}

Future<bool> validateToken(String? token) async {
  if (token == null || token.isEmpty) return false;

  try {
    final response = await http.post(
      Uri.parse('http://localhost:8080/auth/isTokenValid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      return response.body.trim().toLowerCase() == 'true';
    } else {
      return false;
    }
  } catch (e) {
    print("Requisition error: $e");
    return false;
  }
}
