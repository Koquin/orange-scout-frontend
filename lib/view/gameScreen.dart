import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:OrangeScoutFE/util/token_utils.dart';

import 'mainScreen.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
  final Map<String, dynamic> team1;
  final Map<String, dynamic> team2;
  final List<dynamic> startersTeam1;
  final List<dynamic> startersTeam2;
  final String gameMode;
  final Map<String, dynamic> playerStats;


  const GameScreen({
    super.key,
    required this.team1,
    required this.team2,
    required this.startersTeam1,
    required this.startersTeam2,
    required this.gameMode,
    required this.playerStats,
  });

}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver{
  final ScrollController _team1ScrollController = ScrollController();
  final ScrollController _team2ScrollController = ScrollController();
  int? selectedPlayer;
  int? selectedTeam;
  List<String> team1Actions = [];
  List<String> team2Actions = [];
  Map<int, Map<String, int>> playerStats = {};
  int teamOneScore = 0;
  int teamTwoScore = 0;
  Future<String?>? token = loadToken();
  String endPointMatch = "http://192.168.18.31:8080/match";
  bool _hasSavedProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    playerStats = widget.playerStats.map((key, value) {
      return MapEntry(int.parse(key), Map<String, int>.from(value));
    });
  }

  Color getBorderColor(String action) {
    if (action.contains("1 Point Made") || action.contains("2 Point Made") || action.contains("3 Point Made")) {
      return Colors.green; // Acertos → Verde
    } else if (action.contains("Missed")|| action.contains("Turnover") || action.contains("Foul")) {
      return Colors.red; // Erros e faltas → Vermelho
    } else {
      return Colors.yellow; // Assist, block, steal, OR, DR, substituição → Amarelo
    }
  }

  Future<Map<String, double>?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location service disabled');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Permission denied permanently');
      return null;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    return {'latitude': position.latitude, 'longitude': position.longitude};
  }

  void updateStat(int jerseyNumber, String statKey) {
    setState(() {
      if (!playerStats.containsKey(jerseyNumber)) {
        playerStats[jerseyNumber] = {
          "jerseyNumber": jerseyNumber,
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
        print(playerStats);
      }

      playerStats[jerseyNumber]![statKey] = (playerStats[jerseyNumber]![statKey] ?? 0) + 1;
    });
  }


  void addActionToPlayer(String action) {
    setState(() {
      if (selectedTeam == 1 && selectedPlayer != null) {
        team1Actions.insert(0, "$action\n${selectedPlayer!}");
        Future.delayed(Duration(milliseconds: 100), () {
          _team1ScrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      } else if (selectedTeam == 2 && selectedPlayer != null) {
        team2Actions.insert(0, "$action\n${selectedPlayer!}");
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print("🌀 AppLifecycleState: ${state.name}");

    if (state == AppLifecycleState.paused) {
      print("💀 App está sendo destruído!");
      await saveMatchProgress();
    }
  }

  void finishMatch() async {
    print("🏁 Iniciando finishMatch...");

    String? token = await loadToken();
    print("🔑 Token carregado: $token");

    print("📍 Buscando localização atual...");
    Map<String, double>? location = await getCurrentLocation();
    if (location == null || !location.containsKey('latitude') || !location.containsKey('longitude')) {
      print('❌ Localização não encontrada ou incompleta: $location');
      return;
    }
    print("📍 Localização: lat=${location['latitude']}, long=${location['longitude']}");

    print("📊 Processando playerStats...");
    List<Map<String, dynamic>> statsList = playerStats.entries.map((entry) {
      print("Player stats: ${playerStats.entries}");
      final stats = entry.value;
      print(stats["jerseyNumber"]);
      return {
        "matchId": null,
        "statsId": null,
        "playerJersey": stats["jerseyNumber"],
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

    print("✅ Lista final de stats: $statsList");

    print("🛠️ Montando dados da partida...");
    Map<String, dynamic> matchData = {
      "matchId": null,
      "userId": null,
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
        "latitude": location['latitude'],
        "longitude": location['longitude']
      },
      "finished": true,
      "gamemode": widget.gameMode
    };
    print("📦 Corpo da requisição: $matchData");

    if (token == null) {
      print("❌ Token está nulo!");
      return;
    }

    print("📡 Enviando requisição para o endpoint: $endPointMatch");
    final response = await http.post(
      Uri.parse(endPointMatch),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(matchData),
    );

    print("🔵 Status Code da resposta: ${response.statusCode}");
    print("🔵 Corpo da resposta: ${response.body}");

    if (response.statusCode == 201) {
      print("🟢 Partida finalizada com sucesso!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      print("🔴 Erro ao finalizar a partida: ${response.statusCode}");
    }
  }

  Future<void> saveMatchProgress() async {
    if (_hasSavedProgress) {
      print("⚠️ Progresso já foi salvo. Ignorando nova chamada.");
      return;
    }
    _hasSavedProgress = true; // 🔒 Travar para próximas chamadas

    print("💾 Iniciando saveMatchProgress...");

    String? token = await loadToken();
    print("🔑 Token carregado: $token");

    print("📍 Buscando localização atual...");
    Map<String, double>? location = await getCurrentLocation();
    if (location == null || !location.containsKey('latitude') || !location.containsKey('longitude')) {
      print('❌ Localização não encontrada ou incompleta: $location');
      return;
    }
    print("📍 Localização: lat=${location['latitude']}, long=${location['longitude']}");

    print("📊 Processando playerStats...");
    List<Map<String, dynamic>> statsList = playerStats.entries.map((entry) {
      final stats = entry.value;
      return {
        "matchId": null,
        "statsId": null,
        "playerJersey": entry.key,
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

    print("✅ Lista final de stats: $statsList");

    print("🛠️ Montando dados da partida...");
    Map<String, dynamic> matchData = {
      "matchId": null,
      "userId": null,
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
        "latitude": location['latitude'],
        "longitude": location['longitude']
      },
      "finished": false,
      "gamemode": widget.gameMode
    };

    print("📦 Corpo da requisição: $matchData");

    if (token == null) {
      print("❌ Token está nulo!");
      return;
    }

    print("📡 Enviando requisição para o endpoint: $endPointMatch/save-progress");
    final response = await http.post(
      Uri.parse('$endPointMatch/save-progress'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(matchData),
    );

    print("🔵 Status Code da resposta: ${response.statusCode}");
    print("🔵 Corpo da resposta: ${response.body}");

    if (response.statusCode == 200) {
      print("🟢 Progresso da partida salvo com sucesso!");
    } else {
      print("🔴 Erro ao salvar progresso: ${response.statusCode}");
    }
  }


  Widget ElevatedScoreButton(String imagePath, String statKey, VoidCallback onPressed, int points) {
    return GestureDetector(
      onTap: () {
        if (selectedPlayer != null) {
          updateStat(selectedPlayer!, statKey);
        }
        onPressed(); // Mantém o callback original
        updatePoints(selectedTeam!, points);
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: AssetImage(imagePath)),
        ),
      ),
    );
  }

  Widget ElevatedActionButton(String imagePath, String statKey, VoidCallback onPressed) {
    return GestureDetector(
      onTap: () {
        if (selectedPlayer != null) {
          updateStat(selectedPlayer!, statKey);
        }
        onPressed();
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: AssetImage(imagePath)),
        ),
      ),
    );
  }

  Widget ElevatedActionButton2(String imagePath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: () {
        onPressed(); // Mantém o callback original
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: AssetImage(imagePath)),
        ),
      ),
    );
  }

  Widget ElevatedActionButtonSquare(String imagePath, VoidCallback onPressed) {
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
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.abc),
                title: Text("Legend"),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.add_chart),
                title: Text("Actual Stats"),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.ac_unit),
                title: Text("Finish Match"),
                onTap: () => finishMatch(),
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

    return Scaffold(
      body: Row(
        children: [
          // TIME 1 (Jogadores + Ações)
          Expanded(
            child: Column(
              children: [
                // Nome do time 1
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.0),
                  color: Color(0xFF3A2E2E),
                  child: Text(
                    "${widget.team1['abbreviation']}",
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
                    children: [
                      // Jogadores do Time 1 (Apenas números)
                      Expanded(
                        flex: 4, // Aumentando a largura
                        child: Container(
                          color: Color(0xFF3A2E2E),
                          child: Column(
                            children: List.generate(5, (index) {
                              int jerseyNumber = widget.startersTeam1[index]['jerseyNumber']; // Pegando o número do jogador
                              bool isSelected = selectedPlayer == jerseyNumber && selectedTeam == 1; // Comparando com o número do jogador

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    print(widget.team1);
                                    selectedPlayer = jerseyNumber; // Agora guarda o número do jogador
                                    selectedTeam = 1;
                                  });
                                },
                                child: Container(
                                  color: isSelected ? Color(0xFFF6B712) : Colors.transparent,
                                  padding: EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "$jerseyNumber", // Exibe o número correto
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (isSelected) ...[
                                        SizedBox(width: 8), // Espaço entre o número e a imagem
                                        Image.asset(
                                          "assets/images/basketball.png",
                                          width: 40, // Ajuste o tamanho da imagem
                                          height: 40,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),




                      Expanded(
                        flex: 5,
                        child: Container(
                          color: Colors.black, // Fundo preto
                          child: ListView.builder(
                            controller: _team1ScrollController,
                            padding: EdgeInsets.zero,
                            itemCount: team1Actions.length,
                            itemBuilder: (context, index) {
                              String action = team1Actions[index];
                              Color borderColor = getBorderColor(action);

                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black, // Fundo preto das ações
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.orange, width: 2), // Borda laranja ao redor da ação
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      action.replaceAll("Offensive Rebound", "O.Rebound").replaceAll("Defensive Rebound", "D.Rebound"),
                                      style: TextStyle(fontSize: 14, color: borderColor, fontWeight: FontWeight.bold), // Nome da ação com a cor correta
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),

          // Central de ações
          Expanded(
            flex: 1,
            child: Container(
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
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  Container(
                    height: 40,
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        "$teamOneScore X $teamTwoScore",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      padding: EdgeInsets.zero,
                      childAspectRatio: 1.5,
                      children: [
                        ElevatedScoreButton('assets/images/1PointActionIcon.png', "one_pointer", () => addActionToPlayer("1 Point Made"), 1),
                        ElevatedScoreButton('assets/images/2PointActionIcon.png', "two_pointer", () => addActionToPlayer("2 Point Made"), 2),
                        ElevatedScoreButton('assets/images/3PointActionIcon.png', "three_pointer", () => addActionToPlayer("3 Point Made"), 3),
                        ElevatedActionButton('assets/images/1PointMissedActionIcon.png', "missed_one_pointer", () => addActionToPlayer("1 Point Missed")),
                        ElevatedActionButton('assets/images/2PointMissedActionIcon.png', "missed_two_pointer", () => addActionToPlayer("2 Point Missed")),
                        ElevatedActionButton('assets/images/3PointMissedActionIcon.png', "missed_three_pointer", () => addActionToPlayer("3 Point Missed")),
                        ElevatedActionButton('assets/images/AssistActionIcon.png', "assist", () => addActionToPlayer("Assist")),
                        ElevatedActionButton('assets/images/BlockActionIcon.png', "block", () => addActionToPlayer("Block")),
                        ElevatedActionButton('assets/images/StealActionIcon.png', "steal", () => addActionToPlayer("Steal")),
                        ElevatedActionButton('assets/images/OffensiveReboundActionIcon.png', "offensive_rebound", () => addActionToPlayer("O. Rebound")),
                        ElevatedActionButton('assets/images/DefensiveReboundActionIcon.png', "defensive_rebound", () => addActionToPlayer("D. Rebound")),
                        ElevatedActionButton('assets/images/TurnOverActionIcon.png', "turnover", () => addActionToPlayer("Turnover")),
                        ElevatedActionButton('assets/images/FoulActionIcon.png', "foul", () => addActionToPlayer("Foul")),
                        ElevatedActionButtonSquare('assets/images/OptionsIcon.png', showExtraMenu), // Imagem para o botão de reticências
                        ElevatedActionButton2('assets/images/SubstitutionActionIcon.png', () => addActionToPlayer("Substitution")),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TIME 2 (Ações + Jogadores)
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.0),
                  color: Color(0xFF3A2E2E),
                  child: Text(
                    "${widget.team2['abbreviation']}",
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
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          color: Colors.black, // Fundo preto
                          child: ListView.builder(
                            controller: _team2ScrollController,
                            padding: EdgeInsets.zero,
                            itemCount: team2Actions.length,
                            itemBuilder: (context, index) {
                              String action = team2Actions[index];
                              Color borderColor = getBorderColor(action);

                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black, // Fundo preto das ações
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.orange, width: 2), // Borda laranja ao redor da ação
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      action.replaceAll("Offensive Rebound", "O.Rebound").replaceAll("Defensive Rebound", "D.Rebound"),
                                      style: TextStyle(fontSize: 14, color: borderColor, fontWeight: FontWeight.bold), // Nome da ação com a cor correta
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },

                          ),
                        ),
                      ),
                      // Jogadores do Time 2 (Apenas números)
                      Expanded(
                        flex: 4, // Aumentando a largura
                        child: Container(
                          color: Color(0xFF3A2E2E),
                          child: Column(
                            children: List.generate(5, (index) {
                              int jerseyNumber = widget.startersTeam2[index]['jerseyNumber']; // Pegando o número do jogador
                              bool isSelected = selectedPlayer == jerseyNumber && selectedTeam == 2; // Comparando com o número do jogador

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedPlayer = jerseyNumber; // Agora guarda o número do jogador
                                    selectedTeam = 2;
                                  });
                                },
                                child: Container(
                                  color: isSelected ? Color(0xFFF6B712) : Colors.transparent,
                                  padding: EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "$jerseyNumber", // Exibe o número correto
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (isSelected) ...[
                                        SizedBox(width: 8), // Espaço entre o número e a imagem
                                        Image.asset(
                                          "assets/images/basketball.png",
                                          width: 40, // Ajuste o tamanho da imagem
                                          height: 40,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
