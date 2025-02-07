import 'package:flutter/material.dart';
import 'selectGameScreen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Controla a tela ativa

  // Lista de telas que serão mostradas na Navigation Bar
  final List<Widget> _screens = [
    SelectGameScreen(),  // Tela de seleção do modo de jogo
    //Teams(),         // Substitua por outra tela que deseja adicionar
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Altera a tela ativa
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Orange Scout"), // Nome do App
        backgroundColor: Colors.black,
      ),
      body: _screens[_selectedIndex], // Exibe a tela selecionada
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Muda a tela ao clicar
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_basketball),
            label: "Start Game",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Teams",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "History",
          ),
        ],
      ),
    );
  }
}
