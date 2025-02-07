import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final ScrollController _team1ScrollController = ScrollController();
  final ScrollController _team2ScrollController = ScrollController();
  int? selectedPlayer;
  int? selectedTeam;
  List<String> team1Actions = [];
  List<String> team2Actions = [];

  Color getBorderColor(String action) {
    if (action.contains("1 Point Made") || action.contains("2 Point Made") || action.contains("3 Point Made")) {
      return Colors.green; // Acertos → Verde
    } else if (action.contains("Missed")|| action.contains("Turnover") || action.contains("Foul")) {
      return Colors.red; // Erros e faltas → Vermelho
    } else {
      return Colors.yellow; // Assist, block, steal, OR, DR, substituição → Amarelo
    }
  }

  void addActionToPlayer(String action) {
    setState(() {
      if (selectedTeam == 1 && selectedPlayer != null) {
        team1Actions.insert(0, "$action\n${selectedPlayer! + 1}");
        Future.delayed(Duration(milliseconds: 100), () {
          _team1ScrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      } else if (selectedTeam == 2 && selectedPlayer != null) {
        team2Actions.insert(0, "$action\n${selectedPlayer! + 1}");
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


  Widget ElevatedActionButton(String imagePath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
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
                onTap: () => Navigator.pop(context),
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
                    "Team 1",
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
                              bool isSelected = selectedPlayer == index && selectedTeam == 1;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedPlayer = index;
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
                                        "${index + 1}",
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
                        "AÇÕES",
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
                        ElevatedActionButton('assets/images/1PointActionIcon.png', () => addActionToPlayer("1 Point Made")),
                        ElevatedActionButton('assets/images/2PointActionIcon.png', () => addActionToPlayer("2 Point Made")),
                        ElevatedActionButton('assets/images/3PointActionIcon.png', () => addActionToPlayer("3 Point Made")),
                        ElevatedActionButton('assets/images/1PointMissedActionIcon.png', () => addActionToPlayer("1 Point Missed")),
                        ElevatedActionButton('assets/images/2PointMissedActionIcon.png', () => addActionToPlayer("2 Point Missed")),
                        ElevatedActionButton('assets/images/3PointMissedActionIcon.png', () => addActionToPlayer("3 Point Missed")),
                        ElevatedActionButton('assets/images/AssistActionIcon.png', () => addActionToPlayer("Assist")),
                        ElevatedActionButton('assets/images/BlockActionIcon.png', () => addActionToPlayer("Block")),
                        ElevatedActionButton('assets/images/StealActionIcon.png', () => addActionToPlayer("Steal")),
                        ElevatedActionButton('assets/images/OffensiveReboundActionIcon.png', () => addActionToPlayer("O. Rebound")),
                        ElevatedActionButton('assets/images/DefensiveReboundActionIcon.png', () => addActionToPlayer("D. Rebound")),
                        ElevatedActionButton('assets/images/TurnOverActionIcon.png', () => addActionToPlayer("Turnover")),
                        ElevatedActionButton('assets/images/FoulActionIcon.png', () => addActionToPlayer("Foul")),
                        ElevatedActionButtonSquare('assets/images/OptionsIcon.png', showExtraMenu), // Imagem para o botão de reticências
                        ElevatedActionButton('assets/images/SubstitutionActionIcon.png', () => addActionToPlayer("Substitution")),
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
                    "Team 2",
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
                              bool isSelected = selectedPlayer == index && selectedTeam == 2;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedPlayer = index;
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
                                        "${index + 1}",
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
