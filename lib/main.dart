import 'package:flutter/material.dart';
import 'view/mainScreen.dart';
import 'view/historyScreen.dart';
import 'view/gameScreen.dart';
import 'view/selectGameScreen.dart';
import 'view/loginScreen.dart'; // Importa a tela de login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Basketball Game',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: LoginScreen(), // Sempre inicia na tela de login
      routes: {
        '/main': (context) => MainScreen(),
        '/history': (context) => HistoryScreen(),
        '/game': (context) => GameScreen(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
