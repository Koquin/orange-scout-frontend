import 'package:OrangeScoutFE/view/createTeamScreen.dart';
import 'package:flutter/material.dart';
import 'view/mainScreen.dart';
import 'view/historyScreen.dart';
import 'view/registerScreen.dart';
import 'view/loginScreen.dart';
import 'view/verificationScreen.dart';
import 'package:OrangeScoutFE/util/checks.dart';
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  try {
    await dotenv.load();
  } catch (e) {
    print('Erro ao carregar .env: $e');
  }
  WidgetsFlutterBinding.ensureInitialized();

  String? token = await loadToken();
  bool expiredToken = token == null || await isTokenExpired(token);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp(expiredToken: expiredToken));
}

class MyApp extends StatelessWidget {
  final bool expiredToken;

  const MyApp({super.key, required this.expiredToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orange Scout',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: expiredToken ? LoginScreen() : MainScreen(),
      routes: {
        '/main': (context) => MainScreen(),
        '/history': (context) => HistoryScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/validationScreen': (context) => VerificationScreen(),
        '/createTeam': (context) => CreateTeamScreen(teamId: null),
      },
    );
  }
}
