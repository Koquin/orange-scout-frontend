import 'package:flutter/material.dart';
import 'package:OrangeScoutFE/view/teamsScreen.dart';
import 'selectGameScreen.dart';
import 'historyScreen.dart';
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'loginScreen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Widget? _overlayPage;

  void _onItemTapped(int index) {
    setState(() {
      _overlayPage = null;
      _selectedIndex = index;
    });
  }

  void _navigateToOverlay(Widget page) {
    setState(() {
      _overlayPage = page is Container ? null : page;
    });
  }

  Future<void> _logout() async {
    await clearToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Orange Scout", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3b2f2f),
        actions: [
          IconButton(
            icon: Image.asset("assets/images/FinishIcon.png"),
            onPressed: _logout,
          ),
        ],
      ),
      body: _overlayPage ??
          IndexedStack(
            index: _selectedIndex,
            children: [
              SelectGameScreen(onNavigate: _navigateToOverlay),
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
            icon: Image.asset(
              _selectedIndex == 0
                  ? 'assets/images/StartGameButtonIconSelected.png'
                  : 'assets/images/StartGameButtonIcon.png',
              width: 80,
              height: 80,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 1
                  ? 'assets/images/TeamsSelectedButtonIcon.png'
                  : 'assets/images/TeamsButtonIcon.png',
              width: 80,
              height: 80,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 2
                  ? 'assets/images/HistoryButtonIconSelected.png'
                  : 'assets/images/HistoryButtonIcon.png',
              width: 80,
              height: 80,
            ),
            label: '',
          ),
        ],

      ),
    );
  }
}
