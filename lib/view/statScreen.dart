import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:orangescoutfe/view/mapScreen.dart';

class StatsScreen extends StatefulWidget {
  final String matchId; //id da match

  const StatsScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<dynamic> stats = [];
  bool isLoading = true; //variavel para controle de carregamento da página
  Map<String, List<dynamic>> teamsStats = {}; //variavel dos times
  String? selectedTeamFilter; //variavel de seleção do filtro
  List<String> availableTeams = [];

  double latitude = 0.0; //variavel de latitude
  double longitude = 0.0; //variavel de longitude

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final response = await http
        .get(Uri.parse('http://192.168.1.16:8081/stats/${widget.matchId}'));//coloca de volta para localhost:8080

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      var statsList = jsonData['stats'];
      var location = jsonData['location']; // Pegando a localização corretamente

      Map<String, List<dynamic>> teamStats = {};
      for (var stat in statsList) {
        String team = stat['team'];
        if (!teamStats.containsKey(team)) {
          teamStats[team] = [];
        }
        teamStats[team]?.add(stat);
      }

      setState(() {
        stats = statsList;
        teamsStats = teamStats;
        availableTeams = teamStats.keys.toList();
        isLoading = false;

        // Armazenando latitude e longitude corretamente
        latitude = location['latitude'] ?? 0.0;
        longitude = location['longitude'] ?? 0.0;
      });
    } else {
      throw Exception('Falha ao carregar as estatísticas');
    }
  }


  void applyFilter(String filter) {
    setState(() {
      if (filter == 'Ambos') {
        selectedTeamFilter = null; // Quando for "Ambos", não filtra por time
      } else {
        selectedTeamFilter = filter;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<dynamic>> filteredStats = {};

    // Aplicar o filtro escolhido
    if (selectedTeamFilter != null) {
      filteredStats = {selectedTeamFilter!: teamsStats[selectedTeamFilter!] ?? []};
    } else {
      filteredStats = teamsStats;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Estatísticas da Partida'),
        backgroundColor: Color.fromARGB(255, 202, 66, 56),
        actions: [
          PopupMenuButton<String>(
            onSelected: applyFilter,//filtro de time
            itemBuilder: (context) => [
              ...availableTeams,
              'Ambos',
            ].map((team) => PopupMenuItem(
              value: team,
              child: Text(team),
            )).toList(),
          ),
        ],
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ //configura o degradê na vertical
                    const Color.fromARGB(255, 231, 148, 23),
                    const Color.fromARGB(255, 202, 66, 56),
                    const Color.fromARGB(255, 53, 33, 33),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),

              child: ListView(
                children: filteredStats.keys.map((team) {
                  var players = filteredStats[team];
                  if (players != null && players.isNotEmpty) { //faz um if para mostrar os times de acordo com o filtro

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            team,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),

                        Container(
                          margin: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6.0,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),

                          child: SingleChildScrollView( //aqui o cabeçalho tem que ficar de acordo com a ordem das estisticas e nome reais
                            scrollDirection: Axis.horizontal, //configura um scroll para a tabela
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Jogador')),
                                DataColumn(label: Text('3 pontos')),
                                DataColumn(label: Text('2 pontos')),
                                DataColumn(label: Text('1 ponto')),
                                DataColumn(label: Text('Erro 3 pontos')),
                                DataColumn(label: Text('Erro 2 pontos')),
                                DataColumn(label: Text('Erro 1 ponto')),
                                DataColumn(label: Text('Rebote ofensivo')),
                                DataColumn(label: Text('Rebote defensivo')),
                                DataColumn(label: Text('Roubo')),
                                DataColumn(label: Text('Assistência')),
                                DataColumn(label: Text('Bloqueio')),
                                DataColumn(label: Text('Turnover')),
                                DataColumn(label: Text('Falta')),
                              ],
                              rows: players.map((playerStats) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(playerStats['playerName'])),
                                    DataCell(Text(playerStats['threePoints'].toString())),
                                    DataCell(Text(playerStats['twoPoints'].toString())),
                                    DataCell(Text(playerStats['onePoint'].toString())),
                                    DataCell(Text(playerStats['missThreePoints'].toString())),
                                    DataCell(Text(playerStats['missTwoPoints'].toString())),
                                    DataCell(Text(playerStats['missOnePoint'].toString())),
                                    DataCell(Text(playerStats['offensiveRebound'].toString())),
                                    DataCell(Text(playerStats['defensiveRebound'].toString())),
                                    DataCell(Text(playerStats['steal'].toString())),
                                    DataCell(Text(playerStats['assist'].toString())),
                                    DataCell(Text(playerStats['block'].toString())),
                                    DataCell(Text(playerStats['turnover'].toString())),
                                    DataCell(Text(playerStats['foul'].toString())),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Nenhum jogador encontrado para $team',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                }).toList(),
              ),
            ),

          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (latitude != 0.0 && longitude != 0.0) { //verifica os valores de latitude e longitude
                Navigator.push(
                  context,
                  MaterialPageRoute( //chama a tela de mapa
                    builder: (context) => MapScreen(
                      latitude: latitude,
                      longitude: longitude,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Localização não disponível')),
                );
              }
            },

            backgroundColor: Color.fromARGB(255, 202, 66, 56),
            child: Image.asset(
              'assets/images/localizacao.png',
              width: 40,
              height: 40,
            ),
          )
    );
  }
}