import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StatsScreen extends StatefulWidget {
  final String matchId; //para teste de match 

  const StatsScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<dynamic> stats = [];
  bool isLoading = true;
  bool hasError = false;
  String token = 'seu_token_aqui'; // Idealmente carregado de SharedPreferences

  @override
  void initState() {
    super.initState();
    fetchMatchStats();
  }

  Future<void> fetchMatchStats() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('https://localhost:8000/stats/${widget.matchId}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          stats = jsonDecode(response.body);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : hasError
                ? const Text('Erro ao carregar estatísticas.')
                : ListView(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Jogador')),
                          DataColumn(label: Text('Pontos')),
                          DataColumn(label: Text('Assistências')),
                          DataColumn(label: Text('Roubos')),
                          // Adicionar mais células?
                        ],
                        rows: stats.map((player) {
                          return DataRow(cells: [
                            DataCell(Text(player['name'])),
                            DataCell(Text(player['points'].toString())),
                            DataCell(Text(player['assists'].toString())),
                            DataCell(Text(player['steals'].toString())),
                            // Adicionar mais células?
                          ]);
                        }).toList(),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('SAIR'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
