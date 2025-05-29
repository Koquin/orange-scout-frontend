import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:OrangeScoutFE/view/createTeamScreen.dart';
import 'package:OrangeScoutFE/view/editTeamScreen.dart';
import 'package:OrangeScoutFE/controller/teamController.dart';
import 'package:firebase_analytics/firebase_analytics.dart';



class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  _TeamsScreenState createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  List<dynamic> _teams = [];
  bool _isLoading = true;

  final String fallbackImage = "assets/images/TeamShieldIcon-cutout.png";

  final TeamController _teamController = TeamController();

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'TeamsScreen',
        screenClass: 'TeamsScreenState',
      );
    });
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    setState(() {
      _isLoading = true;
    });
    FirebaseAnalytics.instance.logEvent(name: 'fetch_teams_attempt_screen');

    List<dynamic> fetchedTeams = await _teamController.fetchTeams();

    setState(() {
      _teams = fetchedTeams;
      _isLoading = false;
    });

    if (fetchedTeams.isEmpty && mounted) {
      FirebaseAnalytics.instance.logEvent(name: 'no_teams_found_screen');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No teams found. Create one!')),
      );
    }
  }

  void _editTeam(int teamId) async {
    FirebaseAnalytics.instance.logEvent(name: 'edit_team_button_tapped', parameters: {'team_id': teamId});

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTeamScreen(teamId: teamId)),
    );

    if (result == true) {
      _fetchTeams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Team list refreshed!")),
        );
        FirebaseAnalytics.instance.logEvent(name: 'team_list_refreshed_after_edit_delete');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _teams.isEmpty
                  ? const Center(
                child: Text(
                  'No teams found. Create one!',
                  style: TextStyle(color: Colors.white, fontSize: 18),
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
                  final team = _teams[index];
                  final String teamName = team["teamName"];
                  final String abbreviation = team["abbreviation"];
                  final String displayName = teamName.length > 20 ? abbreviation : teamName;

                  return GestureDetector(
                    onTap: () async {
                      FirebaseAnalytics.instance.logEvent(name: 'team_list_item_tapped', parameters: {'team_id': team['id'], 'team_name': teamName});

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditTeamScreen(teamId: team["id"])),
                      );
                      if (result == true) {
                        _fetchTeams();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Team list refreshed!")),
                          );
                        }
                      }
                    },
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
                              child: Image.file(
                                File(team["logoPath"] ?? ""),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(fallbackImage, fit: BoxFit.contain);
                                },
                              ),
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
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Image.asset('assets/images/AddTeamIcon.png', width: 40, height: 40),
                onPressed: () async {
                  FirebaseAnalytics.instance.logEvent(name: 'add_team_button_tapped');
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateTeamScreen(teamId: null)),
                  );
                  if (result == true) {
                    _fetchTeams();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Team list refreshed!")),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
