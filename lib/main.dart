import 'package:flutter/material.dart';
import 'view/mainScreen.dart';
import 'view/historyScreen.dart';
import 'view/registerScreen.dart';
import 'view/loginScreen.dart';
import 'view/verificationScreen.dart';
import 'package:OrangeScoutFE/util/checks.dart';
import 'package:OrangeScoutFE/util/token_utils.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? token = await loadToken();
  bool expiredToken = token == null || await isTokenExpired(token);

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
      },
    );
  }
}
