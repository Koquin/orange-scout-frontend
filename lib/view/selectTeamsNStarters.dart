import 'package:flutter/material.dart';

class SelectTeamsNStarters extends StatelessWidget {
  final String gameMode; // Recebe o modo de jogo selecionado

  const SelectTeamsNStarters({Key? key, required this.gameMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modo: $gameMode")), // Apenas exibe o modo por enquanto
      body: Center(
        child: Text(
          "Modo selecionado: $gameMode",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
