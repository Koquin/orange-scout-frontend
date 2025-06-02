import 'dart:io'; // Still needed for File.existsSync() but check its validity for web/other platforms
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Import Crashlytics

// Import your DTOs
import 'package:OrangeScoutFE/dto/team_dto.dart';

// Import your controllers
import 'package:OrangeScoutFE/controller/team_controller.dart';

// Import your utility
import 'package:OrangeScoutFE/util/persistent_snackbar.dart';

// Import your views
import 'package:OrangeScoutFE/view/createTeamScreen.dart'; // Assuming this screen exists
import 'package:OrangeScoutFE/view/editTeamScreen.dart';   // Assuming this screen exists


class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  _TeamsScreenState createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  // Use TeamDTO for type safety
  List<TeamDTO> _teams = [];
  bool _isLoading = true;
  bool _hasError = false; // Added to indicate a critical error fetching data

  final String fallbackImage = "assets/images/TeamShieldIcon-cutout.png";

  final TeamController _teamController = TeamController();

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation(); // Set orientation early
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'TeamsScreen',
        screenClass: 'TeamsScreenState',
      );
    });
    _fetchTeams();
  }

  // Ensures portrait orientation
  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Fetches teams for the authenticated user from the backend.
  /// Handles loading, empty, and error states.
  Future<void> _fetchTeams() async {
    setState(() {
      _isLoading = true;
      _hasError = false; // Reset error state on new fetch attempt
    });
    FirebaseAnalytics.instance.logEvent(name: 'fetch_teams_attempt_screen');
    FirebaseCrashlytics.instance.log('Attempting to fetch user teams for TeamsScreen.');

    try {
      // Use controller to fetch teams, which now returns List<TeamDTO>
      List<TeamDTO> fetchedTeams = await _teamController.fetchUserTeams();

      setState(() {
        _teams = fetchedTeams;
        _isLoading = false;
        _hasError = false; // No general error if list is just empty
      });

      if (fetchedTeams.isEmpty && mounted) {
        FirebaseAnalytics.instance.logEvent(name: 'no_teams_found_screen');
        PersistentSnackbar.show(
          context: context,
          message: 'No team found. Create one!',
          backgroundColor: Theme.of(context).colorScheme.primary, // Using theme color
          textColor: Theme.of(context).colorScheme.onPrimary,
          icon: Icons.info_outline,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Error fetching user teams in TeamsScreen',
        fatal: false,
      );
      setState(() {
        _isLoading = false;
        _hasError = true; // Set error state if an exception occurs
      });
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: 'Error loading teams. Try again.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  /// Navigates to EditTeamScreen and refreshes team list upon return.
  void _editTeam(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'edit_team_button_tapped', parameters: {'team_id': teamId});

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTeamScreen(teamId: teamId)),
    );

    // Refresh teams if EditTeamScreen indicates a change (e.g., deleted, updated)
    if (result == true && mounted) {
      await _fetchTeams(); // Await fetchTeams to ensure state is updated before next check
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: "Lista de times atualizada!",
          backgroundColor: Colors.blueGrey.shade700,
          textColor: Colors.white,
          icon: Icons.refresh,
          duration: const Duration(seconds: 2),
        );
        FirebaseAnalytics.instance.logEvent(name: 'team_list_refreshed_after_edit_delete');
      }
    }
  }

  /// Navigates to CreateTeamScreen and refreshes team list upon return.
  void _createTeam() async {
    FirebaseAnalytics.instance.logEvent(name: 'add_team_button_tapped');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateTeamScreen(teamId: null)), // teamId is null for creation
    );
    // Refresh teams if CreateTeamScreen indicates a change
    if (result == true && mounted) {
      await _fetchTeams(); // Await fetchTeams to ensure state is updated before next check
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: "Time criado com sucesso! Lista atualizada.",
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  // Helper Widget for Team Logos
  Widget _buildTeamLogo(String? logoPath, {double size = 100}) { // Added size parameter for flexibility
    // Consider adding a network image widget here if logoPath is a URL
    if (logoPath != null && logoPath.isNotEmpty) {
      // Check if it's a local file path
      if (logoPath.startsWith('/data/') || logoPath.startsWith('file://') || File(logoPath).existsSync()) {
        return Image.file(
          File(logoPath),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Image.asset(fallbackImage, width: size, height: size),
        );
      } else {
        // Assume it's a network URL if not a local file path or local file doesn't exist
        return Image.network(
          logoPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Image.asset(fallbackImage, width: size, height: size),
        );
      }
    }
    return Image.asset(fallbackImage, width: size, height: size);
  }

  @override
  Widget build(BuildContext context) {
    // Orientation is set in initState, no need to set it again in build
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
        child: Stack( // Use Stack to position the FAB on top of GridView
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _hasError // Display error message if critical error
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Erro ao carregar times.',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _fetchTeams,
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              )
                  : _teams.isEmpty // Display "No teams" message if empty after loading
                  ? Center(
                child: Text(
                  'Nenhum time encontrado. Crie um para começar!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
                  : GridView.builder(
                itemCount: _teams.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 25,
                  crossAxisSpacing: 25,
                  childAspectRatio: 3 / 4,
                ),
                itemBuilder: (context, index) {
                  final team = _teams[index]; // Now a TeamDTO
                  // Use team.teamName and team.abbreviation directly from TeamDTO
                  final String displayName = team.teamName.length > 20 ? team.abbreviation : team.teamName;

                  return GestureDetector(
                    onTap: () => _editTeam(team.id!), // Use team.id from TeamDTO
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildTeamLogo(team.logoPath, size: 150), // Use team.logoPath
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Floating Action Button (FAB) for adding teams
            Positioned(
              bottom: 20, // Adjust position as needed
              right: 20,
              child: FloatingActionButton(
                onPressed: _createTeam, // Call the create team method
                backgroundColor: Colors.orange, // Match theme
                child: Image.asset('assets/images/AddTeamIcon.png', width: 40, height: 40), // Use your custom icon
              ),
            ),
          ],
        ),
      ),
    );
  }
}