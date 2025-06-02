import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Import your DTOs
import 'package:OrangeScoutFE/dto/team_dto.dart';
import 'package:OrangeScoutFE/dto/player_dto.dart';
import 'package:OrangeScoutFE/dto/match_dto.dart';
import 'package:OrangeScoutFE/dto/stats_dto.dart';
import 'package:OrangeScoutFE/dto/location_dto.dart';

// Import your controllers
import 'package:OrangeScoutFE/controller/team_controller.dart';
import 'package:OrangeScoutFE/controller/player_controller.dart';
import 'package:OrangeScoutFE/controller/auth_controller.dart';
import 'package:OrangeScoutFE/controller/match_controller.dart';

// Import your utility
import 'package:OrangeScoutFE/util/persistent_snackbar.dart';

// Import your views
import 'package:OrangeScoutFE/view/gameScreen.dart';
import 'package:OrangeScoutFE/view/verificationScreen.dart';
import 'package:OrangeScoutFE/view/teamsScreen.dart';


class SelectTeamsNStarters extends StatefulWidget {
  final String gameMode;

  const SelectTeamsNStarters({
    super.key,
    required this.gameMode,
  });

  @override
  _SelectTeamsNStartersState createState() => _SelectTeamsNStartersState();
}

class _SelectTeamsNStartersState extends State<SelectTeamsNStarters> {
  String _pressedMode = "";
  List<TeamDTO> teams = [];
  int team1Index = 0;
  int team2Index = 1;
  List<PlayerDTO> playersTeam1 = [];
  List<PlayerDTO> playersTeam2 = [];
  List<PlayerDTO> selectedPlayersTeam1 = [];
  List<PlayerDTO> selectedPlayersTeam2 = [];

  final TeamController _teamController = TeamController();
  final PlayerController _playerController = PlayerController();
  final AuthController _authController = AuthController();
  final MatchController _matchController = MatchController();


