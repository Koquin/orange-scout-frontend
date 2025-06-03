// lib/view/gameScreen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Import your DTOs
import 'package:OrangeScoutFE/dto/location_dto.dart';
import 'package:OrangeScoutFE/dto/match_dto.dart';
import 'package:OrangeScoutFE/dto/player_dto.dart';
import 'package:OrangeScoutFE/dto/stats_dto.dart';
import 'package:OrangeScoutFE/dto/team_dto.dart';

// Import your controllers
import 'package:OrangeScoutFE/controller/location_controller.dart';
import 'package:OrangeScoutFE/controller/match_controller.dart';
import 'package:OrangeScoutFE/controller/player_controller.dart';
import 'package:OrangeScoutFE/util/persistent_snackbar.dart';

import 'mainScreen.dart';

class GameScreen extends StatefulWidget {
  final TeamDTO team1;
  final TeamDTO team2;
  final List<PlayerDTO> startersTeam1;
  final List<PlayerDTO> startersTeam2;
  final String gameMode;
  final List<StatsDTO> initialPlayerStats;
  final int userId;
  final int? matchId; // Nullable for new matches
  final int teamOneScore;
  final int teamTwoScore;

  const GameScreen({
    super.key,
    required this.team1,
    required this.team2,
    required this.startersTeam1,
    required this.startersTeam2,
    required this.gameMode,
    required this.initialPlayerStats,
    required this.userId,
    this.matchId,
    required this.teamOneScore,
    required this.teamTwoScore,
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final LocationController _locationController = LocationController();
  final MatchController _matchController = MatchController();
  final PlayerController _playerController = PlayerController();

  final ScrollController _team1ScrollController = ScrollController();
  final ScrollController _team2ScrollController = ScrollController();

  List<String> team1Actions = [];
  List<String> team2Actions = [];

  PlayerDTO? selectedPlayer;
  TeamDTO? selectedTeam;
  Map<int, StatsDTO> playerStats = {}; // Map player ID to StatsDTO
  bool _hasSavedProgressOnPause = false;

  int teamOneScore = 0;
  int teamTwoScore = 0;
  int? currentMatchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // FIX: Conditionally add match_id_initial or convert to String if null
    final Map<String, Object> screenParams = {
      'game_mode': widget.gameMode,
    };
    if (widget.matchId != null) {
      screenParams['match_id_initial'] = widget.matchId!; // It's an int, so it's fine
    } else {
      // Option 1: Don't send if null (cleaner)
      // Option 2: Send as a string like 'new_match'
      screenParams['match_id_initial'] = 'new_match'; // Example of Option 2
    }

    FirebaseAnalytics.instance.logScreenView(
      screenName: 'GameScreen',
      screenClass: 'GameScreenState',
      parameters: screenParams, // Use the prepared map
    );

    teamOneScore = widget.teamOneScore;
    teamTwoScore = widget.teamTwoScore;
    currentMatchId = widget.matchId;

    _initializePlayerStats();
  }

  void _initializePlayerStats() {
    if (widget.initialPlayerStats.isNotEmpty) {
      for (var statDTO in widget.initialPlayerStats) {
        if (statDTO.playerId != null) {
          playerStats[statDTO.playerId!] = statDTO.copyWith(matchId: currentMatchId); // Ensure matchId is updated
          debugPrint("Resuming stats for player ${statDTO.playerId}");
        }
      }
      FirebaseAnalytics.instance.logEvent(name: 'game_resumed', parameters: {'match_id': currentMatchId});
    } else {
      for (var player in widget.startersTeam1) {
        playerStats[player.idPlayer!] = StatsDTO(
            matchId: currentMatchId, // matchId can be null initially for new games
            playerId: player.idPlayer!,
            threePointers: 0, twoPointers: 0, onePointers: 0,
            missedThreePointers: 0, missedTwoPointers: 0, missedOnePointers: 0,
            steals: 0, turnovers: 0, blocks: 0, assists: 0,
            offensiveRebounds: 0, defensiveRebounds: 0, fouls: 0,
            playerJersey: player.jerseyNumber,
            teamName: widget.team1.teamName
        );
      }
      for (var player in widget.startersTeam2) {
        playerStats[player.idPlayer!] = StatsDTO(
            matchId: currentMatchId, // matchId can be null initially for new games
            playerId: player.idPlayer!,
            threePointers: 0, twoPointers: 0, onePointers: 0,
            missedThreePointers: 0, missedTwoPointers: 0, missedOnePointers: 0,
            steals: 0, turnovers: 0, blocks: 0, assists: 0,
            offensiveRebounds: 0, defensiveRebounds: 0, fouls: 0,
            playerJersey: player.jerseyNumber,
            teamName: widget.team2.teamName
        );
      }
      FirebaseAnalytics.instance.logEvent(name: 'new_game_started', parameters: {'game_mode': widget.gameMode});
    }
  }

  Color getBorderColor(String actionType) {
    if (actionType.contains("Point") && !actionType.contains("Missed")) {
      return Colors.green;
    } else if (actionType.contains("Missed") || actionType.contains("Turnover") || actionType.contains("Foul")) {
      return Colors.red;
    } else {
      return Colors.yellow;
    }
  }

  void updateStat(int playerId, String statKey) {
    setState(() {
      if (!playerStats.containsKey(playerId)) {
        playerStats[playerId] = StatsDTO(
          matchId: currentMatchId,
          playerId: playerId,
          threePointers: 0, twoPointers: 0, onePointers: 0,
          missedThreePointers: 0, missedTwoPointers: 0, missedOnePointers: 0,
          steals: 0, turnovers: 0, blocks: 0, assists: 0,
          offensiveRebounds: 0, defensiveRebounds: 0, fouls: 0,
        );
      }

      final currentStats = playerStats[playerId]!;
      playerStats[playerId] = _incrementStat(currentStats, statKey);

      FirebaseAnalytics.instance.logEvent(
        name: 'stat_updated',
        parameters: {
          'player_id': playerId,
          'stat_key': statKey,
          'new_value': playerStats[playerId]!.toJson()[statKey], // To get the value as String/num for the log
          'game_mode': widget.gameMode,
        },
      );
    });
  }

  StatsDTO _incrementStat(StatsDTO stats, String statKey) {
    switch (statKey) {
      case "threePointers": return stats.copyWith(threePointers: stats.threePointers + 1);
      case "twoPointers": return stats.copyWith(twoPointers: stats.twoPointers + 1);
      case "onePointers": return stats.copyWith(onePointers: stats.onePointers + 1);
      case "missedThreePointers": return stats.copyWith(missedThreePointers: stats.missedThreePointers + 1);
      case "missedTwoPointers": return stats.copyWith(missedTwoPointers: stats.missedTwoPointers + 1);
      case "missedOnePointers": return stats.copyWith(missedOnePointers: stats.missedOnePointers + 1);
      case "steals": return stats.copyWith(steals: stats.steals + 1);
      case "turnovers": return stats.copyWith(turnovers: stats.turnovers + 1);
      case "blocks": return stats.copyWith(blocks: stats.blocks + 1);
      case "assists": return stats.copyWith(assists: stats.assists + 1);
      case "offensiveRebounds": return stats.copyWith(offensiveRebounds: stats.offensiveRebounds + 1);
      case "defensiveRebounds": return stats.copyWith(defensiveRebounds: stats.defensiveRebounds + 1);
      case "fouls": return stats.copyWith(fouls: stats.fouls + 1);
      default: return stats;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _team1ScrollController.dispose();
    _team2ScrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      debugPrint("App life cycle state changed to: $state");
      await _saveMatchProgress(isFinished: false);
    } else if (state == AppLifecycleState.resumed) {
      _hasSavedProgressOnPause = false;
    }
  }

  Future<void> _finishMatch() async {
    FirebaseAnalytics.instance.logEvent(name: 'finish_match_button_pressed');

    if (currentMatchId == null) {
      PersistentSnackbar.show(
        context: context,
        message: 'Error: match ID not found to finish.',
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        icon: Icons.error_outline,
      );
      return;
    }

    final bool success = await _matchController.finishMatch(currentMatchId!);
    if (success) {
      PersistentSnackbar.show(
        context: context,
        message: 'Match finished successfully!',
        backgroundColor: Colors.green.shade700,
        textColor: Colors.white,
        icon: Icons.check_circle_outline,
      );
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      PersistentSnackbar.show(
        context: context,
        message: 'Failed finishing match. Try again.',
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _saveMatchProgress({required bool isFinished}) async {
    // Skip saving if already saved on pause and not explicitly finishing
    if (_hasSavedProgressOnPause && !isFinished) {
      FirebaseAnalytics.instance.logEvent(name: 'save_progress_skipped_already_saved');
      debugPrint("Progress has already been saved on pause.");
      return;
    }

    FirebaseAnalytics.instance.logEvent(name: 'save_progress_attempt', parameters: {'is_finished': isFinished});

    LocationDTO? locationDTO;
    // Only fetch location data if the match is being finished
    if (isFinished) {
      try {
        locationDTO = await _locationController.getCurrentLocationData();
        if (locationDTO == null) {
          PersistentSnackbar.show(
            context: context,
            message: 'Not possible to fetch location. Match will be saved without location.',
            backgroundColor: Colors.orange.shade700,
            textColor: Colors.white,
            icon: Icons.warning_amber_rounded,
            duration: const Duration(seconds: 4),
          );
        }
        FirebaseAnalytics.instance.logEvent(name: 'location_fetched_for_match', parameters: {'status': locationDTO != null ? 'success' : 'failed'});
      } catch (e) {
        FirebaseAnalytics.instance.logEvent(name: 'location_fetch_failed', parameters: {'error': e.toString()});
        debugPrint('Error getting location: $e');
      }
    }

    // Prepare the list of StatsDTOs
    final List<StatsDTO> currentStatsList = playerStats.values.map((stats) {
      // Ensure matchId is set for each stat, using currentMatchId
      return stats.copyWith(
        matchId: currentMatchId,
      );
    }).toList();

    // Create the MatchDTO for sending to the backend
    final MatchDTO matchDTO = MatchDTO(
      idMatch: currentMatchId,
      appUserId: widget.userId,
      matchDate: DateTime.now().toIso8601String().split('T')[0], // Date in YYYY-MM-DD format
      teamOneScore: teamOneScore,
      teamTwoScore: teamTwoScore,
      teamOne: widget.team1,
      teamTwo: widget.team2,
      startersTeam1: widget.startersTeam1,
      startersTeam2: widget.startersTeam2,
      gameMode: widget.gameMode,
      stats: currentStatsList,
      location: locationDTO,
      finished: isFinished,
    );

    // Call the MatchController to save or update the match
    final int? newMatchId = await _matchController.saveOrUpdateMatch(matchDTO);

    if (newMatchId != null) {
      setState(() {
        currentMatchId = newMatchId; // Update local matchId with the ID from backend
        _hasSavedProgressOnPause = true; // Mark as saved to prevent immediate re-save on pause
      });
      FirebaseAnalytics.instance.logEvent(name: 'progress_saved_successfully', parameters: {'match_id': currentMatchId, 'is_finished': isFinished});
      debugPrint("Match saved successfully. ID: $currentMatchId");

      // Check if the match was finished (not just progress saved)
      if (isFinished) {
        PersistentSnackbar.show(
          context: context,
          message: 'Match finished successfully!',
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
        );
        // Wait briefly for the Snackbar to show, then navigate
        await Future.delayed(const Duration(seconds: 1));
        // Navigate back to MainScreen and clear the navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
              (Route<dynamic> route) => false,
        );
      } else {
        // If not finished, it's a progress save, show a less intrusive Snackbar
        PersistentSnackbar.show(
          context: context,
          message: 'Progress saved automatically!',
          backgroundColor: Colors.blueGrey.shade700,
          textColor: Colors.white,
          icon: Icons.save_alt,
          duration: const Duration(seconds: 2),
        );
      }
    } else {
      // Handle failure case
      FirebaseAnalytics.instance.logEvent(name: 'progress_save_failed', parameters: {'is_finished': isFinished});
      debugPrint("Error saving match progress.");
      if (isFinished) {
        // If it failed while trying to finish, show a specific error
        PersistentSnackbar.show(
          context: context,
          message: 'Failed finishing match, try again.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
      } else {
        // If it failed during automatic progress save
        PersistentSnackbar.show(
          context: context,
          message: 'Failed to automatically save progress.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
  void updatePoints(int teamNumber, int points) {
    setState(() {
      if (selectedTeam != null) {
        if (selectedTeam!.id == widget.team1.id) {
          teamOneScore += points;
        } else if (selectedTeam!.id == widget.team2.id) {
          teamTwoScore += points;
        }
        FirebaseAnalytics.instance.logEvent(name: 'score_updated', parameters: {'team': teamNumber, 'points': points, 'team1_score': teamOneScore, 'team2_score': teamTwoScore});
      } else {
        debugPrint("Error: No team selected for scoring.");
        PersistentSnackbar.show(
          context: context,
          message: 'Please, select a player and its team to score!',
          backgroundColor: Colors.orange.shade700,
          textColor: Colors.white,
          icon: Icons.warning_amber_rounded,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  void addActionToPlayer(String actionDescription) {
    setState(() {
      if (selectedPlayer != null && selectedTeam != null) {
        final displayString = "$actionDescription\n${selectedPlayer!.jerseyNumber}";
        if (selectedTeam!.id == widget.team1.id) {
          team1Actions.insert(0, displayString);
          _team1ScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut,);
        } else if (selectedTeam!.id == widget.team2.id) {
          team2Actions.insert(0, displayString);
          _team2ScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut,);
        }
      } else {
        PersistentSnackbar.show(
          context: context,
          message: 'Please, first select a player!',
          backgroundColor: Colors.blueGrey.shade700,
          textColor: Colors.white,
          icon: Icons.info_outline,
          duration: const Duration(seconds: 2),
        );
        FirebaseAnalytics.instance.logEvent(name: 'action_button_failed', parameters: {'reason': 'no_player_selected'});
      }
    });
  }

  void _performSubstitution(PlayerDTO enteringPlayer) {
    FirebaseAnalytics.instance.logEvent(name: 'substitution_performed', parameters: {'entering_player_id': enteringPlayer.idPlayer, 'leaving_player_id': selectedPlayer!.idPlayer});
    setState(() {
      if (selectedTeam != null && selectedPlayer != null) {
        final List<PlayerDTO> currentStarters = selectedTeam!.id == widget.team1.id
            ? widget.startersTeam1
            : widget.startersTeam2;

        final index = currentStarters.indexWhere(
              (p) => p.idPlayer == selectedPlayer!.idPlayer,
        );

        if (index != -1) {
          currentStarters[index] = enteringPlayer;
        }
      }
      selectedPlayer = null;
      selectedTeam = null;
    });

    PersistentSnackbar.show(
      context: context,
      message: '${enteringPlayer.playerName} is in the court!',
      backgroundColor: Colors.blueGrey.shade700,
      textColor: Colors.white,
    );
  }

  Widget _substitutionButton({
    required BuildContext context,
    required TeamDTO currentTeam,
  }) {
    return GestureDetector(
      onTap: () async {
        if (selectedPlayer == null) {
          PersistentSnackbar.show(
            context: context,
            message: 'Select a player to substitute!',
            backgroundColor: Colors.blueGrey.shade700,
            textColor: Colors.white,
            icon: Icons.info_outline,
            duration: const Duration(seconds: 2),
          );
          return;
        }

        FirebaseAnalytics.instance.logEvent(name: 'substitution_button_tapped', parameters: {'team_id': currentTeam.id});

        final List<PlayerDTO> players = await _playerController.fetchPlayersByTeamId(currentTeam.id!);

        if (players.isNotEmpty) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black87,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) {
              return ListView.builder(
                itemCount: players.length,
                itemBuilder: (ctx, index) {
                  final player = players[index];
                  final currentStarters = selectedTeam!.id == widget.team1.id ? widget.startersTeam1 : widget.startersTeam2;
                  if (currentStarters.any((p) => p.idPlayer == player.idPlayer)) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    title: Text(
                      player.jerseyNumber,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      player.playerName,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _performSubstitution(player);
                    },
                  );
                },
              );
            },
          );
        } else {
          PersistentSnackbar.show(
            context: context,
            message: 'There is no players available to substitution in this team.',
            backgroundColor: Colors.blueGrey.shade700,
            textColor: Colors.white,
            icon: Icons.info_outline,
          );
          FirebaseAnalytics.instance.logEvent(name: 'substitution_fetch_players_failed', parameters: {'team_id': currentTeam.id, 'reason': 'no_players_available'});
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: const DecorationImage(image: AssetImage('assets/images/SubstitutionActionIcon.png'), fit: BoxFit.cover),
          border: Border.all(color: Colors.yellow, width: 1),
        ),
      ),
    );
  }

  Widget _scoreButton(String imagePath, String statKey, int points) {
    return GestureDetector(
      onTap: () {
        if (selectedPlayer != null && selectedTeam != null) {
          updateStat(selectedPlayer!.idPlayer!, statKey);
          updatePoints(selectedTeam!.id!, points);
          addActionToPlayer("${points} Point Made");
        } else {
          PersistentSnackbar.show(
            context: context,
            message: 'Please, select a player first!',
            backgroundColor: Colors.blueGrey.shade700,
            textColor: Colors.white,
            icon: Icons.info_outline,
            duration: const Duration(seconds: 2),
          );
          FirebaseAnalytics.instance.logEvent(name: 'score_button_failed', parameters: {'reason': 'no_player_selected'});
        }
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: getBorderColor(statKey), width: 1),
          image: DecorationImage(image: AssetImage(imagePath)),
        ),
      ),
    );
  }

  Widget _actionButton(String imagePath, String statKey, String actionDescription) {
    return GestureDetector(
      onTap: () {
        if (selectedPlayer != null && selectedTeam != null) {
          updateStat(selectedPlayer!.idPlayer!, statKey);
          addActionToPlayer(actionDescription);
        } else {
          PersistentSnackbar.show(
            context: context,
            message: 'Please, select a player first!',
            backgroundColor: Colors.blueGrey.shade700,
            textColor: Colors.white,
            icon: Icons.info_outline,
            duration: const Duration(seconds: 2),
          );
          FirebaseAnalytics.instance.logEvent(name: 'action_button_failed', parameters: {'reason': 'no_player_selected'});
        }
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: getBorderColor(statKey), width: 1),
          image: DecorationImage(image: AssetImage(imagePath)),
        ),
      ),
    );
  }

  Widget _optionsButton(String imagePath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          image: DecorationImage(image: AssetImage(imagePath)),
        ),
      ),
    );
  }

