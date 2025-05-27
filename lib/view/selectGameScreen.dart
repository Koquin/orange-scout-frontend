import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'selectTeamsNStarters.dart';
import 'package:OrangeScoutFE/util/persistent_snackBar.dart';
import 'package:OrangeScoutFE/util/checks.dart';

class SelectGameScreen extends StatefulWidget {
  final Function(Widget) onNavigate;
  const SelectGameScreen({super.key, required this.onNavigate});

  @override
  _SelectGameScreenState createState() => _SelectGameScreenState();
}

class _SelectGameScreenState extends State<SelectGameScreen> {
  String _pressedMode = "";
  //Base url
  String? baseUrl = dotenv.env['API_BASE_URL'];

  Future<void> _handleNavigation(String gameMode) async {
    bool isValidated = await checkUserValidation();
    bool hasEnoughTeams = await checkUserTeams();

    if (!isValidated) {
      PersistentSnackbar.show(
        context: context,
        message: "You need to validate your email",
        actionTitle: "Validation Screen",
        navigation: "/validationScreen",
      );
    } else if (!hasEnoughTeams) {
      PersistentSnackbar.show(
        context: context,
        message: "You need at least two teams to start",
        actionTitle: "Create team",
        navigation: "/createTeam",
      );
    } else {
      widget.onNavigate(
        SelectTeamsNStarters(
          gameMode: gameMode,
          onBack: () => widget.onNavigate(Container()),
          changeScreen: widget.onNavigate,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

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
            _buildGameModeButton("5x5", "assets/images/5x5.png"),
            const SizedBox(height: 20),
            _buildGameModeButton("3x3", "assets/images/3x3.png"),
            const SizedBox(height: 20),
            _buildGameModeButton("1x1", "assets/images/1x1.png"),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeButton(String mode, String imagePath) {
    return GestureDetector(
      onTap: () => _handleNavigation(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: 300,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTapDown: (_) => setState(() => _pressedMode = mode),
            onTapUp: (_) {
              setState(() => _pressedMode = "");
              _handleNavigation(mode);
            },
            child: AnimatedScale(
              scale: _pressedMode == mode ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Image.asset(
                imagePath,
                width: 300,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
