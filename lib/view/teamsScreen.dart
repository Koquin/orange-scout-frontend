import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../util/token_utils.dart';
import 'createTeamScreen.dart';
import 'editTeamScreen.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  _TeamsScreenState createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  String? baseUrl = dotenv.env['API_BASE_URL'];
  List<dynamic> teams = [];
  bool isLoading = true;

  final String fallbackImage = "assets/images/TeamShieldIcon-cutout.png";

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.initState();
    fetchTeams();
  }

  Future<void> fetchTeams() async {
    String? token = await loadToken();
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/team"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(data);
        setState(() {
          teams = data;
          isLoading = false;
        });
      } else {
        print("Error fetching teams: ${response.statusCode}");
      }
    } catch (e) {
      print("Requisition error: $e");
    }
  }

  void _editTeam(int teamId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTeamScreen(teamId: teamId)),
    );

    if (result == true) {
      fetchTeams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Team list refreshed!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
              itemCount: teams.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 25,
                crossAxisSpacing: 25,
                childAspectRatio: 3 / 4,
              ),
              itemBuilder: (context, index) {
                final team = teams[index];
                final String teamName = team["teamName"];
                final String abbreviation = team["abbreviation"];
                final String displayName =
                teamName.length > 20 ? abbreviation : teamName;

                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              EditTeamScreen(teamId: team["id"])),
                    );
                    if (result == true) {
                      fetchTeams();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Team list refreshed!")), // User feedback
                        );
                      }
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(22),
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
                                return Image.asset(fallbackImage);
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
            top: 5,
            right: 5,
            child: IconButton(
              icon: Image.asset('assets/images/AddTeamIcon.png', width: 40, height: 40),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateTeamScreen(teamId: null)),
                );
                if (result == true) {
                  fetchTeams();
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
    );
  }
}
