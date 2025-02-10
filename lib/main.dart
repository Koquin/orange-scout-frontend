import 'package:flutter/material.dart';
import 'package:orangescoutfe/view/statScreen.dart';
import 'view/mainScreen.dart';
import 'view/historyScreen.dart';
import 'view/gameScreen.dart';
import 'view/registerScreen.dart';
import 'view/loginScreen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; //anuncio

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize(); //Inicializa o SDK do AdMob - Anuncio

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orange Scout',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: LoginScreen(),
      routes: {
        '/main': (context) => MainScreen(),
        '/history': (context) => HistoryScreen(),
        '/game': (context) => GameScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
       // '/stat': (context) => StatsScreen(),
      },
    );
  }
}