  void _showExtraMenu() {
    FirebaseAnalytics.instance.logEvent(name: 'extra_menu_opened');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.white),
                title: const Text("Legend", style: TextStyle(color: Colors.white)),
                onTap: () {
                  FirebaseAnalytics.instance.logEvent(name: 'legend_menu_item_clicked');
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.black.withOpacity(0.6),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/LegendsImage.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.white),
                title: const Text("Finish match", style: TextStyle(color: Colors.white)),
                onTap: () {
                  FirebaseAnalytics.instance.logEvent(name: 'finish_match_menu_item_clicked');
                  Navigator.pop(context);
                  _saveMatchProgress(isFinished: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  "Exit without saving",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  FirebaseAnalytics.instance.logEvent(name: 'exit_without_saving_menu_item_clicked');
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Are you sure?"),
                        content: const Text("All unsaved stats will be lost."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              FirebaseAnalytics.instance.logEvent(name: 'exit_without_saving_canceled');
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: () {
                              FirebaseAnalytics.instance.logEvent(name: 'exit_without_saving_confirmed');
                              Navigator.pop(context);
                              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => MainScreen()),
                                    (Route<dynamic> route) => false,
                              );
                            },
                            child: const Text("Exit", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileLayout = constraints.maxWidth < 800;

        Widget buildActionCenter(bool isMobile) {
          return Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Color(0xFFFF4500),
                  Color(0xFF84442E),
                  Color(0xFF3A2E2E),
                ],
                stops: [0.0, 0.2, 0.7],
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: Center(
                    child: Text(
                      "$teamOneScore X $teamTwoScore",
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: isMobile ? 4 : 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    padding: EdgeInsets.zero,
                    childAspectRatio: 1.5,
                    children: [
                      _scoreButton('assets/images/1PointActionIcon.png', "onePointers", 1),
                      _scoreButton('assets/images/2PointActionIcon.png', "twoPointers", 2),
                      _scoreButton('assets/images/3PointActionIcon.png', "threePointers", 3),
                      _actionButton('assets/images/1PointMissedActionIcon.png', "missedOnePointers", "1 Ponto Perdido"),
                      _actionButton('assets/images/2PointMissedActionIcon.png', "missedTwoPointers", "2 Pontos Perdidos"),
                      _actionButton('assets/images/3PointMissedActionIcon.png', "missedThreePointers", "3 Pontos Perdidos"),
                      _actionButton('assets/images/AssistActionIcon.png', "assists", "Assistência"),
                      _actionButton('assets/images/BlockActionIcon.png', "blocks", "Toco"),
                      _actionButton('assets/images/StealActionIcon.png', "steals", "Roubada"),
                      _actionButton('assets/images/OffensiveReboundActionIcon.png', "offensiveRebounds", "R. Ofensivo"),
                      _actionButton('assets/images/DefensiveReboundActionIcon.png', "defensiveRebounds", "R. Defensivo"),
                      _actionButton('assets/images/TurnOverActionIcon.png', "turnovers", "Turnover"),
                      _actionButton('assets/images/FoulActionIcon.png', "fouls", "Falta"),
                      _optionsButton('assets/images/OptionsIcon.png', _showExtraMenu),
                      _substitutionButton(
                        context: context,
                        currentTeam: selectedTeam?.id == widget.team1.id ? widget.team1 : widget.team2,
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildActionList(List<String> actions, ScrollController controller) {
          return Expanded(
            flex: 5,
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                controller: controller,
                padding: EdgeInsets.zero,
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  String action = actions[index];
                  Color borderColor = getBorderColor(action.split('\n')[0]);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        action,
                        style: TextStyle(fontSize: 14, color: borderColor, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
        Widget buildPlayers(List<PlayerDTO> starters, TeamDTO team) {
          return Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF3A2E2E),
              child: Column(
                children: List.generate(
                  widget.gameMode == "5x5" ? 5 : widget.gameMode == "3x3" ? 3 : 1,
                      (index) {
                    if (index >= starters.length) {
                      return const SizedBox.shrink();
                    }
                    PlayerDTO player = starters[index];
                    bool isSelected = selectedPlayer?.idPlayer == player.idPlayer && selectedTeam?.id == team.id;

                    return GestureDetector(
                      onTap: () {
                        debugPrint("Player selected: ID ${player.idPlayer}, Jersey: ${player.jerseyNumber}");
                        setState(() {
                          selectedPlayer = player;
                          selectedTeam = team;
                        });
                      },
                      child: Container(
                        color: isSelected ? const Color(0xFFF6B712) : Colors.transparent,
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                player.jerseyNumber,
                                style: const TextStyle(color: Colors.white, fontSize: 37),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Image.asset("assets/images/basketball.png", width: 40, height: 40),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }
        Widget buildTeamColumn(TeamDTO team, List<PlayerDTO> starters, List<String> actions, ScrollController controller, int teamNumber) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                color: const Color(0xFF3A2E2E),
                child: Text(
                  team.abbreviation,
                  style: const TextStyle(
                    color: Color(0xFFFFCC80),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Row(
                  children: teamNumber == 1
                      ? [buildPlayers(starters, team), buildActionList(actions, controller)]
                      : [buildActionList(actions, controller), buildPlayers(starters, team)],
                ),
              ),
            ],
          );
        }

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            _showExtraMenu();
          },
          child: Scaffold(
            body: OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;

                if (isLandscape) {
                  return Row(
                    children: [
                      Expanded(child: buildTeamColumn(widget.team1, widget.startersTeam1, team1Actions, _team1ScrollController, 1)),
                      Expanded(flex: 1, child: buildActionCenter(isMobileLayout)),
                      Expanded(child: buildTeamColumn(widget.team2, widget.startersTeam2, team2Actions, _team2ScrollController, 2)),
                    ],
                  );
                } else {
                  return Center(
                    child: Text(
                      'Please, rotate your device to landscape mode to play.',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.orange),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}