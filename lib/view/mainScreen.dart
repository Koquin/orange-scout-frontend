import 'package:flutter/material.dart';
import 'package:orangescoutfe/view/teams_screen.dart';
import 'selectGameScreen.dart';
import 'historyScreen.dart';
import 'package:orangescoutfe/util/team_requirement_banner.dart';
import 'package:orangescoutfe/util/verification_banner.dart';
import 'package:orangescoutfe/util/checks.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  Widget _activeScreen = SelectGameScreen(onNavigate: (Widget screen) {});

  @override
  void initState() {
    super.initState();
    _activeScreen = SelectGameScreen(
      onNavigate: (Widget screen) {
        setState(() {
          _activeScreen = screen;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Orange Scout", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3b2f2f),
      ),
      body: _activeScreen, // Agora a tela é dinâmica
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF3c3030),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
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
