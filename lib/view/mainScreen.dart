import 'package:flutter/material.dart';
import 'package:OrangeScoutFE/view/teamsScreen.dart';
import 'package:OrangeScoutFE/view/selectGameScreen.dart';
import 'package:OrangeScoutFE/view/historyScreen.dart';
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:OrangeScoutFE/view/loginScreen.dart';
import 'package:OrangeScoutFE/controller/matchController.dart';
import 'package:OrangeScoutFE/view/gameScreen.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Widget? _overlayPage; // Reintroduzido para gerenciar overlays

  final MatchController _matchController = MatchController();

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'MainScreen',
        screenClass: 'MainScreenState',
      );
    });
    _checkLastMatchIfExists();
  }

  Future<void> _checkLastMatchIfExists() async {
    final Map<String, dynamic>? lastMatch = await _matchController.checkLastUnfinishedMatch();
    if (lastMatch != null) {
      FirebaseAnalytics.instance.logEvent(name: 'unfinished_match_dialog_shown');
      _showLastMatchDialog(lastMatch);
    } else {
      FirebaseAnalytics.instance.logEvent(name: 'no_unfinished_match_to_show');
    }
  }

  void _showLastMatchDialog(Map<String, dynamic> lastMatch) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A2E2E),
        title: const Text("You have an unfinished match", style: TextStyle(color: Colors.white)),
        content: const Text("Continue match?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () async {
              FirebaseAnalytics.instance.logEvent(name: 'unfinished_match_dialog_discard');
              final bool finished = await _matchController.finishMatch(lastMatch["idMatch"]);
              if (finished && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Match discarded successfully!")),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to discard match.")),
                );
              }
              Navigator.of(context).pop();
            },
            child: const Text("No", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(name: 'unfinished_match_dialog_continue');
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
                    gameMode: lastMatch["gameMode"],
                    playerStats: convertedStats,
                  ),
                ),
              );
            },
            child: const Text("Yes", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _overlayPage = null; // Garante que o overlay seja fechado ao mudar de aba
      _selectedIndex = index;
    });
    FirebaseAnalytics.instance.logEvent(
      name: 'bottom_nav_item_tapped',
      parameters: {'index': index},
    );
  }

  void _navigateToOverlay(Widget page) { // Reintroduzido para gerenciar overlays
    setState(() {
      _overlayPage = page is Container ? null : page; // Define o overlay, ou null para fechar
    });
    FirebaseAnalytics.instance.logEvent(
      name: 'overlay_page_navigated',
      parameters: {'page_type': page.runtimeType.toString()},
    );
  }

  Future<void> _logout() async {
    FirebaseAnalytics.instance.logEvent(name: 'logout_attempt');
    await clearToken();
    if (mounted) {
      FirebaseAnalytics.instance.logEvent(name: 'logout_success');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return SelectGameScreen(onNavigate: _navigateToOverlay); // Passa a função de navegação para overlay
      case 1:
        return TeamsScreen();
      case 2:
        return HistoryScreen();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text("Orange Scout", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3A2E2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _overlayPage ?? _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF3A2E2E),
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
