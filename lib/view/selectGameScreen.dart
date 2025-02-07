import 'package:flutter/material.dart';
import 'selectTeamsNStarters.dart'; // Importa a próxima tela

class SelectGameScreen extends StatelessWidget {
  const SelectGameScreen({Key? key}) : super(key: key);

  void _navigateToGameScreen(BuildContext context, String gameMode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectTeamsNStarters(gameMode: gameMode),
      ),
    );
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
              Color(0xFF3A2E2E),
            ],
            stops: [0.0, 0.2, 0.7],
          ),
        ),
        child: Center( // Garante que a Column fique centralizada
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _navigateToGameScreen(context, "5x5"),
                child: Image.asset("assets/images/west_harden-cutout.png", width: 300, height: 150),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () => _navigateToGameScreen(context, "3x3"),
                child: Image.asset("assets/images/west_harden-cutout.png", width: 300, height: 150),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () => _navigateToGameScreen(context, "1x1"),
                child: Image.asset("assets/images/west_harden-cutout.png", width: 300, height: 150),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
