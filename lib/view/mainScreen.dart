import 'package:flutter/material.dart';
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
  int _selectedIndex = 0; // Controla a tela ativa
  bool _isValidated = true; // Estado inicial assume que o usuário está validado
  bool _hasEnoughTeams = true; // Estado inicial assume que o usuário tem times suficientes

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    bool validated = await checkUserValidation();
    bool hasTeams = await checkUserTeams();
    setState(() {
      _isValidated = validated;
      _hasEnoughTeams = hasTeams;
    });
  }

  // Lista de telas para a Bottom Navigation Bar
  final List<Widget> _screens = [
    SelectGameScreen(),  // Tela de seleção do modo de jogo
    HistoryScreen(),     // Tela de histórico
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Atualiza a tela ativa
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Orange Scout", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF3b2f2f),
      ),
      body: Column(
        children: [
          if (!_isValidated) VerificationBanner(),
          if (!_hasEnoughTeams) TeamRequirementBanner(),
          Expanded(child: _screens[_selectedIndex]), // Exibe a tela selecionada
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF3c3030),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Muda a tela ao clicar
        showSelectedLabels: false,
        showUnselectedLabels: false,
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
                  ? 'assets/images/TeamsSelectedButtonIcon.png'  // Ícone quando selecionado
                  : 'assets/images/TeamsButtonIcon.png',  // Ícone padrão
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