  @override
  void initState() {
    super.initState();
    _setPortraitOrientation(); // Set orientation early
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'SelectTeamsNStartersScreen',
        screenClass: 'SelectTeamsNStartersState',
        parameters: {'game_mode': widget.gameMode},
      );
      // FIX: Move initial snackbar calls here
      PersistentSnackbar.show(
        context: context,
        message: "Certifique-se de que o Orange Scout pode usar TELA CHEIA no seu dispositivo antes de pressionar INICIAR.",
        backgroundColor: Colors.blueGrey.shade700,
        textColor: Colors.white,
        icon: Icons.info_outline,
        duration: const Duration(seconds: 7),
      );
      // FIX: Call _fetchTeamsAndPlayers after the above snackbar for proper context
      _fetchTeamsAndPlayers();
    });
  }

  // Ensures portrait orientation
  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Fetches teams and players from the backend.
  /// Handles initial loading and error states.
  Future<void> _fetchTeamsAndPlayers() async {
    FirebaseAnalytics.instance.logEvent(name: 'fetch_teams_and_players_attempt');

    // FIX: Show loading snackbar here as this method is now called *after* postFrameCallback
    PersistentSnackbar.show(
      context: context,
      message: "Carregando times e jogadores...",
      backgroundColor: Colors.blueGrey.shade700,
      textColor: Colors.white,
      icon: Icons.hourglass_empty,
      duration: const Duration(seconds: 5), // Make it visible while loading
    );

    try {
      final fetchedTeams = await _teamController.fetchUserTeams();
      setState(() {
        teams = fetchedTeams;
      });

      if (teams.length < 2) {
        if (mounted) {
          PersistentSnackbar.show(
            context: context,
            message: "Você precisa de pelo menos dois times para iniciar uma partida.",
            actionLabel: "Criar Times",
            onActionPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamsScreen()));
            },
            backgroundColor: Colors.red.shade700,
            textColor: Colors.white,
            icon: Icons.error_outline,
            duration: const Duration(seconds: 5),
          );
        }
        FirebaseAnalytics.instance.logEvent(name: 'not_enough_teams_for_game');
        Navigator.pop(context); // Go back to previous screen
        return;
      }

      if (team1Index == team2Index && teams.length > 1) {
        setState(() {
          team2Index = (team1Index + 1) % teams.length;
        });
      }

      await _fetchPlayersForSelectedTeam(teams[team1Index].id!, isTeam1: true);
      await _fetchPlayersForSelectedTeam(teams[team2Index].id!, isTeam1: false);
      PersistentSnackbar.hide(context); // Hide loading snackbar
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Error fetching teams and players for game setup');
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: "Erro ao carregar times e jogadores. Tente novamente.",
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 5),
        );
        Navigator.pop(context); // Go back on critical error
      }
    }
  }

  /// Fetches players for a given team ID from the backend.
  Future<void> _fetchPlayersForSelectedTeam(int teamId, {required bool isTeam1}) async {
    List<PlayerDTO> players = await _playerController.fetchPlayersByTeamId(teamId);
    setState(() {
      if (isTeam1) {
        playersTeam1 = players;
        selectedPlayersTeam1 = players.take(_getRequiredPlayersCount()).toList();
      } else {
        playersTeam2 = players;
        selectedPlayersTeam2 = players.take(_getRequiredPlayersCount()).toList();
      }
    });

    if (players.length < _getRequiredPlayersCount() && mounted) {
      PersistentSnackbar.show(
        context: context,
        message: "O time ${teams[isTeam1 ? team1Index : team2Index].abbreviation} não tem jogadores suficientes para o modo ${widget.gameMode}. Por favor, adicione mais jogadores.",
        backgroundColor: Colors.orange.shade700,
        textColor: Colors.white,
        icon: Icons.warning_amber_rounded,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// Determines the number of players required based on game mode.
  int _getRequiredPlayersCount() {
    switch (widget.gameMode) {
      case "5x5": return 5;
      case "3x3": return 3;
      case "1x1": return 1;
      default: return 5;
    }
  }

  /// Starts the game, navigating to GameScreen.
  void _startGame() {
    FirebaseAnalytics.instance.logEvent(name: 'start_game_button_pressed', parameters: {'game_mode': widget.gameMode});

    final requiredPlayers = _getRequiredPlayersCount();
    if (selectedPlayersTeam1.length < requiredPlayers || selectedPlayersTeam2.length < requiredPlayers) {
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: "Por favor, selecione jogadores suficientes para ambos os times.",
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 3),
        );
      }
      FirebaseAnalytics.instance.logEvent(name: 'start_game_failed', parameters: {'reason': 'not_enough_players_selected'});
      return;
    }

    final List<StatsDTO> initialStatsForGameScreen = [];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          userId: 0,
          matchId: null,
          teamOneScore: 0,
          teamTwoScore: 0,
          team1: teams[team1Index],
          team2: teams[team2Index],
          startersTeam1: selectedPlayersTeam1,
          startersTeam2: selectedPlayersTeam2,
          gameMode: widget.gameMode,
          initialPlayerStats: initialStatsForGameScreen,
        ),
      ),
    );
    FirebaseAnalytics.instance.logEvent(name: 'game_started_successfully', parameters: {'game_mode': widget.gameMode});
  }

  /// Shows a modal bottom sheet for player selection.
  void _showPlayerSelectionDialog(int slotIndex, bool isTeam1, List<PlayerDTO> availablePlayers) {
    FirebaseAnalytics.instance.logEvent(name: 'player_selection_dialog_opened', parameters: {'team_side': isTeam1 ? 'team1' : 'team2', 'player_index': slotIndex});

    final List<PlayerDTO> currentSelectedPlayers = isTeam1 ? selectedPlayersTeam1 : selectedPlayersTeam2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15.0,
                spreadRadius: 3.0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                "Selecionar Jogador",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFCC80),
                ),
              ),
              const Divider(color: Colors.white38, height: 24),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availablePlayers.length,
                  itemBuilder: (context, i) {
                    final player = availablePlayers[i];
                    final bool isAlreadySelected = currentSelectedPlayers.contains(player);

                    return Card(
                      color: Colors.white.withOpacity(0.08),
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isAlreadySelected ? Colors.grey : const Color(0xFFFF4500),
                          child: Text(
                            player.jerseyNumber,
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          player.playerName,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          "Camisa: ${player.jerseyNumber}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: isAlreadySelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                        onTap: isAlreadySelected ? null : () {
                          setState(() {
                            if (isTeam1) {
                              selectedPlayersTeam1[slotIndex] = player;
                            } else {
                              selectedPlayersTeam2[slotIndex] = player;
                            }
                          });
                          FirebaseAnalytics.instance.logEvent(
                            name: 'player_selected_in_dialog',
                            parameters: {
                              'team_side': isTeam1 ? 'team1' : 'team2',
                              'player_index_slot': slotIndex,
                              'player_id': player.idPlayer,
                              'player_name': player.playerName,
                            },
                          );
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    FirebaseAnalytics.instance.logEvent(name: 'player_selection_dialog_canceled');
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84442E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Cancelar", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Handles changing the selected team.
  void _changeTeam(bool isNext, bool isTeam1) {
    FirebaseAnalytics.instance.logEvent(name: 'change_team_button_pressed',
        parameters: {
          'direction': isNext ? 'next' : 'previous',
          'team_side': isTeam1 ? 'team1' : 'team2'
        });
    setState(() {
      int newIndex;
      if (isTeam1) {
        newIndex = team1Index;
        do {
          newIndex = (newIndex + (isNext ? 1 : -1));
          if (newIndex < 0) newIndex = teams.length - 1;
          newIndex = newIndex % teams.length;
        } while (newIndex == team2Index && teams.length > 1);
        team1Index = newIndex;
        _fetchPlayersForSelectedTeam(teams[team1Index].id!, isTeam1: true);
      } else {
        newIndex = team2Index;
        do {
          newIndex = (newIndex + (isNext ? 1 : -1));
          if (newIndex < 0) newIndex = teams.length - 1;
          newIndex = newIndex % teams.length;
        } while (newIndex == team1Index && teams.length > 1);
        team2Index = newIndex;
        _fetchPlayersForSelectedTeam(teams[team2Index].id!, isTeam1: false);
      }
    });
  }

  // --- UI Build Methods ---

  /// Builds the team selection widget for one side (Team 1 or Team 2).
  Widget _buildTeamSelection(bool isTeam1) {
    int teamIndex = isTeam1 ? team1Index : team2Index;
    List<PlayerDTO> selectedPlayers = isTeam1 ? selectedPlayersTeam1 : selectedPlayersTeam2;

    if (teams.isEmpty || teamIndex >= teams.length || teamIndex < 0) {
      return const SizedBox.shrink();
    }

    final TeamDTO currentTeam = teams[teamIndex];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Image.asset("assets/images/arrow_left.png", width: 50, height: 50),
              onPressed: () => _changeTeam(false, isTeam1),
            ),
            Column(
              children: [
                Text(
                  currentTeam.teamName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                _buildTeamLogo(currentTeam.logoPath),
              ],
            ),
            IconButton(
              icon: Image.asset("assets/images/arrow.png", width: 50, height: 50),
              onPressed: () => _changeTeam(true, isTeam1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildPlayersGrid(selectedPlayers, isTeam1),
      ],
    );
  }

  /// Builds the grid of selected players for a team.
  Widget _buildPlayersGrid(List<PlayerDTO> selectedPlayers, bool isTeam1) {
    int playerCount = _getRequiredPlayersCount();
    List<PlayerDTO> availablePlayers = isTeam1 ? playersTeam1 : playersTeam2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        playerCount,
            (index) => GestureDetector(
          onTap: () => _showPlayerSelectionDialog(index, isTeam1, availablePlayers),
          child: Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                selectedPlayers.length > index && selectedPlayers[index] != null
                    ? (selectedPlayers[index].jerseyNumber)
                    : '-',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget for Team Logos (copied from HistoryScreen, ensure it's in a shared utility or duplicated)
  Widget _buildTeamLogo(String? logoPath) {
    // FIX: Use the larger size here for consistency
    final double logoSize = 150.0; // Consistent with default in TeamsScreen's _buildTeamLogo
    if (logoPath != null && logoPath.isNotEmpty) {
      if (logoPath.startsWith('/data/') || logoPath.startsWith('file://')) {
        return Image.file(
          File(logoPath),
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Image.asset("assets/images/TeamShieldIcon-cutout.png", width: logoSize, height: logoSize),
        );
      } else {
        return Image.network(
          logoPath,
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Image.asset("assets/images/TeamShieldIcon-cutout.png", width: logoSize, height: logoSize),
        );
      }
    }
    return Image.asset("assets/images/TeamShieldIcon-cutout.png", width: logoSize, height: logoSize);
  }

  // Build method (main UI layout)
  @override
  Widget build(BuildContext context) {
    _setPortraitOrientation();

    return Scaffold(
      body: Container(
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
        child: teams.length < 2 // Check for minimum required teams
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTeamSelection(true),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.orange,
              ),
              onPressed: (selectedPlayersTeam1.length == _getRequiredPlayersCount() &&
                  selectedPlayersTeam2.length == _getRequiredPlayersCount())
                  ? _startGame
                  : null,
              child: const Text("INICIAR", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            _buildTeamSelection(false),
          ],
        ),
      ),
    );
  }
}