import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

Future<String?> _loadToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

Future<bool> checkUserValidation() async {
  String? token = await _loadToken();
  if (token == null) {
    return false;
  }
    final response = await http.get(
      Uri.parse('http://localhost:8080/auth/isValidated'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return true;
    }
    return false;
  }

Future<bool> checkUserTeams() async {
  String? token = await _loadToken();
  if (token == null || token.isEmpty) {
    print("🚨 Token not found");
    return false;
  }

  final response = await http.get(
    Uri.parse('http://localhost:8080/match/validate-start'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print("🔹 Resposta do servidor: ${response.statusCode}");
  print("🔹 Corpo da resposta: ${response.body}");

  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}