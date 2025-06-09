import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Import your DTOs
import 'package:OrangeScoutFE/dto/stats_dto.dart';
import 'package:OrangeScoutFE/dto/match_dto.dart'; // To get match details like location
import 'package:OrangeScoutFE/dto/location_dto.dart'; // Nested in MatchDTO

// Import your controllers
import 'package:OrangeScoutFE/controller/match_controller.dart';
import 'package:OrangeScoutFE/controller/location_controller.dart';

// Import your utility
import 'package:OrangeScoutFE/util/persistent_snackbar.dart';


class StatsScreen extends StatefulWidget {
  final int matchId;

  const StatsScreen({super.key, required this.matchId});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // Use StatsDTO for type safety
  List<StatsDTO> stats = [];
  bool isLoading = true;
  bool hasError = false; // Indicates a critical error fetching data
  Map<String, List<StatsDTO>> teamsStats = {}; // Map team name to list of StatsDTO
  String? selectedTeamFilter;
  List<String> availableTeams = [];
  String? matchLocationName; // Renamed for clarity
  int? matchLocationId;

  final MatchController _matchController = MatchController();
  final LocationController _locationController = LocationController();

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation(); // Set orientation early
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'StatsScreen',
        screenClass: 'StatsScreenState',
        parameters: {'match_id': widget.matchId},
      );
    });
    _fetchMatchDetailsAndStats(); // Unified fetch method
  }

  @override
  void dispose() {
    // Setting orientation to default (portraitUp, portraitDown) is usually sufficient
    // or you can revert to all DeviceOrientation.values if your app requires it.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // Ensures portrait orientation
  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Fetches match details and all stats for the given match ID.
  Future<void> _fetchMatchDetailsAndStats() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    FirebaseAnalytics.instance.logEvent(name: 'fetch_stats_screen_attempt', parameters: {'match_id': widget.matchId});
    FirebaseCrashlytics.instance.log('Attempting to fetch stats and details for match: ${widget.matchId}');

    try {
      // 1. Fetch Match Details (to get location, team names etc.)
      final MatchDTO? matchDetails = await _matchController.getMatchById(widget.matchId);

      if (matchDetails == null) {
        throw Exception("Match details not found for ID: ${widget.matchId}");
      }

      // 2. Fetch Stats for the Match
      final List<StatsDTO>? fetchedStats = await _matchController.fetchMatchStats(widget.matchId);

      if (fetchedStats == null || fetchedStats.isEmpty) {
        // No stats found, but match details exist, so it's not a critical error
        // just an empty stats list for this match.
        setState(() {
          isLoading = false;
          stats = []; // Ensure empty list
          teamsStats = {};
          availableTeams = [];
          matchLocationName = matchDetails.location?.venueName;
          matchLocationId = matchDetails.location?.id;
        });
        FirebaseAnalytics.instance.logEvent(name: 'no_stats_found_for_match', parameters: {'match_id': widget.matchId});
        if (mounted) {
          PersistentSnackbar.show(
            context: context,
            message: 'No stats found for this match.',
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            icon: Icons.info_outline,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // Process stats to group by team
      Map<String, List<StatsDTO>> teamStatsMap = {};
      for (var stat in fetchedStats) {
        if (stat.teamName != null && stat.teamName!.isNotEmpty) {
          String team = stat.teamName!;
          teamStatsMap.putIfAbsent(team, () => []).add(stat);
        }
      }

      setState(() {
        stats = fetchedStats;
        teamsStats = teamStatsMap;
        availableTeams = teamStatsMap.keys.toList();
        isLoading = false;
        matchLocationName = matchDetails.location?.venueName;
        matchLocationId = matchDetails.location?.id;
      });
      FirebaseAnalytics.instance.logEvent(name: 'stats_fetched_successfully', parameters: {'match_id': widget.matchId, 'num_teams': availableTeams.length});
      FirebaseCrashlytics.instance.log('Stats fetched successfully for match ${widget.matchId}.');
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Error fetching match details or stats',
        fatal: false,
      );
      setState(() {
        hasError = true;
        isLoading = false;
      });
      FirebaseAnalytics.instance.logEvent(name: 'fetch_stats_failed_screen', parameters: {'match_id': widget.matchId});
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: 'Error loading stats for match. Try again.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  /// Applies a filter to display stats for a specific team or all teams.
  void applyFilter(String? filter) {
    setState(() {
      selectedTeamFilter = filter == "All Teams" ? null : filter;
    });
    FirebaseAnalytics.instance.logEvent(name: 'stats_filter_applied', parameters: {'filter_team': filter ?? 'All Teams'});
  }

  /// Initiates the deletion of the current match after user confirmation.
  Future<void> _deleteMatchConfirmed() async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_match_from_stats_confirmed', parameters: {'match_id': widget.matchId});
    bool success = await _matchController.deleteMatch(widget.matchId);
    if (success && mounted) {
      PersistentSnackbar.show(
        context: context,
        message: 'Match deleted successfully!',
        backgroundColor: Colors.green.shade700,
        textColor: Colors.white,
        icon: Icons.check_circle_outline,
      );
      Navigator.pop(context, true); // Pop and return 'true' to indicate deletion
    } else if (mounted) {
      PersistentSnackbar.show(
        context: context,
        message: 'Error deleting match. Try again.',
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        icon: Icons.error_outline,
      );
    }
  }

  /// Shows a confirmation dialog before deleting the match.
  void _showDeleteConfirmationDialog() {
    FirebaseAnalytics.instance.logEvent(name: 'delete_match_dialog_opened', parameters: {'match_id': widget.matchId});
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('You really want to delete this match ? this cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(name: 'delete_match_dialog_canceled');
              Navigator.of(context).pop(false); // Pop with false
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Pop with true
              _deleteMatchConfirmed();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Opens the match's location on Google Maps.
  Future<void> _openMatchLocation() async {
    if (matchLocationId == null) {
      PersistentSnackbar.show(
        context: context,
        message: 'Location not available for this match.',
        backgroundColor: Colors.orange.shade700,
        textColor: Colors.white,
        icon: Icons.info_outline,
      );
      FirebaseAnalytics.instance.logEvent(name: 'view_match_location_unavailable', parameters: {'match_id': widget.matchId});
      return;
    }
    FirebaseAnalytics.instance.logEvent(name: 'view_match_location_from_stats', parameters: {'match_id': widget.matchId, 'location_id': matchLocationId});
    // Use the controller's method which now returns boolean for success
    bool success = await _locationController.openMatchLocationOnMaps(matchLocationId!);
    if (!success && mounted) {
      PersistentSnackbar.show(
        context: context,
        message: 'Not possible to open match location.',
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Orientation is set in initState, no need to set it again in build
    _setPortraitOrientation();

    // Filter stats based on selectedTeamFilter
    Map<String, List<StatsDTO>> filteredStats = selectedTeamFilter != null
        ? {selectedTeamFilter!: teamsStats[selectedTeamFilter!] ?? []}
        : teamsStats;

    return Scaffold(
      appBar: AppBar(
        title: Text(matchLocationName != null && matchLocationName!.isNotEmpty ? matchLocationName! : 'Match stats', style: const TextStyle(color: Colors.blue)),
        backgroundColor: const Color(0xFF3A2E2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(name: 'stats_screen_back_button_tapped', parameters: {'match_id': widget.matchId});
            Navigator.pop(context);
          },
        ),
        actions: [
          if (matchLocationId != null) // Only show if location exists
            IconButton(
              icon: const Icon(Icons.location_on, color: Colors.blueAccent, size: 28),
              tooltip: 'View match location',
              onPressed: _openMatchLocation, // Unified method
            ),
          if (availableTeams.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
              tooltip: 'Filter',
              onSelected: applyFilter,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: "All Teams",
                  child: Text("All teams"), // Localized
                ),
                ...availableTeams.map((team) =>
                    PopupMenuItem(value: team, child: Text(team))),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 28),
            tooltip: 'Delete match',
            onPressed: _showDeleteConfirmationDialog,
          ),
        ],
      ),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : hasError
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error loading match stats.', style: TextStyle(color: Colors.red, fontSize: 16)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _fetchMatchDetailsAndStats, // Retry button
                child: const Text('Try again.'),
              ),
            ],
          ),
        )
            : stats.isEmpty && selectedTeamFilter == null // Check if no stats and no filter applied
            ? Center(
          child: Text(
            'Not stats available for this match.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        )
            : ListView(
          children: filteredStats.keys.map((team) {
            var playersStatsList = filteredStats[team] ?? []; // List of StatsDTOs

            return Card(
              color: Colors.black.withOpacity(0.6),
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      team,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCC80),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                      dataRowColor: MaterialStateProperty.all(Colors.transparent),
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(label: Text('PLAYER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('3PT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('2PT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('1PT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('OFF REB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), // Renamed
                        DataColumn(label: Text('DEF REB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), // Renamed
                        DataColumn(label: Text('ASS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('STL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('TO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('BLK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('FOUL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), // Renamed
                      ],
                      rows: playersStatsList.map((playerStats) { // Now a StatsDTO
                        // Calculate total shots for percentage display
                        int threeTotal = playerStats.threePointers + playerStats.missedThreePointers;
                        int twoTotal = playerStats.twoPointers + playerStats.missedTwoPointers;
                        int oneTotal = playerStats.onePointers + playerStats.missedOnePointers;

                        return DataRow(
                          cells: [
                            DataCell(Text(playerStats.playerJersey ?? '-', style: const TextStyle(color: Colors.white70))),
                            DataCell(Text('${playerStats.threePointers}/${threeTotal}', style: const TextStyle(color: Colors.white))),
                            DataCell(Text('${playerStats.twoPointers}/${twoTotal}', style: const TextStyle(color: Colors.white))),
                            DataCell(Text('${playerStats.onePointers}/${oneTotal}', style: const TextStyle(color: Colors.white))),
                            DataCell(Text(playerStats.offensiveRebounds.toString(), style: const TextStyle(color: Colors.white70))),
                            DataCell(Text(playerStats.defensiveRebounds.toString(), style: const TextStyle(color: Colors.white70))),
                            DataCell(Text(playerStats.assists.toString(), style: const TextStyle(color: Colors.white70))),
                            DataCell(Text(playerStats.steals.toString(), style: const TextStyle(color: Colors.white70))),
                            DataCell(Text(playerStats.turnovers.toString(), style: const TextStyle(color: Colors.white70))),
                            DataCell(Text(playerStats.blocks.toString(), style: const TextStyle(color: Colors.white70))),
                            DataCell(Text(playerStats.fouls.toString(), style: const TextStyle(color: Colors.white70))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}