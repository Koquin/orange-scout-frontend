import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:orangescoutfe/view/MatchDetailScreen.dart';
import 'package:orangescoutfe/util/verification_banner.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> matches = [];
  String token = 'seu_token_aqui';
  InterstitialAd? _interstitialAd;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchMatches();
    _loadInterstitialAd();
  }

  // Carrega o anúncio
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-6483916339248630/3524831551',
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

  // Faz GET para /match/user e pega as partidas do usuário autenticado
  Future<void> fetchMatches() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('https://localhost:8080/match/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          matches = data.map((match) => {
            'id': match['id'],
            'team1': match['teamOne']['abbr_team'],
            'team2': match['teamTwo']['abbr_team'],
            'score': '${match['teamOneScore']} x ${match['teamTwoScore']}',
            'date': match['date'],
            'team1Logo': match['teamOne']['team_logo_path'],
            'team2Logo': match['teamTwo']['team_logo_path'],
          }).toList();
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

  // Verifica se o usuário é premium
  Future<bool> checkPremiumStatus() async {
    try {
      final response = await http.get(
        Uri.parse('https://localhost:8080/user/premium'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Faz GET para /stats/{matchId}
  Future<void> fetchMatchStats(String matchId) async {
    try {
      final response = await http.get(
        Uri.parse('https://localhost:8080/stats/$matchId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final stats = jsonDecode(response.body);
        print(stats);
      } else {
        print('Erro ao buscar stats');
      }
    } catch (e) {
      print('Erro de conexão: $e');
    }
  }

  // configura o anúncio e busca stats
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
      body: Container(
        width: double.infinity,  // Ocupa toda a largura
        height: double.infinity, // Ocupa toda a altura
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFFFF4500),
              Color(0xFF84442E),
              Colors.black,
            ],
            stops: [0.0, 0.2, 0.7],
          ),
        ),

        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
                ? const Center(child: Text('Erro ao carregar partidas', style: TextStyle(color: Colors.red)))
                : ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchDetailView(match: matches[index]), //vai para a tela de starts, essa tela de matchDetail é para teste
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
                                VerificationBanner(),
                                Row(
                                  children: [
                                    Image.network(matches[index]['team1Logo'], width: 60, height: 60),
                                    const SizedBox(width: 10),
                                    Text(matches[index]['team1'], style: const TextStyle(color: Colors.white)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(matches[index]['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text(matches[index]['score'], style: const TextStyle(color: Colors.orange, fontSize: 18)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(matches[index]['team2'], style: const TextStyle(color: Colors.white)),
                                    const SizedBox(width: 10),
                                    Image.network(matches[index]['team2Logo'], width: 60, height: 60),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.stars, color: Colors.orange),
                                  onPressed: () => _showAdOrStats(matches[index]['id']),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
