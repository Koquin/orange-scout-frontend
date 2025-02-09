import 'package:flutter/material.dart';
import 'package:orangescoutfe/view/MatchDetailScreen.dart';
import 'dart:convert'; // Para manipulação de JSON
import 'package:google_mobile_ads/google_mobile_ads.dart'; //anuncio

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> matches = [];
  String token = 'token_aqui';
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    fetchMatches();
    _loadInterstitialAd(); // Carrega o anúncio na inicialização
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-6483916339248630/3524831551', //id do app para anuncio
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> fetchMatches() async {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        matches = [
          {
            'id': 'match1',
            'team1': 'Team 1',
            'team2': 'Team 2',
            'score': '15 x 2',
            'date': '2024/06/16',
            'team1Logo': 'https://example.com/team1_logo.png',
            'team2Logo': 'https://example.com/team2_logo.png',
          },
          {
            'id': 'match2',
            'team1': 'Team 3',
            'team2': 'Team 4',
            'score': '31 x 32',
            'date': '2024/04/13',
            'team1Logo': 'https://example.com/team3_logo.png',
            'team2Logo': 'https://example.com/team4_logo.png',
          },
          {
            'id': 'match3',
            'team1': 'Team 5',
            'team2': 'Team 6',
            'score': '70 x 64',
            'date': '2024/06/16',
            'team1Logo': 'https://example.com/team5_logo.png',
            'team2Logo': 'https://example.com/team6_logo.png',
          },
        ];
      });
    });
  }

  Future<bool> checkPremiumStatus() async {
    await Future.delayed(const Duration(seconds: 1));
    return false;
  }

  Future<void> fetchMatchStats(String matchId) async {
    await Future.delayed(const Duration(seconds: 1));
    final stats = {
      'matchId': matchId,
      'team1Stats': {
        'points': 15,
        'assists': 10,
        'rebounds': 5,
      },
      'team2Stats': {
        'points': 10,
        'assists': 8,
        'rebounds': 4,
      },
    };
  }

  void _showAdOrStats(String matchId) async {
    bool isPremium = await checkPremiumStatus();
    if (isPremium) {
      fetchMatchStats(matchId);
    } else {
      if (_interstitialAd != null) {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _loadInterstitialAd();
            fetchMatchStats(matchId);
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            fetchMatchStats(matchId);
          },
        );
        _interstitialAd!.show();
      } else {
        fetchMatchStats(matchId);
      }
    }
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
                                Image.network(matches[index]['team1Logo'], width: 60, height: 60),
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
                                Image.network(matches[index]['team2Logo'], width: 60, height: 60),
                              ],
                            ),

                            // Botão para ver as stats
                            IconButton(
                              icon: const Icon(Icons.stars),
                              color: Colors.orange,
                              onPressed: () async {
                                bool isPremium = await checkPremiumStatus();

                                if (isPremium) {
                                  // Se for premium, busca as stats
                                  fetchMatchStats(matches[index]['id']);
                                } else {
                                  // Caso contrário, exibe um anúncio (simulação)
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Anúncio"),
                                      content: const Text("Assista ao anúncio para acessar as stats!"),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            fetchMatchStats(matches[index]['id']);
                                          },
                                          child: const Text('Assistir'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Fechar'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
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
          // Adicionar navegação as telas
        },

        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}
