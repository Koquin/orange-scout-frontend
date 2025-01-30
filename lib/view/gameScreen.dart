import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int? selectedPlayer; // Armazena o ID do jogador selecionado globalmente
  int? selectedTeam; // Armazena qual time tem um jogador selecionado
  List<String> team1Actions = [];
  List<String> team2Actions = [];

  void addActionToPlayer(String action) {
    setState(() {
      if (selectedTeam == 1 && selectedPlayer != null) {
        team1Actions.add("J${selectedPlayer! + 1} - $action");
      } else if (selectedTeam == 2 && selectedPlayer != null) {
        team2Actions.add("J${selectedPlayer! + 1} - $action");
      }
    });
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
                leading: Icon(Icons.info),
                title: Text("Legendas"),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text("Estatísticas Atuais"),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.flag),
                title: Text("Finalizar Partida"),
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
                      // Jogadores do Time 1
                      Expanded(
                        child: Container(
                          color: Color(0xFF3A2E2E),
                          child: Column(
                            children: List.generate(5, (index) {
                              bool isSelected = selectedPlayer == index && selectedTeam == 1;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedPlayer = index;
                                    selectedTeam = 1; // Marca que o jogador selecionado é do Time 1
                                  });
                                },
                                child: Container(
                                  color: isSelected ? Color(0xFFF6B712) : Colors.transparent,
                                  padding: EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Jogador ${index + 1}",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      if (isSelected)
                                        Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Image.asset(
                                            'assets/IconeBasketBallAcoes.png', // Ícone personalizado
                                            width: 16,
                                            height: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      // Ações dos jogadores do Time 1
                      Expanded(
                        child: Container(
                          color: Colors.black,
                          child: Column(
                            children: team1Actions.map((action) {
                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(action, style: TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Color(0xFFFF4500), // Centro laranja
                    Color(0xFF84442E), // Meio
                    Color(0xFF3A2E2E), // Bordas escuras
                  ],
                  stops: [0.0, 0.2, 0.7],
                ),
              ),
              clipBehavior: Clip.hardEdge, // Evita linhas na borda
              child: Column(
                children: [
                  Container(
                    height: 40,
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        "AÇÕES",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10, // Sem espaço entre os botões
                      mainAxisSpacing: 0, // Sem espaço entre as linhas
                      padding: EdgeInsets.zero, // Remove qualquer padding
                      children: [
                        ...List.generate(14, (index) {
                          return SizedBox(
                            height: 30,
                            width: 30,
                            child: ElevatedButton(
                              onPressed: () {
                                addActionToPlayer("Ação ${index + 1}");
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.all(4),
                                backgroundColor: Colors.orange,
                              ),
                              child: Text("Ação ${index + 1}", style: TextStyle(fontSize: 10)),
                            ),
                          );
                        }),
                        SizedBox(
                          height: 30,
                          width: 30,
                          child: ElevatedButton(
                            onPressed: showExtraMenu,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(4),
                              backgroundColor: Colors.grey.shade700,
                            ),
                            child: Text("...", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
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
                // Nome do time 2
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
                      // Ações dos jogadores do Time 2
                      Expanded(
                        child: Container(
                          color: Colors.black,
                          child: Column(
                            children: team2Actions.map((action) {
                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(action, style: TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Jogadores do Time 2
                      Expanded(
                        child: Container(
                          color: Color(0xFF3A2E2E),
                          child: Column(
                            children: List.generate(5, (index) {
                              bool isSelected = selectedPlayer == index && selectedTeam == 2;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedPlayer = index;
                                    selectedTeam = 2; // Marca que o jogador selecionado é do Time 2
                                  });
                                },
                                child: Container(
                                  color: isSelected ? Color(0xFFF6B712) : Colors.transparent,
                                  padding: EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Jogador ${index + 1}", style: TextStyle(color: Colors.white)),
                                      if (isSelected)
                                        Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Image.asset('assets/IconeBasketBallAcoes.png', width: 16, height: 16),
                                        ),
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
