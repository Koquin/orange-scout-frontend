import 'package:flutter/material.dart';
import 'selectTeamsNStarters.dart'; // Próxima tela
import 'package:orangescoutfe/util/verification_banner.dart';
import 'package:orangescoutfe/util/team_requirement_banner.dart';
import 'package:orangescoutfe/util/checks.dart';

class SelectGameScreen extends StatefulWidget {
  final Function(Widget) onNavigate; // Função para trocar de tela no MainScreen
  const SelectGameScreen({Key? key, required this.onNavigate}) : super(key: key);


  @override
  _SelectGameScreenState createState() => _SelectGameScreenState();
}

class _SelectGameScreenState extends State<SelectGameScreen> {
  Future<void> _handleNavigation(String gameMode) async {
    bool isValidated = await checkUserValidation();
    bool hasEnoughTeams = await checkUserTeams();

    if (!isValidated) {
      _showBanner(VerificationBanner());
    } else if (!hasEnoughTeams) {
      _showBanner(TeamRequirementBanner());
    } else {
      // Agora, a navegação acontece dentro do MainScreen
      widget.onNavigate(SelectTeamsNStarters(
        gameMode: gameMode,
        onBack: () => widget.onNavigate(SelectGameScreen(onNavigate: widget.onNavigate)),
      ));
    }
  }

  void _showBanner(Widget banner) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: banner,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Color(0xFFFF4500),
            Color(0xFF84442E),
            Colors.black,
          ],
          stops: [0.0, 0.5, 0.9],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _handleNavigation("5x5"),
              child: Image.asset(
                "assets/images/5x5-cutout-cutout.png",
                width: 400,
                height: 100,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _handleNavigation("3x3"),
              child: Image.asset(
                "assets/images/3x3-cutout.png",
                width: 400,
                height: 100,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _handleNavigation("1x1"),
              child: Image.asset(
                "assets/images/west_harden-cutout.png",
                width: 400,
                height: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
