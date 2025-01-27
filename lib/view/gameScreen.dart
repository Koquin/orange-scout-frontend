import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Start Game"),
        backgroundColor: Colors.orange,
      ),
      body: Row(
        children: [
          // Coluna 1: TIME 1
          Expanded(
            child: Container(
            color: Color(0xFF3A2E2E),
            child: Column(
              children: [
                Container(
                  height: 50,
                  child: const Center(
                    child: Text(
                      "TIME 1",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF6B712)),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 5, // Exemplo de jogadores
                    itemBuilder: (context, index) => Container(
                      height: 50,
                      margin: const EdgeInsets.all(4),
                      child: Center(
                          child: Text("Jogador ${index + 1}", style: TextStyle(color: Color(0xFFF6B712)),)
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),

          // Coluna 2: AÇÕES DO TIME 1
          Expanded(
          child: Container(
          color: Color(0xFF3A2E2E),
            child: Column(
              children: [
                Container(
                  height: 50,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 5, // Exemplo de ações
                    itemBuilder: (context, index) => Container(
                      height: 50,
                      margin: const EdgeInsets.all(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),

          // Coluna 3: AÇÕES (CENTRAL)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Container(
                  color: Colors.orange.shade100,
                  height: 50,
                  child: const Center(
                    child: Text(
                      "AÇÕES",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3, // Organiza os botões centralmente
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    padding: const EdgeInsets.all(10),
                    children: List.generate(
                      9, // Exemplo de 9 botões de ações
                          (index) => ElevatedButton(
                        onPressed: () {},
                        child: Text("Ação ${index + 1}"),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Coluna 4: AÇÕES DO TIME 2
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  color: Colors.purple.shade100,
                  height: 50,
                  child: const Center(
                    child: Text(
                      "AÇÕES DO TIME 2",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 5, // Exemplo de ações
                    itemBuilder: (context, index) => Container(
                      height: 50,
                      margin: const EdgeInsets.all(4),
                      color: Colors.purple.shade200,
                      child: Center(child: Text("Ação ${index + 1}")),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Coluna 5: TIME 2
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  color: Colors.red.shade100,
                  height: 50,
                  child: const Center(
                    child: Text(
                      "TIME 2",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 5, // Exemplo de jogadores
                    itemBuilder: (context, index) => Container(
                      height: 50,
                      margin: const EdgeInsets.all(4),
                      color: Colors.red.shade200,
                      child: Center(child: Text("Jogador ${index + 1}")),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
