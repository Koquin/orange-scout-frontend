import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> checkUserValidation() async {
  final response = await http.get(Uri.parse('http://localhost:8080/user/validated'));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['validated']; // Assume que o JSON retorna {"validated": true}
  }
  return false; // Se der erro, assume que não está validado
}

Future<bool> checkUserTeams() async {
  final response = await http.get(Uri.parse('http://localhost:8080/match/validate-start'));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['teamCount'] >= 2; // Assume que o JSON retorna {"teamCount": 2}
  }
  return false;
}

