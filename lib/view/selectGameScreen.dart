import 'package:flutter/material.dart';
import 'selectTeamsNStarters.dart'; // Próxima tela
import 'package:orangescoutfe/util/verification_banner.dart';
import 'package:orangescoutfe/util/team_requirement_banner.dart';
import 'package:orangescoutfe/util/checks.dart';

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

  Future<void> _handleNavigation(BuildContext context, String gameMode) async {
    bool isValidated = await checkUserValidation();
    bool hasEnoughTeams = await checkUserTeams();

    if (!isValidated) {
      _showBanner(context, VerificationBanner());
    } else if (!hasEnoughTeams) {
      _showBanner(context, TeamRequirementBanner());
    } else {
      _navigateToGameScreen(context, gameMode);
    }
  }

  void _showBanner(BuildContext context, Widget banner) {
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
    return Scaffold(
      body: Container(
        width: double.infinity,  // Ocupa toda a largura
        height: double.infinity, // Ocupa toda a altura
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFFFF4500),
              Color(0xFF84442E),
              Colors.black,
            ],
            stops: [0.0, 0.2, 0.7],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _handleNavigation(context, "5x5"),
                child: Image.asset(
                  "assets/images/3x3-cutout.png",
                  width: 400,
                  height: 100,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _handleNavigation(context, "3x3"),
                child: Image.asset(
                  "assets/images/michael-cutout.png",
                  width: 400,
                  height: 100,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _handleNavigation(context, "1x1"),
                child: Image.asset(
                  "assets/images/west_harden-cutout.png",
                  width: 400,
                  height: 100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
