import 'dart:io'; // Still needed for File.existsSync() but check its validity for web/other platforms
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Import your DTOs
import 'package:OrangeScoutFE/dto/match_dto.dart';
import 'package:OrangeScoutFE/dto/location_dto.dart'; // Ensure LocationDTO is imported for parsing
import 'package:OrangeScoutFE/dto/team_dto.dart';     // Ensure TeamDTO is imported for parsing

// Import your controllers
import 'package:OrangeScoutFE/controller/match_controller.dart';
import 'package:OrangeScoutFE/controller/location_controller.dart';
import 'package:OrangeScoutFE/util/persistent_snackbar.dart'; // Import your refactored Snackbar
import 'package:OrangeScoutFE/view/statScreen.dart'; // Your StatsScreen to navigate to

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Use MatchDTO for type safety
  List<MatchDTO> matches = [];
  bool isLoading = true;
  bool hasError = false; // Indicates a critical error fetching data

  final MatchController _matchController = MatchController();
  final LocationController _locationController = LocationController();

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation(); // Set orientation early
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'HistoryScreen',
        screenClass: 'HistoryScreenState',
      );
    });
    _fetchMatches();
  }

  // Ensures portrait orientation
  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _fetchMatches() async {
    setState(() {
      isLoading = true;
      hasError = false; // Reset error state on new fetch attempt
    });
    FirebaseAnalytics.instance.logEvent(name: 'fetch_matches_history_attempt');
    FirebaseCrashlytics.instance.log('Attempting to fetch user match history.');

    try {
      // Use controller to fetch matches, which now returns List<MatchDTO>
      List<MatchDTO> fetchedMatches = await _matchController.fetchUserMatches();

      setState(() {
        matches = fetchedMatches;
        isLoading = false;
        // Set hasError based on whether matches were fetched
        hasError = fetchedMatches.isEmpty;
      });

      if (fetchedMatches.isEmpty && mounted) {
        FirebaseAnalytics.instance.logEvent(name: 'no_matches_found_history_screen');
        PersistentSnackbar.show(
          context: context,
          message: 'No match found in your history.',
          backgroundColor: Theme.of(context).colorScheme.primary, // Using theme color
          textColor: Theme.of(context).colorScheme.onPrimary,
          icon: Icons.info_outline,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Error fetching user match history',
        fatal: false,
      );
      setState(() {
        isLoading = false;
        hasError = true; // Set error state if an exception occurs
      });
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: 'Error loading match history. Try again.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  /// Opens a specific match location on Google Maps.
  /// It receives a LocationDTO, which includes latitude and longitude.
  Future<void> _openMatchLocationOnMaps(LocationDTO location) async {
    FirebaseAnalytics.instance.logEvent(name: 'open_single_match_location_button_tapped', parameters: {'location_id': location.id});
    bool success = await _locationController.openMatchLocationOnMaps(location.id!);

    if (!success && mounted) {
      PersistentSnackbar.show(
        context: context,
        message: 'Could not open match location.',
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _deleteMatch(int matchId) async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_match_button_tapped', parameters: {'match_id': matchId});
    FirebaseCrashlytics.instance.log('Attempting to delete match: $matchId');

    // Show a confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm delete'),
          content: const Text('You really want to delete this match?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      bool success = await _matchController.deleteMatch(matchId);
      if (success && mounted) {
        PersistentSnackbar.show(
          context: context,
          message: 'Match deleted successfully!',
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
        );
        _fetchMatches(); // Refresh the list after deletion
      } else if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: 'Failed to delete match. Try Again.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : hasError
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Error loading match history or no match found.',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _fetchMatches,
                      child: const Text('Try again.'),
                    ),
                  ],
                ),
              )
                  : matches.isEmpty
                  ? Center(
                child: Text(
                  'Start a match to see your history here!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final DateTime matchDate = DateTime.parse(match.matchDate);
                  final String formattedDate = "${matchDate.day.toString().padLeft(2, '0')}/${matchDate.month.toString().padLeft(2, '0')}/${matchDate.year}";

                  return Card(
                    color: Colors.black.withOpacity(0.5),
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.bar_chart, color: Color(0xFFFFCC80), size: 25),
                            tooltip: 'View stats',
                            onPressed: () {
                              FirebaseAnalytics.instance.logEvent(name: 'view_stats_button_tapped', parameters: {'match_id': match.idMatch});
                              if (match.idMatch != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StatsScreen(matchId: match.idMatch!),
                                  ),
                                );
                              } else {
                                PersistentSnackbar.show(
                                  context: context,
                                  message: 'Match id not available to view stats.',
                                  backgroundColor: Colors.red.shade700,
                                  textColor: Colors.white,
                                );
                              }
                            },
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTeamLogo(match.teamOne.logoPath),
                                const SizedBox(width: 8),
                                Text(
                                  match.teamOne.abbreviation,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 15),
                                // Match Date and Score
                                Column(
                                  children: [
                                    Text(formattedDate, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text(
                                      '${match.teamOneScore} x ${match.teamTwoScore}',
                                      style: const TextStyle(color: Colors.orange, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 15),
                                // Display Team 2 Logo and Abbreviation
                                Text(
                                  match.teamTwo.abbreviation,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                _buildTeamLogo(match.teamTwo.logoPath),
                              ],
                            ),
                          ),
                          // Location and Delete Buttons
                          IconButton(
                            icon: const Icon(Icons.location_on, color: Colors.blueAccent, size: 25),
                            tooltip: 'See location',
                            onPressed: () {
                              FirebaseAnalytics.instance.logEvent(name: 'view_match_location_button_tapped', parameters: {'match_id': match.idMatch});
                              if (match.location != null && match.location!.id != null) {
                                _openMatchLocationOnMaps(match.location!);
                              } else {
                                PersistentSnackbar.show(
                                  context: context,
                                  message: 'Location not available to this match.',
                                  backgroundColor: Colors.orange.shade700,
                                  textColor: Colors.white,
                                  icon: Icons.info_outline,
                                );
                                FirebaseAnalytics.instance.logEvent(name: 'view_match_location_unavailable', parameters: {'match_id': match.idMatch});
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 25),
                            tooltip: 'Delete match',
                            onPressed: () {
                              if (match.idMatch != null) {
                                _deleteMatch(match.idMatch!);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Team Logos
  Widget _buildTeamLogo(String? logoPath) {
    if (logoPath != null && logoPath.isNotEmpty) {
      // Check if it's a local file path
      if (logoPath.startsWith('/data/') || logoPath.startsWith('file://')) {
        return Image.file(
          File(logoPath),
          width: 30,
          height: 30,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Image.asset("assets/images/TeamShieldIcon-cutout.png", width: 30, height: 30),
        );
      } else {
        // Assume it's a network URL if not a local file path
        return Image.network(
          logoPath,
          width: 30,
          height: 30,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Image.asset("assets/images/TeamShieldIcon-cutout.png", width: 30, height: 30),
        );
      }
    }
    return Image.asset("assets/images/TeamShieldIcon-cutout.png", width: 30, height: 30);
  }
}