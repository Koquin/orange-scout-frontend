import 'package:flutter/material.dart';
import 'package:OrangeScoutFE/view/teamsScreen.dart';
import 'selectGameScreen.dart';
import 'historyScreen.dart';
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'loginScreen.dart';
import 'package:OrangeScoutFE/controller/match_controller.dart';
import 'gameScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Widget? _overlayPage;

  @override
  void initState() {
    super.initState();
    _checkLastMatchIfExists();
  }

  Future<void> _checkLastMatchIfExists() async {
    String? token = await loadToken();
    if (token == null) return;

    Map<String, dynamic>? lastMatch = await checkLastMatch();
    if (lastMatch != null) {
      print("Last match: $lastMatch");
      _showLastMatchDialog(lastMatch);
    }
  }

  void _showLastMatchDialog(Map<String, dynamic> lastMatch) {
    print("Last match como Map<String, dynamic>: $lastMatch");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("You have an unfinished match"),
        content: const Text("Continue match?"),
        actions: [
          TextButton(
            onPressed: () async {
              String? token = await loadToken();
              if (token != null) {
                await finishMatch(lastMatch["idMatch"], token);
              }
              Navigator.of(context).pop();
            },
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              final List<Map<String, dynamic>> convertedStats = (lastMatch["stats"] as List)
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GameScreen(
                    teamOneScore: lastMatch["teamOneScore"],
                    teamTwoScore: lastMatch["teamTwoScore"],
                    userId: lastMatch["userId"],
                    matchId: lastMatch["idMatch"],
                    team1: lastMatch["teamOne"],
                    team2: lastMatch["teamTwo"],
                    startersTeam1: lastMatch["startersTeam1"],
                    startersTeam2: lastMatch["startersTeam2"],
                    gameMode: lastMatch["gamemode"],
                    playerStats: convertedStats,
                  ),
                ),
              );
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _overlayPage = null;
      _selectedIndex = index;
    });
  }

  void _navigateToOverlay(Widget page) {
    setState(() {
      _overlayPage = page is Container ? null : page;
    });
  }

  Future<void> _logout() async {
    await clearToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return SelectGameScreen(onNavigate: _navigateToOverlay);
      case 1:
        return TeamsScreen(); // Será recarregado toda vez que for clicado
      case 2:
        return HistoryScreen(); // Também será recarregado
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Orange Scout", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3b2f2f),
        actions: [
          IconButton(
            icon: Image.asset("assets/images/FinishIcon.png"),
            onPressed: _logout,
          ),
        ],
      ),
      body: _overlayPage ?? _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF3c3030),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 0
                  ? 'assets/images/StartGameButtonIconSelected.png'
                  : 'assets/images/StartGameButtonIcon.png',
              width: 80,
              height: 80,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 1
                  ? 'assets/images/TeamsSelectedButtonIcon.png'
                  : 'assets/images/TeamsButtonIcon.png',
              width: 80,
              height: 80,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 2
                  ? 'assets/images/HistoryButtonIconSelected.png'
                  : 'assets/images/HistoryButtonIcon.png',
              width: 80,
              height: 80,
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}

