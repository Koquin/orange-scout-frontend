import 'package:OrangeScoutFE/view/verificationScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Import your controllers
import 'package:OrangeScoutFE/controller/user_controller.dart'; // Remova se não usar
import 'package:OrangeScoutFE/controller/auth_controller.dart'; // Import AuthController for validation check
import 'package:OrangeScoutFE/controller/match_controller.dart'; // Import MatchController for teams check

// Import your DTOs
import 'package:OrangeScoutFE/dto/auth_result_dto.dart'; // Use AuthResult (já que AuthResult.token foi adaptado)
import 'package:OrangeScoutFE/dto/team_dto.dart'; // To get List<TeamDTO> from MatchController

// Import your utility
import 'package:OrangeScoutFE/util/persistent_snackbar.dart';

// Import your views
import 'package:OrangeScoutFE/view/selectTeamsNStarters.dart';
import 'package:OrangeScoutFE/view/teamsScreen.dart';

class SelectGameScreen extends StatefulWidget {
  const SelectGameScreen({super.key});

  @override
  _SelectGameScreenState createState() => _SelectGameScreenState();
}

class _SelectGameScreenState extends State<SelectGameScreen> {
  String _pressedMode = "";

  final AuthController _authController = AuthController();
  final MatchController _matchController = MatchController();

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'SelectGameScreen',
        screenClass: 'SelectGameScreenState',
      );
    });
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Handles the navigation logic based on game mode selection.
  /// Checks user validation and team count before proceeding.
  Future<void> _handleNavigation(String gameMode) async {
    FirebaseAnalytics.instance.logEvent(
      name: 'game_mode_selected',
      parameters: {'game_mode': gameMode},
    );

    // 1. Check user validation status
    AuthResult validationResult = await _authController.checkUserValidationStatus();

    // NOTE: AuthResult.token is a String. If it's used for isValidated status
    // and holds 'true' or 'false', compare it as a String.
    // However, it's better to add a specific `isValidated` bool to AuthResult.
    // For now, assuming your AuthResult.token holds 'true'/'false' as strings:
    if (!validationResult.success || validationResult.token == 'false') {
      FirebaseAnalytics.instance.logEvent(name: 'validation_needed_snackbar_shown');
      PersistentSnackbar.show(
        context: context,
        message: validationResult.userMessage ?? "Você precisa validar seu email para continuar.",
        actionLabel: "Validar",
        onActionPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificationScreen()));
        },
        backgroundColor: Colors.orange.shade700,
        textColor: Colors.white,
        icon: Icons.email,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    // 2. Check if user has enough teams
    bool hasEnoughTeams = await _matchController.validateStartGame();

    FirebaseAnalytics.instance.logEvent(
      name: 'user_teams_status',
      parameters: {'has_teams': hasEnoughTeams.toString()},
    );

    if (!hasEnoughTeams) {
      FirebaseAnalytics.instance.logEvent(name: 'teams_needed_snackbar_shown');
      PersistentSnackbar.show(
        context: context,
        message: "Você precisa de pelo menos dois times para iniciar uma partida.",
        actionLabel: "Criar Times",
        onActionPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamsScreen()));
        },
        backgroundColor: Colors.orange.shade700,
        textColor: Colors.white,
        icon: Icons.group,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    // If validated and has enough teams, navigate to SelectTeamsNStarters
    FirebaseAnalytics.instance.logEvent(
        name: 'navigate_to_select_teams_starters',
        parameters: {'game_mode': gameMode});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectTeamsNStarters(
          gameMode: gameMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setPortraitOrientation();

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
            Color(0xFF3A2E2E),
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

  // Helper widget to build game mode buttons
  Widget _buildGameModeButton(String mode, String imagePath) {
    return GestureDetector(
      onTap: () {
        setState(() => _pressedMode = mode);
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() => _pressedMode = "");
          _handleNavigation(mode);
        });
      },
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
          child: AnimatedScale(
            scale: _pressedMode == mode ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
                Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: Text(
                      mode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}