import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    super.key,
    required this.gameMode,
    required this.onBack,
    required this.changeScreen,
  });

  @override
  _SelectTeamsNStartersState createState() => _SelectTeamsNStartersState();
}

class _SelectTeamsNStartersState extends State<SelectTeamsNStarters> {
  //Base url
  String? baseUrl = dotenv.env['API_BASE_URL'];

  //Other variables
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Make sure that Orange Scout can use FULL SCREEN in your device before pressing START"),
          duration: Duration(seconds: 7),
        ),
      );
    });
  }

  Future<void> fetchTeams() async {
    String? token = await loadToken();
    if (token == null) {
      print("Error: Token is null");
      return;
    }

    final response = await http.get(
      Uri.parse("$baseUrl/team"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        teams = jsonDecode(response.body);
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
      return;
    }
    final response = await http.get(
      Uri.parse('$baseUrl/player/team-players/$teamId'),
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
    for (var player in selectedPlayersTeam1 + selectedPlayersTeam2) {
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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15.0,
                spreadRadius: 3.0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Select Player",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFCC80),
                ),
              ),
              const Divider(color: Colors.white38, height: 24),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availablePlayers.length,
                  itemBuilder: (context, i) {
                    final player = availablePlayers[i];
                    return Card(
                      color: Colors.white.withOpacity(0.08),
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFFFF4500),
                          child: Text(
                            player['jerseyNumber']?.toString() ?? '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          player['playerName'] ?? "Unknown player",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          "Jersey: ${player['jerseyNumber']?.toString() ?? '-'}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () {
                          setState(() {
                            if (isTeam1) {
                              selectedPlayersTeam1[index] = player;
                            } else {
                              selectedPlayersTeam2[index] = player;
                            }
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF84442E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Cancel", style: TextStyle(fontSize: 16)),
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
                        throw FileSystemException();
                      }
                    } catch (e) {
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
            width: 60,
            height: 60,
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
                  fontSize: 28,
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