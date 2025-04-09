import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String apiUrl = "http://192.168.18.31:8080/match"; // Substitua pelo seu endpoint real

Future<Map<String, dynamic>?> checkLastMatch() async {
  print("Checando ultima partida...");
  String? token = await loadToken();
  final response = await http.get(
    Uri.parse("$apiUrl/last"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);

    if (data["finished"] == false) {
      return data;
    }
  }

  return null;
}

Future<void> finishMatch(int matchId, String token) async {
  final response = await http.put(
    Uri.parse("$apiUrl/finish/$matchId"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode != 200) {
    throw Exception("Error finishing match");
  }
}

Future<void> saveMatchToDB({
  required String token,
  required Map<String, dynamic> team1,
  required Map<String, dynamic> team2,
  required List<dynamic> startersTeam1,
  required List<dynamic> startersTeam2,
  required String gameMode,
  required Map<int, Map<String, int>> playerStats,
}) async {
  final url = Uri.parse(apiUrl);

  final body = jsonEncode({
    "team1": team1,
    "team2": team2,
    "startersTeam1": startersTeam1,
    "startersTeam2": startersTeam2,
    "gameMode": gameMode,
    "playerStats": playerStats,
    "finished": false, // Partida ainda não finalizada
  });

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: body,
  );

  if (response.statusCode == 200) {
    print("Match saved succesfully");
  } else {
    print("Error saving match: ${response.body}");
  }
}
