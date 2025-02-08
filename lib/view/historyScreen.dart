import 'package:flutter/material.dart';
import 'package:orangescoutfe/view/MatchDetailScreen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> matches = [];

  @override
  void initState() {
    super.initState();
    fetchMatches();
  }

  void fetchMatches() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        matches = [
          {'team1': 'Team 1', 'team2': 'Team 2', 'score': '15 x 2', 'date': '2024/06/16'},
          {'team1': 'Team 3', 'team2': 'Team 4', 'score': '31 x 32', 'date': '2024/04/13'},
          {'team1': 'Team 5', 'team2': 'Team 6', 'score': '70 x 64', 'date': '2024/06/16'},
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('TEAM 1', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[900],
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.orange, Colors.black],
          ),
        ),
        child: matches.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchDetailView(match: matches[index]),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.black54,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Ícone e nome do Time 1
                            Row(
                              children: [
                                Image.asset('assets/images/pngwing.com.png', width: 60, height: 60),
                                const SizedBox(width: 10),
                                Text(
                                  matches[index]['team1'],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),

                            // Placar
                            Column(
                              children: [
                                Text(
                                  matches[index]['date'],
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  matches[index]['score'],
                                  style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),

                            // Ícone e nome do Time 2
                            Row(
                              children: [
                                Text(
                                  matches[index]['team2'],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 10),
                                Image.asset('assets/images/pngwing.com.png', width: 60, height: 60),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.brown[900],
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/TeamsButtonIcon.png', width: 50, height: 50),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/StartGameButtonIcon.png', width: 50, height: 50),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/HistoryButtonIcon.png', width: 50, height: 50),
            label: '',
          ),
        ],
        onTap: (index) {
          // Adicionar navegação entre telas
        },

        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),

    );
  }
}
