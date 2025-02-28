import 'package:flutter/material.dart';
import 'package:orangescoutfe/view/teams_screen.dart';
import 'selectGameScreen.dart';
import 'historyScreen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Índice da tela ativa

  // Método para mudar de tela ao tocar no BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Orange Scout", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3b2f2f),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SelectGameScreen(onNavigate: (Widget page) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => page));
          }),

          TeamsScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF3c3030),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/StartGameButtonIcon.png', width: 80, height: 80),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/TeamsButtonIcon.png', width: 80, height: 80),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/HistoryButtonIcon.png', width: 80, height: 80),
            label: '',
          ),
        ],
      ),
    );
  }
}
