import 'package:flutter/material.dart';
import 'view/mainScreen.dart';
import 'view/historyScreen.dart';
import 'view/registerScreen.dart';
import 'view/loginScreen.dart';
import 'view/verificationScreen.dart';
import 'package:OrangeScoutFE/util/checks.dart';
import 'view/gameScreen.dart';
import 'controller/match_controller.dart';
import 'package:OrangeScoutFE/util/token_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? token = await loadToken();
  bool expiredToken = token == null || await isTokenExpired(token);
  Map<String, dynamic>? lastMatch = token != null ? await checkLastMatch(token) : null;

  print('Token expirado?: $expiredToken');
  print('Token existe?: $token');
  print('Última partida?: $lastMatch');

  runApp(MyApp(expiredToken: expiredToken, lastMatch: lastMatch));
}

class MyApp extends StatelessWidget {
  final bool expiredToken;
  final Map<String, dynamic>? lastMatch;

  const MyApp({super.key, required this.expiredToken, required this.lastMatch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orange Scout',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: _getHomeScreen(),
      routes: {
        '/main': (context) => MainScreen(),
        '/history': (context) => HistoryScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/validationScreen': (context) => VerificationScreen(),
      },
    );
  }

  Widget _getHomeScreen() {
    if (expiredToken) {
      return LoginScreen();
    } else if (lastMatch != null) {
      return LastMatchDialog(lastMatch: lastMatch!);
    } else {
      return MainScreen();
    }
  }
}

class LastMatchDialog extends StatelessWidget {
  final Map<String, dynamic> lastMatch;

  const LastMatchDialog({super.key, required this.lastMatch});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("You have an unfinished match"),
      content: const Text("Do you want to continue it?"),
      actions: [
        TextButton(
          onPressed: () async {
            String? token = await loadToken();
            if (token != null) {
              await finishMatch(lastMatch["id"], token);
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          },
          child: const Text("No"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GameScreen(
                  team1: lastMatch["team1"],
                  team2: lastMatch["team2"],
                  startersTeam1: lastMatch["startersTeam1"],
                  startersTeam2: lastMatch["startersTeam2"],
                  gameMode: lastMatch["gameMode"],
                  playerStats: lastMatch["playerStats"],
                ),
              ),
            );
          },
          child: const Text("Yes"),
        ),
      ],
    );
  }
}
