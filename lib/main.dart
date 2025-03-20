import 'package:flutter/material.dart';
import 'view/mainScreen.dart';
import 'view/historyScreen.dart';
import 'view/registerScreen.dart';
import 'view/loginScreen.dart';
import 'view/verificationScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:OrangeScoutFE/util/checks.dart';
import 'view/gameScreen.dart';
import 'controller/match_controller.dart';

Future<String?> _loadToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? token = await _loadToken(); // Espera carregar o token
  bool validToken = await validateToken(token); // Espera validar o token
  Map<String, dynamic>? lastMatch;
  if (token != null) {
    lastMatch = await checkLastMatch(token);
  } else {
    lastMatch = null;
  }

  runApp(MyApp(validToken: validToken, lastMatch: lastMatch ?? {}));
}

class MyApp extends StatelessWidget {
  final bool validToken;
  final Map<String, dynamic>? lastMatch;

  const MyApp({super.key, required this.validToken, required this.lastMatch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orange Scout',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: validToken
          ? (lastMatch != null
          ? LastMatchDialog(lastMatch: lastMatch!) // Usa '!' para garantir que não é nulo
          : MainScreen())
          : LoginScreen(),
      routes: {
        '/main': (context) => MainScreen(),
        '/history': (context) => HistoryScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/validationScreen': (context) => VerificationScreen(),
      },
    );
  }
}

class LastMatchDialog extends StatelessWidget {
  final Map<String, dynamic> lastMatch;

  const LastMatchDialog({super.key, required this.lastMatch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: AlertDialog(
        title: Text("You have an unfinished match"),
        content: Text("You want to continue it?"),
        actions: [
          TextButton(
            onPressed: () async {
              String? token = await _loadToken();
              if (token != null) {
                await finishMatch(lastMatch["id"], token);
              }
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainScreen()),
              );
            },
            child: Text("No"),
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
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }
}
