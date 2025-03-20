import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:OrangeScoutFE/util/token_utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> matches = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchMatches();
  }



  Future<void> fetchMatches() async {
    String? token = await loadToken();
    setState(() {
      isLoading = true;
      hasError = false;
    });

    print("chegou na requisição");
    try {
      final response = await http.get(
        Uri.parse('http://192.168.18.31:8080/match/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    print(token);
    print("passou da requisição de matches");
    print(response.statusCode);
      if (response.statusCode == 200){
        print("entrou no if");
        List<dynamic> data = jsonDecode(response.body);
        print(data);
        setState(() {
          matches = data.map((match) => {
            'id': match['idMatch'],
            'team1': match['teamOne']['abbreviation'],
            'team2': match['teamTwo']['abbreviation'],
            'score': '${match['teamOneScore']} x ${match['teamTwoScore']}',
            'date': match['matchDate'],
            'team1Logo': match['teamOne']['logoPath'],
            'team2Logo': match['teamTwo']['logoPath'],
          }).toList();
          print(matches);
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  /// **Abre a localização da partida específica no Google Maps**
  Future<void> _openMatchLocation(String matchId) async {
    String? token = await loadToken();
    final response = await http.get(
      Uri.parse('http://192.168.18.31/match/matchLocation/$matchId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final latitude = data['latitude'];
      final longitude = data['longitude'];

      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl));
      } else {
        print("Erro ao abrir o Google Maps");
      }
    } else {
      print("Erro ao buscar localização da partida");
    }
  }

  /// **Abre todas as localizações no Google Maps**
  Future<void> _openAllLocations() async {
    String? token = await loadToken();
    final response = await http.get(
      Uri.parse('http://192.168.18.31:8080/match/locations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> locations = jsonDecode(response.body);
      if (locations.isEmpty) {
        print("Nenhuma localização disponível.");
        return;
      }

      if (locations.length == 1) {
        // Caso tenha apenas 1 ponto, usamos apenas `destination`
        final singleLocation = "${locations[0]['latitude']},${locations[0]['longitude']}";
        final googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$singleLocation";

        if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
          await launchUrl(Uri.parse(googleMapsUrl));
        } else {
          print("Erro ao abrir o Google Maps");
        }
        return;
      }

      // O primeiro ponto vai no `destination`
      String destination = "${locations[0]['latitude']},${locations[0]['longitude']}";

      // Os outros vão como `waypoints`, separados por `|`
      String waypoints = locations
          .skip(1)
          .map((loc) => "${loc['latitude']},${loc['longitude']}")
          .join("|");

      // Construindo a URL final
      String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$destination&waypoints=$waypoints";

      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl));
      } else {
        print("Erro ao abrir o Google Maps");
      }
    } else {
      print("Erro ao buscar todas as localizações");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 231, 148, 23),
              Color.fromARGB(255, 202, 66, 56),
              Color.fromARGB(255, 53, 33, 33),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : hasError
                  ? Center(child: Text('Erro ao carregar partidas', style: TextStyle(color: Colors.red)))
                  : ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.black54,
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Image.asset(
                              'assets/images/StatisticsIcon.png',
                              width: 50,
                              height: 50,
                            ),
                            onPressed: () {
                              final matchId = matches[index]['id'];
                              if (matchId != null) {
                                _openMatchLocation(matchId.toString());
                              }
                            },
                          ),
                          Row(
                            children: [
                              Image.asset('assets/images/TeamShieldIcon-cutout.png', width: 60, height: 60),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(width: 5),
                              Text(matches[index]['team1'], style: TextStyle(color: Colors.grey, fontSize: 16)),
                              SizedBox(width: 5),
                            ],
                          ),
                          Column(
                            children: [
                              Text(matches[index]['date'], style: TextStyle(color: Colors.grey, fontSize: 16)),
                              Text(matches[index]['score'], style: TextStyle(color: Colors.orange, fontSize: 20)),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(width: 5),
                              Text(matches[index]['team2'], style: TextStyle(color: Colors.grey, fontSize: 16)),
                              SizedBox(width: 5),
                            ],
                          ),
                          Row(
                            children: [
                              Image.asset('assets/images/TeamShieldIcon-cutout.png', width: 60, height: 60),
                              SizedBox(width: 10),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _openAllLocations,
                    child: Text("Ver Todas as Localizações"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

    );
  }
}
