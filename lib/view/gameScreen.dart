import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:OrangeScoutFE/util/location.dart';

import 'mainScreen.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // Importe FirebaseAnalytics

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
  final Map<String, dynamic> team1;
  final Map<String, dynamic> team2;
  final List<dynamic> startersTeam1;
  final List<dynamic> startersTeam2;
  final String gameMode;
  final List<Map<String, dynamic>> playerStats;
  final int userId;
  final int matchId;
  final int teamOneScore;
  final int teamTwoScore;


  const GameScreen({
    super.key,
    required this.teamOneScore,
    required this.teamTwoScore,
    required this.matchId,
    required this.userId,
    required this.team1,
    required this.team2,
    required this.startersTeam1,
    required this.startersTeam2,
    required this.gameMode,
    required this.playerStats,
  });

}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver{
  String? baseUrl = dotenv.env['API_BASE_URL'];

  final ScrollController _team1ScrollController = ScrollController();
  final ScrollController _team2ScrollController = ScrollController();
  String? selectedPlayerJerseyNumber;
  int? selectedPlayerId;
  int? selectedTeam;
  int? selectedTeamId;
  List<String> team1Actions = [];
  List<String> team2Actions = [];
  Map<int, Map<String, int>> playerStats = {};
  int teamOneScore = 0;
  int teamTwoScore = 0;
  Future<String?>? token = loadToken();
  bool _hasSavedProgress = false;
  int? matchId;
  int? selectedPlayerIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    FirebaseAnalytics.instance.logScreenView(
      screenName: 'GameScreen',
      screenClass: 'GameScreenState',
      parameters: {'game_mode': widget.gameMode, 'match_id_initial': widget.matchId},
    );

    teamOneScore = widget.teamOneScore;
    teamTwoScore = widget.teamTwoScore;
    matchId = widget.matchId == 0 ? null : widget.matchId;

    if (widget.playerStats.isNotEmpty) {
      for (var statEntry in widget.playerStats) {
        if (statEntry['playerId'] != null) {
          playerStats[statEntry['playerId']] = Map<String, int>.from(statEntry);
          playerStats[statEntry['playerId']]!['playerId'] = statEntry['playerId'];
        }
      }
      FirebaseAnalytics.instance.logEvent(name: 'game_resumed', parameters: {'match_id': matchId});
    } else {
      for (var player in widget.startersTeam1 + widget.startersTeam2) {
        playerStats[player['id_player']] = {
          "id_player": player['id_player'],
          "three_pointer": 0, "two_pointer": 0, "one_pointer": 0,
          "missed_three_pointer": 0, "missed_two_pointer": 0, "missed_one_pointer": 0,
          "steal": 0, "turnover": 0, "block": 0, "assist": 0,
          "offensive_rebound": 0, "defensive_rebound": 0, "foul": 0,
        };
      }
    }
  }

  Color getBorderColor(String action) {
    if (
    action.contains("1 Point Made") ||
        action.contains("2 Point Made") ||
        action.contains("3 Point Made") ||
        action == "one_pointer" ||
        action == "two_pointer" ||
        action == "three_pointer"
    ) {
      return Colors.green;
    } else if (
    action.contains("Missed") ||
        action.contains("Turnover") ||
        action.contains("Foul") ||
        action.contains("missed") ||
        action.contains("turnover") ||
        action.contains("foul")
    ) {
      return Colors.red;
    } else {
      return Colors.yellow;
    }
  }

  void updateStat(int idPlayer, String statKey) {
    setState(() {
      if (!playerStats.containsKey(idPlayer)) {
        playerStats[idPlayer] = {
          "id_player": idPlayer,
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
      playerStats[idPlayer]![statKey] = (playerStats[idPlayer]![statKey] ?? 0) + 1;
      FirebaseAnalytics.instance.logEvent( // Log de atualização de estatística
        name: 'stat_updated',
        parameters: {
          'player_id': idPlayer,
          'stat_key': statKey,
          'new_value': playerStats[idPlayer]![statKey],
          'game_mode': widget.gameMode,
        },
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _team1ScrollController.dispose();
    _team2ScrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _hasSavedProgress = false;
    }
    if (state == AppLifecycleState.paused) {
      print("Estado mudou, ${state}");
      await saveMatchProgress();
    }
  }

  void finishMatch() async {
    FirebaseAnalytics.instance.logEvent(name: 'finish_match_button_pressed');

    String? token = await loadToken();

  print("Stats: ${playerStats.entries}");
  List<Map<String, dynamic>> statsList = playerStats.entries.map((entry) {
    final stats = entry.value;
    return {
      "matchId": null,
      "statsId": null,
      "playerId": stats["id_player"],
      "three_pointer": stats["three_pointer"] ?? 0,
      "two_pointer": stats["two_pointer"] ?? 0,
      "one_pointer": stats["one_pointer"] ?? 0,
      "missed_three_pointer": stats["missed_three_pointer"] ?? 0,
      "missed_two_pointer": stats["missed_two_pointer"] ?? 0,
      "missed_one_pointer": stats["missed_one_pointer"] ?? 0,
      "steal": stats["steal"] ?? 0,
      "turnover": stats["turnover"] ?? 0,
      "block": stats["block"] ?? 0,
      "assist": stats["assist"] ?? 0,
      "offensive_rebound": stats["offensive_rebound"] ?? 0,
      "defensive_rebound": stats["defensive_rebound"] ?? 0,
      "foul": stats["foul"] ?? 0
    };
  }).toList();

    Map<String, dynamic>? locationData;
    try {
      locationData = await getCurrentLocation();
      FirebaseAnalytics.instance.logEvent(name: 'location_fetched_for_match');
    } catch (e) {
      FirebaseAnalytics.instance.logEvent(name: 'location_fetch_failed', parameters: {'error': e.toString()});
      print('Error getting location: $e');
    }

    double? latitude = locationData?['latitude'];
    double? longitude = locationData?['longitude'];
    String? placeName = locationData?['placeName'];

  Map<String, dynamic> matchData = {
    "idMatch": matchId,
    "userId": widget.userId,
    "matchDate": DateTime.now().toIso8601String(),
    "teamOneScore": teamOneScore,
    "teamTwoScore": teamTwoScore,
    "teamOne": {
      "id": widget.team1["id"],
      "teamName": widget.team1["teamName"],
      "logoPath": widget.team1["logoPath"],
      "abbreviation": widget.team1["abbreviation"]
    },
    "teamTwo": {
      "id": widget.team2["id"],
      "teamName": widget.team2["teamName"],
      "logoPath": widget.team2["logoPath"],
      "abbreviation": widget.team2["abbreviation"]
    },
    "stats": statsList,
    "location": {
      "latitude": latitude,
      "longitude": longitude,
      "placeName": placeName
    },
    "finished": true,
    "gamemode": widget.gameMode,
    "startersTeam1": widget.startersTeam1,
    "startersTeam2": widget.startersTeam2
  };

    if (token == null) {
      print("Token is null!");
      FirebaseAnalytics.instance.logEvent(name: 'finish_match_failed', parameters: {'reason': 'token_null'});
      return;
    }

  final response = await http.post(
    Uri.parse("$baseUrl/match"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    },
    body: jsonEncode(matchData),
  );
  if (response.statusCode == 201) {
    try {
      final responseBody = jsonDecode(response.body);
      final newMatchId = responseBody;
      if (newMatchId != null) {
        setState(() {
          matchId = newMatchId;
          print(matchId);
        });
        FirebaseAnalytics.instance.logEvent(name: 'match_finished_successfully', parameters: {'match_id': matchId});
        await Future.delayed(const Duration(seconds: 1, milliseconds: 50));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
              (Route<dynamic> route) => false,
        );
      } else {
        print("MatchId is not in the response.");
        FirebaseAnalytics.instance.logEvent(name: 'finish_match_failed', parameters: {'reason': 'match_id_not_in_response'});
      }
    } catch (e) {
      print('Error decoding answer or finding matchId: $e');
      FirebaseAnalytics.instance.logEvent(name: 'finish_match_failed', parameters: {'reason': 'response_decode_error', 'error': e.toString()});
    }
  } else {
    print("Error finishing match: ${response.statusCode}");
    FirebaseAnalytics.instance.logEvent(name: 'finish_match_failed', parameters: {'reason': 'http_error', 'status_code': response.statusCode, 'response_body': response.body});
  }
}

  Future<void> saveMatchProgress() async {
    if (_hasSavedProgress) {
      FirebaseAnalytics.instance.logEvent(name: 'save_progress_skipped_already_saved');
      print("Progress has already been saved.");
      return;
    }
    _hasSavedProgress = true;
    FirebaseAnalytics.instance.logEvent(name: 'save_progress_attempt');

    String? token = await loadToken();
    print("Stats: ${playerStats.entries}");
    List<Map<String, dynamic>> statsList = playerStats.entries.map((entry) {
      final stats = entry.value;
      return {
        "matchId": null,
        "statsId": null,
        "playerId": stats["id_player"],
        "three_pointer": stats["three_pointer"] ?? 0,
        "two_pointer": stats["two_pointer"] ?? 0,
        "one_pointer": stats["one_pointer"] ?? 0,
        "missed_three_pointer": stats["missed_three_pointer"] ?? 0,
        "missed_two_pointer": stats["missed_two_pointer"] ?? 0,
        "missed_one_pointer": stats["missed_one_pointer"] ?? 0,
        "steal": stats["steal"] ?? 0,
        "turnover": stats["turnover"] ?? 0,
        "block": stats["block"] ?? 0,
        "assist": stats["assist"] ?? 0,
        "offensive_rebound": stats["offensive_rebound"] ?? 0,
        "defensive_rebound": stats["defensive_rebound"] ?? 0,
        "foul": stats["foul"] ?? 0
      };
    }).toList();
    Map<String, dynamic> matchData = {
      "idMatch": matchId,
      "userId": widget.userId,
      "matchDate": DateTime.now().toIso8601String(),
      "teamOneScore": teamOneScore,
      "teamTwoScore": teamTwoScore,
      "teamOne": {
        "id": widget.team1["id"],
        "teamName": widget.team1["teamName"],
        "logoPath": widget.team1["logoPath"],
        "abbreviation": widget.team1["abbreviation"]
      },
      "teamTwo": {
        "id": widget.team2["id"],
        "teamName": widget.team2["teamName"],
        "logoPath": widget.team2["logoPath"],
        "abbreviation": widget.team2["abbreviation"]
      },
      "stats": statsList,
      "location": {
        "latitude": null,
        "longitude": null
      },
      "finished": false,
      "gamemode": widget.gameMode,
      "startersTeam1": widget.startersTeam1,
      "startersTeam2": widget.startersTeam2
    };
    if (token == null) {
      print("Token is null!");
      FirebaseAnalytics.instance.logEvent(name: 'save_progress_failed', parameters: {'reason': 'token_null'});
      return;
    }
    print("Stats sendo mandado para o backEnd: $matchData");
    final response = await http.post(
      Uri.parse('$baseUrl/match/save-progress'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(matchData),
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final newMatchId = responseBody['matchId'];
      if (newMatchId != null) {
        setState(() {
          matchId = newMatchId;
        });
        FirebaseAnalytics.instance.logEvent(name: 'progress_saved_successfully', parameters: {'match_id': matchId});
      } else {
        print("MatchID was not in the response.");
        FirebaseAnalytics.instance.logEvent(name: 'progress_save_failed', parameters: {'reason': 'match_id_not_in_response'});
      }
    }
    else {
      print("Error saving progress: ${response.statusCode}");
      FirebaseAnalytics.instance.logEvent(name: 'progress_save_failed', parameters: {'reason': 'http_error', 'status_code': response.statusCode, 'response_body': response.body});
    }
  }

  Widget substitutionButton({
    required String imagePath,
    required int teamId,
    required BuildContext context,
    required Function(Map<String, dynamic>) onPlayerSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        FirebaseAnalytics.instance.logEvent(name: 'substitution_button_tapped', parameters: {'team_id': teamId});
        String? token = await loadToken();
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/player/team-players/$teamId'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            List<dynamic> players = jsonDecode(response.body);
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.black87,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) {
                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (ctx, index) {
                    final player = players[index];
                    return ListTile(
                      title: Text(
                        player['jerseyNumber'].toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        player['playerName'] ?? '',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onPlayerSelected(player);
                      },
                    );
                  },
                );
              },
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error fetching players: ${response.statusCode}')),
            );
            FirebaseAnalytics.instance.logEvent(name: 'substitution_fetch_players_failed', parameters: {'team_id': teamId, 'http_status': response.statusCode});
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unexpected error fetching players.')),
          );
          FirebaseAnalytics.instance.logEvent(name: 'substitution_fetch_players_failed', parameters: {'team_id': teamId, 'error': e.toString()});
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
          border: Border.all(color: Colors.yellow, width: 1),
        ),
      ),
    );
  }

  Widget scoreButton (String imagePath, String statKey, VoidCallback onPressed, int points) {
    return GestureDetector(
      onTap: () {
        if (selectedPlayerId != null) {
          updateStat(selectedPlayerId!, statKey);
        }
        onPressed();
        updatePoints(selectedTeam!, points);
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: getBorderColor(statKey), width: 1),
          image: DecorationImage(image: AssetImage(imagePath)),
        ),
      ),
    );
  }

  Widget actionButton (String imagePath, String statKey, VoidCallback onPressed) {
    return GestureDetector(
      onTap: () {
        if (selectedPlayerId != null) {
          updateStat(selectedPlayerId!, statKey);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a player first!')),
          );
          FirebaseAnalytics.instance.logEvent(name: 'action_button_failed', parameters: {'reason': 'no_player_selected'});
        }
        onPressed();
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: getBorderColor(statKey), width: 1),
          image: DecorationImage(image: AssetImage(imagePath)),
        ),
      ),
    );
  }

  void substitution(Map<String, dynamic> enteringPlayer) {
    FirebaseAnalytics.instance.logEvent(name: 'substitution_performed', parameters: {'entering_player_id': enteringPlayer['id'], 'leaving_player_id': selectedPlayerId});
    setState(() {
      if (selectedTeam == 1) {
        final index = widget.startersTeam1.indexWhere(
              (player) => player['id_player'] == selectedPlayerId,
        );
        print("INDEX : $index");
        if (index != -1) {
          widget.startersTeam1[index] = enteringPlayer;
        }
      } else if (selectedTeam == 2) {
        final index = widget.startersTeam2.indexWhere(
              (player) => player['id_player'] == selectedPlayerId,
        );
        if (index != -1) {
          widget.startersTeam2[index] = enteringPlayer;
        }
      }
      selectedPlayerId = null;
      selectedPlayerJerseyNumber = null;
      selectedTeam = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${enteringPlayer['playerName']} is in the court!")),
    );
  }

  void addActionToPlayer(String action) {
    setState(() {
      if (selectedTeam == 1 && selectedPlayerId != null) {
        team1Actions.insert(0, "$action\n${selectedPlayerJerseyNumber!}");
        Future.delayed(Duration(milliseconds: 100), () {
          _team1ScrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      } else if (selectedTeam == 2 && selectedPlayerId != null) {
        team2Actions.insert(0, "$action\n${selectedPlayerJerseyNumber!}");
        Future.delayed(Duration(milliseconds: 100), () {
          _team2ScrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  void updatePoints(int team, int points){
    team = selectedTeam!;
    if (team == 1){
      teamOneScore += points;
    } else {
      teamTwoScore += points;
    }
    FirebaseAnalytics.instance.logEvent(name: 'score_updated', parameters: {'team': team, 'points': points, 'team1_score': teamOneScore, 'team2_score': teamTwoScore});
  }

  Widget optionsButton (String imagePath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          image: DecorationImage(image: AssetImage(imagePath)),
        ),
      ),
    );
  }

  void showExtraMenu() {
    FirebaseAnalytics.instance.logEvent(name: 'extra_menu_opened');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.menu_book, color: Colors.white),
                title: Text("Legend", style: TextStyle(color: Colors.white)),
                onTap: () {
                  FirebaseAnalytics.instance.logEvent(name: 'legend_menu_item_clicked');
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.black.withOpacity(0.6),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/LegendsImage.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.flag, color: Colors.white),
                title: Text("Finish Match", style: TextStyle(color: Colors.white)),
                onTap: () {
                  FirebaseAnalytics.instance.logEvent(name: 'finish_match_menu_item_clicked');
                  Navigator.pop(context);
                  finishMatch();
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.red),
                title: Text(
                  "Exit Without Saving",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  FirebaseAnalytics.instance.logEvent(name: 'exit_without_saving_menu_item_clicked');
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Are you sure?"),
                        content: Text("All unsaved stats will be lost."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              FirebaseAnalytics.instance.logEvent(name: 'exit_without_saving_canceled');
                              Navigator.pop(context);
                            },
                            child: Text("Cancel", style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: () {
                              FirebaseAnalytics.instance.logEvent(name: 'exit_without_saving_confirmed');
                              Navigator.pop(context);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => MainScreen()),
                                    (Route<dynamic> route) => false,
                              );
                            },
                            child: Text("Exit", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    Widget buildActionCenter(bool isMobile) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFFFF4500),
              Color(0xFF84442E),
              Color(0xFF3A2E2E),
            ],
            stops: [0.0, 0.2, 0.7],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  "$teamOneScore X $teamTwoScore",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: isMobile ? 4 : 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                padding: EdgeInsets.zero,
                childAspectRatio: 1.5,
                children: [
                  scoreButton('assets/images/1PointActionIcon.png', "one_pointer", () => addActionToPlayer("1 Point Made"), 1),
                  scoreButton('assets/images/2PointActionIcon.png', "two_pointer", () => addActionToPlayer("2 Point Made"), 2),
                  scoreButton('assets/images/3PointActionIcon.png', "three_pointer", () => addActionToPlayer("3 Point Made"), 3),
                  actionButton('assets/images/1PointMissedActionIcon.png', "missed_one_pointer", () => addActionToPlayer("1 Point Missed")),
                  actionButton('assets/images/2PointMissedActionIcon.png', "missed_two_pointer", () => addActionToPlayer("2 Point Missed")),
                  actionButton('assets/images/3PointMissedActionIcon.png', "missed_three_pointer", () => addActionToPlayer("3 Point Missed")),
                  actionButton('assets/images/AssistActionIcon.png', "assist", () => addActionToPlayer("Assist")),
                  actionButton('assets/images/BlockActionIcon.png', "block", () => addActionToPlayer("Block")),
                  actionButton('assets/images/StealActionIcon.png', "steal", () => addActionToPlayer("Steal")),
                  actionButton('assets/images/OffensiveReboundActionIcon.png', "offensive_rebound", () => addActionToPlayer("O. Rebound")),
                  actionButton('assets/images/DefensiveReboundActionIcon.png', "defensive_rebound", () => addActionToPlayer("D. Rebound")),
                  actionButton('assets/images/TurnOverActionIcon.png', "turnover", () => addActionToPlayer("Turnover")),
                  actionButton('assets/images/FoulActionIcon.png', "foul", () => addActionToPlayer("Foul")),
                  optionsButton('assets/images/OptionsIcon.png', showExtraMenu),
                  substitutionButton(
                    imagePath: 'assets/images/SubstitutionActionIcon.png',
                    teamId: selectedTeam == 1 ? widget.team1["id"] : widget.team2["id"],
                    context: context,
                    onPlayerSelected: (player) {
                      substitution(player);
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      );
    }

    //Build action list
    Widget buildActionList(List actions, ScrollController controller) {
      return Expanded(
        flex: 5,
        child: Container(
          color: Colors.black,
          child: ListView.builder(
            controller: controller,
            padding: EdgeInsets.zero,
            itemCount: actions.length,
            itemBuilder: (context, index) {
              String action = actions[index];
              Color borderColor = getBorderColor(action);

              return Container(
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Center(
                  child: Text(
                    action.replaceAll("Offensive Rebound", "O.Rebound").replaceAll("Defensive Rebound", "D.Rebound"),
                    style: TextStyle(fontSize: 14, color: borderColor, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    //Build players list
    Widget buildPlayers(List starters, int teamNumber) {
      return Expanded(
        flex: 4,
        child: Container(
          color: Color(0xFF3A2E2E),
          child: Column(
            children: List.generate(
              widget.gameMode == "5x5" ? 5 : widget.gameMode == "3x3" ? 3 : 1,
                  (index) {
                String jerseyNumber = starters[index]['jerseyNumber'];
                int playerId = starters[index]['id_player'];
                bool isSelected = selectedPlayerId == playerId && selectedTeam == teamNumber;
                return GestureDetector(
                  onTap: () {
                    print("Id: $playerId\nJersey Number: $jerseyNumber");
                    setState(() {
                      selectedPlayerId = playerId;
                      selectedPlayerJerseyNumber = jerseyNumber;
                      selectedTeam = teamNumber;
                    });
                  },
                  child: Container(
                    color: isSelected ? Color(0xFFF6B712) : Colors.transparent,
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "$jerseyNumber",
                            style: TextStyle(color: Colors.white, fontSize: 37),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(width: 8),
                          Image.asset("assets/images/basketball.png", width: 40, height: 40),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
    //Build team column
    Widget buildTeamColumn(Map team, List starters, List actions, ScrollController controller, int teamNumber) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8.0),
            color: Color(0xFF3A2E2E),
            child: Text(
              "${team['abbreviation']}",
              style: TextStyle(
                color: Color(0xFFF6B712),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Row(
              children: teamNumber == 1
                  ? [buildPlayers(starters, teamNumber), buildActionList(actions, controller)]
                  : [buildActionList(actions, controller), buildPlayers(starters, teamNumber)],
            ),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return Scaffold(
            body: Column(
              children: [
                Expanded(child: buildTeamColumn(widget.team1, widget.startersTeam1, team1Actions, _team1ScrollController, 1)),
                SizedBox(
                  height: 350,
                  child: buildActionCenter(isMobile),
                ),
                Expanded(child: buildTeamColumn(widget.team2, widget.startersTeam2, team2Actions, _team2ScrollController, 2)),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: Row(
              children: [
                Expanded(child: buildTeamColumn(widget.team1, widget.startersTeam1, team1Actions, _team1ScrollController, 1)),
                Expanded(flex: 1, child: buildActionCenter(isMobile)),
                Expanded(child: buildTeamColumn(widget.team2, widget.startersTeam2, team2Actions, _team2ScrollController, 2)),
              ],
            ),
          );
        }
      },
    );
  }
}

