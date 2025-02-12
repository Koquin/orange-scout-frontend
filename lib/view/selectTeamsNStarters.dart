import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';



class SelectTeamsNStarters extends StatefulWidget {
  final String gameMode;
  final VoidCallback onBack; // Final, mas inicializado pelo construtor

  const SelectTeamsNStarters({Key? key, required this.gameMode, required this.onBack}) : super(key: key);

  @override
  _SelectTeamsNStartersState createState() => _SelectTeamsNStartersState();
}

class _SelectTeamsNStartersState extends State<SelectTeamsNStarters> {
  List<dynamic> teams = [];
  int team1Index = 0;
  int team2Index = 1;
  List<dynamic> playersTeam1 = [];
  List<dynamic> playersTeam2 = [];
  List<dynamic> selectedPlayersTeam1 = [];
  List<dynamic> selectedPlayersTeam2 = [];


  @override
  void initState() {
    super.initState();
    fetchTeams();
  }

  Future<String?> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchTeams() async {
    String? token = await _loadToken();
    if (token == null) {
      print("Erro: Token não encontrado.");
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:8080/team'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("Status da requisição /team: ${response.statusCode}");

    if (response.statusCode == 200) {
      setState(() {
        teams = jsonDecode(response.body);
      });

      if (teams.length >= 2) {
        fetchPlayers(teams[team1Index]['id'], isTeam1: true);
        fetchPlayers(teams[team2Index]['id'], isTeam1: false);
      }
    } else {
      print("Erro ao buscar times: ${response.body}");
    }
  }

  Future<void> fetchPlayers(int teamId, {required bool isTeam1}) async {
    String? token = await _loadToken();
    if (token == null) {
      print("Erro: Token não encontrado.");
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:8080/player/team-players/$teamId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("Status da requisição /players/team-players/$teamId: ${response.statusCode}");

    if (response.statusCode == 200) {
      setState(() {
        List<dynamic> players = jsonDecode(response.body);
        if (isTeam1) {
          playersTeam1 = players;
          selectedPlayersTeam1 = players.length >= 5 ? players.sublist(0, 5) : List.from(players);
        } else {
          playersTeam2 = players;
          selectedPlayersTeam2 = players.length >= 5 ? players.sublist(0, 5) : List.from(players);
        }
      });
    }
  }

  void showPlayerSelectionDialog(int index, bool isTeam1, List<dynamic> availablePlayers) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: availablePlayers.length,
          itemBuilder: (context, i) {
            return ListTile(
              title: Text(availablePlayers[i]['playerName'] ?? "Unknown player"), // Tratamento de null
              subtitle: Text("Jersey: ${availablePlayers[i]['jerseyNumber']?.toString() ?? '-'}"),
              onTap: () {
                setState(() {
                  if (isTeam1) {
                    selectedPlayersTeam1[index] = availablePlayers[i];
                  } else {
                    selectedPlayersTeam2[index] = availablePlayers[i];
                  }
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }



  void changeTeam(bool isNext, bool isTeam1) {
    setState(() {
      if (isTeam1) {
        do {
          team1Index = (team1Index + (isNext ? 1 : -1)) % teams.length;
          if (team1Index < 0) team1Index = teams.length - 1;
        } while (team1Index == team2Index); // Garante que os times sejam diferentes

        fetchPlayers(teams[team1Index]['id'], isTeam1: true);
      } else {
        do {
          team2Index = (team2Index + (isNext ? 1 : -1)) % teams.length;
          if (team2Index < 0) team2Index = teams.length - 1;
        } while (team2Index == team1Index); // Garante que os times sejam diferentes

        fetchPlayers(teams[team2Index]['id'], isTeam1: false);
      }
    });
  }




  Widget buildTeamSelection(bool isTeam1) {
    int teamIndex = isTeam1 ? team1Index : team2Index;
    List<dynamic> selectedPlayers = isTeam1 ? selectedPlayersTeam1 : selectedPlayersTeam2;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => changeTeam(false, isTeam1),
              child: Image.asset(
                "assets/images/arrow_left-cutout.png",
                width: 30,
                height: 30,
              ),
            ),
            Column(
              children: [
                Text(
                  teams[teamIndex]['teamName'],
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Image.asset(
                  "assets/images/TeamShieldIcon-cutout.png",
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            GestureDetector(
              onTap: () => changeTeam(true, isTeam1),
              child: Image.asset(
                "assets/images/arrow.png",
                width: 30,
                height: 30,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        buildPlayersGrid(selectedPlayers, isTeam1),
      ],
    );
  }

  Widget buildPlayersGrid(List<dynamic> selectedPlayers, bool isTeam1) {
    int playerCount = widget.gameMode == "5x5" ? 5 : widget.gameMode == "3x3" ? 3 : 1;
    List<dynamic> availablePlayers = isTeam1 ? playersTeam1 : playersTeam2;

    if (widget.gameMode == "1x1") {
      return Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: "Número do jogador"),
          ),
          TextField(
            decoration: InputDecoration(labelText: "Nome do jogador"),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        playerCount,
            (index) => GestureDetector(
          onTap: () => showPlayerSelectionDialog(index, isTeam1, availablePlayers),
          child: Container(
            margin: EdgeInsets.all(4),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              selectedPlayers.length > index && selectedPlayers[index] != null
                  ? (selectedPlayers[index]['jerseyNumber']?.toString() ?? '-') // Corrige erro de null
                  : '-',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Selecionar Times e Titulares")),
      body: teams.length < 2
          ? Center(child: CircularProgressIndicator())
          : Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildTeamSelection(true), // Time de cima
          buildTeamSelection(false), // Time de baixo
        ],
      ),
    );
  }
}
