import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Import your DTOs
import 'package:OrangeScoutFE/dto/match_dto.dart';
import 'package:OrangeScoutFE/dto/team_dto.dart';

// Import your controllers
import 'package:OrangeScoutFE/controller/match_controller.dart';
import 'package:OrangeScoutFE/util/persistent_snackbar.dart';
import 'package:OrangeScoutFE/util/token_utils.dart';

// Import your views
import 'package:OrangeScoutFE/view/gameScreen.dart';
import 'package:OrangeScoutFE/view/historyScreen.dart';
import 'package:OrangeScoutFE/view/loginScreen.dart';
import 'package:OrangeScoutFE/view/selectGameScreen.dart';
import 'package:OrangeScoutFE/view/teamsScreen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final MatchController _matchController = MatchController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'MainScreen',
        screenClass: 'MainScreenState',
      );
      _checkLastUnfinishedMatch();
    });
  }

  /// Checks if there's a last unfinished match and prompts the user to continue it.
  Future<void> _checkLastUnfinishedMatch() async {
    debugPrint("Checking for last unfinished match...");
    final MatchDTO? lastMatch = await _matchController.checkLastUnfinishedMatch();

    if (lastMatch != null) {
      FirebaseAnalytics.instance.logEvent(name: 'unfinished_match_dialog_shown');
      _showLastMatchDialog(lastMatch);
    } else {
      FirebaseAnalytics.instance.logEvent(name: 'no_unfinished_match_to_show');
      debugPrint("No unfinished match found.");
    }
  }

  /// Displays a dialog asking the user to continue or discard an unfinished match.
  void _showLastMatchDialog(MatchDTO lastMatch) {
    debugPrint("Showing dialog for unfinished match: ${lastMatch.idMatch}");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A2E2E),
        title: const Text("Partida Inacabada", style: TextStyle(color: Colors.white)),
        content: const Text("Você tem uma partida não finalizada. Deseja continuar?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () async {
              FirebaseAnalytics.instance.logEvent(name: 'unfinished_match_dialog_discard');
              Navigator.of(context).pop();

              final bool success = await _matchController.finishMatch(lastMatch.idMatch!);
              if (success && mounted) {
                PersistentSnackbar.show(
                  context: context,
                  message: "Partida descartada com sucesso!",
                  backgroundColor: Colors.green.shade700,
                  textColor: Colors.white,
                  icon: Icons.check_circle_outline,
                );
              } else if (mounted) {
                PersistentSnackbar.show(
                  context: context,
                  message: "Falha ao descartar partida.",
                  backgroundColor: Colors.red.shade700,
                  textColor: Colors.white,
                  icon: Icons.error_outline,
                );
              }
            },
            child: const Text("Não", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(name: 'unfinished_match_dialog_continue');
              Navigator.of(context).pop();

              // Navigate to GameScreen with loaded data
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GameScreen(
                    teamOneScore: lastMatch.teamOneScore,
                    teamTwoScore: lastMatch.teamTwoScore,
                    userId: lastMatch.appUserId!, // Assumindo que userId nunca será nulo aqui
                    matchId: lastMatch.idMatch,
                    team1: lastMatch.teamOne,
                    team2: lastMatch.teamTwo,
                    startersTeam1: lastMatch.startersTeam1,
                    startersTeam2: lastMatch.startersTeam2,
                    gameMode: lastMatch.gameMode,
                    initialPlayerStats: lastMatch.stats,
                  ),
                ),
              );
            },
            child: const Text("Sim", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  /// Handles tap events on the bottom navigation bar.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    FirebaseAnalytics.instance.logEvent(
      name: 'bottom_nav_item_tapped',
      parameters: {'index': index},
    );
  }

  /// Handles user logout.
  Future<void> _logout() async {
    FirebaseAnalytics.instance.logEvent(name: 'logout_attempt');
    await clearToken();
    if (mounted) {
      FirebaseAnalytics.instance.logEvent(name: 'logout_success');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  /// Returns the widget corresponding to the selected navigation tab.
  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return const SelectGameScreen();
      case 1:
        return const TeamsScreen();
      case 2:
        return const HistoryScreen();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    _setPortraitOrientation();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text("Orange Scout", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3A2E2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: _getSelectedPage(),
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
            label: 'Iniciar Jogo',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 1
                  ? 'assets/images/TeamsSelectedButtonIcon.png'
                  : 'assets/images/TeamsButtonIcon.png',
              width: 80,
              height: 80,
            ),
            label: 'Times',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 2
                  ? 'assets/images/HistoryButtonIconSelected.png'
                  : 'assets/images/HistoryButtonIcon.png',
              width: 80,
              height: 80,
            ),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }

  // Helper for orientation
  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}