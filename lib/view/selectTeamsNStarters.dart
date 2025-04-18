import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'gameScreen.dart';
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'dart:io';

class SelectTeamsNStarters extends StatefulWidget {
  final String gameMode;
  final VoidCallback onBack;
  final Function(Widget screen) changeScreen;

  const SelectTeamsNStarters({
    Key? key,
    required this.gameMode,
    required this.onBack,
    required this.changeScreen,
  }) : super(key: key);

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
  String endPointTeam = "http://192.168.18.31:8080/team";
  String endPointPlayer = "http://192.168.18.31:8080/player";

  @override
  void initState() {
    super.initState();
    fetchTeams();
  }

  Future<void> fetchTeams() async {
    String? token = await loadToken();
    if (token == null) {
      print("Error: Token is null");
      return;
    }

    final response = await http.get(
      Uri.parse(endPointTeam),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        teams = jsonDecode(response.body);
        print(teams);
      });

      if (teams.length >= 2) {
        fetchPlayers(teams[team1Index]['id'], isTeam1: true);
        fetchPlayers(teams[team2Index]['id'], isTeam1: false);
      }
    }
  }

  Future<void> fetchPlayers(int teamId, {required bool isTeam1}) async {
    String? token = await loadToken();
    if (token == null) {
      print("Error: Token is null");
      return;
    }
    final response = await http.get(
      Uri.parse('$endPointPlayer/team-players/$teamId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

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

  void startGame() {
    Map<int, Map<String, int>> playerStats = {};
    print("Team 1: ${teams[team1Index]}, Team 2: ${teams[team2Index]}");
    for (var player in selectedPlayersTeam1 + selectedPlayersTeam2) {
      print(player);
      playerStats[player['id_player']] = {
        "three_pointer": 0,
        "two_pointer": 0,
        "one_pointer": 0,
        "missed_three_pointer": 0,
        "missed_two_pointer": 0,
        "missed_one_pointer": 0,
        "steal": 0,
        "turnover": 0,
        "block": 0,
        "assist": 0,
        "offensive_rebound": 0,
        "defensive_rebound": 0,
        "foul": 0,
      };
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          userId: 0,
          matchId: 0,
          teamOneScore: 0,
          teamTwoScore: 0,
          team1: teams[team1Index],
          team2: teams[team2Index],
          startersTeam1: selectedPlayersTeam1,
          startersTeam2: selectedPlayersTeam2,
          gameMode: widget.gameMode,
          playerStats: [],
        ),
      ),
    );
  }

  void showPlayerSelectionDialog(int index, bool isTeam1, List<dynamic> availablePlayers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select player", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availablePlayers.length,
                  itemBuilder: (context, i) {
                    return ListTile(
                      title: Text(availablePlayers[i]['playerName'] ?? "Unknown player"),
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
                ),
              ),
            ],
          ),
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
        } while (team1Index == team2Index);
        fetchPlayers(teams[team1Index]['id'], isTeam1: true);
      } else {
        do {
          team2Index = (team2Index + (isNext ? 1 : -1)) % teams.length;
          if (team2Index < 0) team2Index = teams.length - 1;
        } while (team2Index == team1Index);
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
            IconButton(
              icon: Image.asset("assets/images/arrow_left.png", width: 50, height: 50),
              onPressed: () => changeTeam(false, isTeam1),
            ),
            Column(
              children: [
                Text(
                  teams[teamIndex]['teamName'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Builder(
                  builder: (_) {
                    try {
                      final path = teams[teamIndex]['logoPath'];
                      if (path != null && File(path).existsSync()) {
                        return Image.file(
                          File(path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        );
                      } else {
                        throw FileSystemException(); // força cair no catch se o caminho não existir
                      }
                    } catch (e) {
                      // Exibe a imagem padrão caso ocorra algum erro ao carregar a imagem do time
                      return Image.asset(
                        "assets/images/TeamShieldIcon-cutout.png",
                        width: 100,
                        height: 100,
                      );
                    }
                  },
                ),

              ],
            ),
            IconButton(
              icon: Image.asset("assets/images/arrow.png", width: 50, height: 50),
              onPressed: () => changeTeam(true, isTeam1),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        playerCount,
            (index) => GestureDetector(
          onTap: () => showPlayerSelectionDialog(index, isTeam1, availablePlayers),
          child: Container(
            width: 60, // Largura fixa
            height: 60, // Altura fixa
            margin: EdgeInsets.all(4),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                selectedPlayers.length > index && selectedPlayers[index] != null
                    ? (selectedPlayers[index]['jerseyNumber']?.toString() ?? '-')
                    : '-',
                style: TextStyle(
                  fontSize: 28, // Tamanho base, reduzido automaticamente pelo FittedBox
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFFFF4500),
              Color(0xFF84442E),
              Colors.black,
            ],
            stops: [0.0, 0.5, 0.9],
          ),
        ),
        child: teams.length < 2
            ? Center(child: CircularProgressIndicator())
            : Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildTeamSelection(true),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.orange,
              ),
              onPressed: (selectedPlayersTeam1.isNotEmpty && selectedPlayersTeam2.isNotEmpty)
                  ? startGame
                  : null,
              child: Text("START", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            buildTeamSelection(false),
          ],
        ),
      ),
    );
  }

}